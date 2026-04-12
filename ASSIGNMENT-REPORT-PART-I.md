# Part I Report: Containerized Deployment of Web Application (AWS EC2 + Docker)

## 1. Project Overview

### Application name
Electronics eCommerce Shop With Admin Dashboard (Next.js + Node.js + MySQL)

### Stack
- Frontend: Next.js
- Backend: Node.js + Express
- Database: MySQL 8.4
- ORM: Prisma
- Containerization: Docker + Docker Compose
- Cloud deployment target: AWS EC2 (Ubuntu)

### Objective completed
- Built Docker images for web and API services.
- Pushed images to Docker Hub.
- Deployed with Docker Compose on AWS EC2.
- Added persistent storage using Docker volume for MySQL.
- Added automatic demo-data seeding in container startup (toggle via env).

---

## 2. Architecture

Three containers are used:
- `web` (Next.js, port 3000)
- `api` (Express + Prisma, port 3001)
- `db` (MySQL, port 3306)

Data persistence:
- MySQL uses named volume `mysql_data` mounted at `/var/lib/mysql`.

---

## 3. Micro Steps Followed

## Part A: Local containerization and image preparation

1. Confirmed app uses MySQL in Prisma schema and both env files.
2. Created local DB and user for development.
3. Added Docker assets:
- root Dockerfile for Next.js (`web`)
- server Dockerfile for Express (`api`)
- root `.dockerignore` and `server/.dockerignore`
- `docker-compose.yml` with 3 services and volume
4. Fixed production build blockers in code (Next.js route/export and compile/lint blockers necessary for image build).
5. Added runtime-safe config for internal API calls from server-side rendering.
6. Added startup migration and optional demo-data seeding in API container.
7. Built amd64 images and pushed to Docker Hub:
- `mubashirhassan/singitronic-web:latest`
- `mubashirhassan/singitronic-api:latest`

## Part B: Deployment on AWS EC2

1. Connected to EC2 Ubuntu instance.
2. Installed Docker Engine + Compose plugin.
3. Granted Docker socket access to ubuntu user.
4. Created deployment folder (`~/singitronic`) with `docker-compose.yml` and `.env`.
5. Pulled and started containers with:
- `docker compose pull --policy always`
- `docker compose up -d --force-recreate`
6. Validated containers and logs:
- `docker compose ps`
- `docker compose logs --tail=... api`
- `docker compose logs --tail=... web`
7. Verified API health endpoint and frontend reachability.
8. Verified demo data import is executed by API container startup.

---

## 4. Troubleshooting Summary

1. `docker` command not found on local shell:
- Used Docker Desktop binary path and CLI plugin path directly.

2. Docker Hub push denied:
- Corrected username namespace and re-tagged/pushed images.

3. EC2 pull failed with `no matching manifest for linux/amd64`:
- Rebuilt and pushed images using Buildx with `--platform linux/amd64`.

4. API startup failed with Prisma initialization:
- Added `prisma generate` in API container startup command.

5. API startup failed with missing module (`express-rate-limit`):
- Added package to `server/package.json` and rebuilt API image.

6. Web runtime `NO_SECRET`:
- Added `NEXTAUTH_SECRET` in compose runtime env and `.env`.

7. Web SSR calls to external API host failed:
- Added `INTERNAL_API_BASE_URL=http://api:3001` and used it server-side.

8. Registration/database path issues:
- Ensured `DATABASE_URL` exists for both `api` and `web` containers.

---

## 5. Commands Used on EC2 (Final Form)

```bash
cat > .env << 'EOF'
DOCKERHUB_USERNAME=mubashirhassan
NEXTAUTH_URL=http://3.101.109.184:3000
NEXT_PUBLIC_API_BASE_URL=http://3.101.109.184:3001
INTERNAL_API_BASE_URL=http://api:3001
SEED_DEMO_DATA=true
EOF
echo "NEXTAUTH_SECRET=$(openssl rand -hex 32)" >> .env

docker compose down
docker compose pull --policy always
docker compose up -d --force-recreate

docker compose ps
docker compose logs --tail=200 api
docker compose logs --tail=200 web
curl http://localhost:3001/health
curl -I http://localhost:3000
```

---

## 6. Required Docker Artifacts

## 6.1 Dockerfile (web)

```dockerfile
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci

FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

ARG NEXT_PUBLIC_API_BASE_URL=http://localhost:3001
ENV NEXT_PUBLIC_API_BASE_URL=${NEXT_PUBLIC_API_BASE_URL}
ARG DATABASE_URL=mysql://singitronic_user:singitronic_local_2026@db:3306/singitronic_nextjs?sslmode=disabled
ENV DATABASE_URL=${DATABASE_URL}
ARG NEXTAUTH_SECRET=build-secret-placeholder
ENV NEXTAUTH_SECRET=${NEXTAUTH_SECRET}

RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3000

COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/next.config.mjs ./next.config.mjs
COPY --from=builder /app/prisma ./prisma

EXPOSE 3000
CMD ["npm", "run", "start"]
```

## 6.2 Dockerfile (api)

```dockerfile
FROM node:20-alpine
WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY . .

ENV NODE_ENV=production
ENV PORT=3001
ENV SEED_DEMO_DATA=true

EXPOSE 3001
CMD ["sh", "-c", "npx prisma generate && npx prisma migrate deploy && if [ \"$SEED_DEMO_DATA\" = \"true\" ]; then node utills/insertDemoData.js; else echo 'Skipping demo seed'; fi && node app.js"]
```

## 6.3 docker-compose.yml

```yaml
services:
  db:
    image: mysql:8.4
    container_name: singitronic-db
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: root_local_2026
      MYSQL_DATABASE: singitronic_nextjs
      MYSQL_USER: singitronic_user
      MYSQL_PASSWORD: singitronic_local_2026
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-usingitronic_user", "-psingitronic_local_2026"]
      interval: 10s
      timeout: 5s
      retries: 10

  api:
    build:
      context: ./server
      dockerfile: Dockerfile
    image: ${DOCKERHUB_USERNAME:-mubashirhassan}/singitronic-api:latest
    container_name: singitronic-api
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      NODE_ENV: production
      PORT: 3001
      SEED_DEMO_DATA: ${SEED_DEMO_DATA:-true}
      DATABASE_URL: mysql://singitronic_user:singitronic_local_2026@db:3306/singitronic_nextjs?sslmode=disabled
      NEXTAUTH_URL: ${NEXTAUTH_URL:-http://localhost:3000}
      FRONTEND_URL: ${NEXTAUTH_URL:-http://localhost:3000}
      NEXTAUTH_SECRET: ${NEXTAUTH_SECRET:-change-this-production-secret}
    ports:
      - "3001:3001"

  web:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        NEXT_PUBLIC_API_BASE_URL: ${NEXT_PUBLIC_API_BASE_URL:-http://localhost:3001}
    image: ${DOCKERHUB_USERNAME:-mubashirhassan}/singitronic-web:latest
    container_name: singitronic-web
    restart: unless-stopped
    depends_on:
      - api
    environment:
      NODE_ENV: production
      NEXTAUTH_URL: ${NEXTAUTH_URL:-http://localhost:3000}
      NEXTAUTH_SECRET: ${NEXTAUTH_SECRET:-change-this-production-secret}
      INTERNAL_API_BASE_URL: ${INTERNAL_API_BASE_URL:-http://api:3001}
      NEXT_PUBLIC_API_BASE_URL: ${NEXT_PUBLIC_API_BASE_URL:-http://localhost:3001}
      DATABASE_URL: mysql://singitronic_user:singitronic_local_2026@db:3306/singitronic_nextjs?sslmode=disabled
    ports:
      - "3000:3000"

volumes:
  mysql_data:
```

---

## 7. Screenshots to Attach in Submission

1. Local Docker image build success (`web` and `api`).
2. Docker Hub repositories showing pushed images and tags.
3. EC2 terminal output for `docker compose pull` and `docker compose up -d`.
4. `docker compose ps` showing all three services up.
5. API health response (`/health`).
6. Frontend home page loaded from EC2 public IP.
7. Logs proving demo data seeding ran successfully.
8. Database volume evidence (e.g., restart stack and show data persistence).

---

## 8. Conclusion

The web application was successfully containerized and deployed on AWS EC2 using Docker and Docker Compose. The setup includes persistent MySQL storage through a named volume and automated migration + optional demo seeding during API startup. This satisfies the assignment requirements for Part I.
