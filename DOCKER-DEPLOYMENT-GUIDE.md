# Docker Deployment Guide

This project is containerized with three services:

- `web` (Next.js frontend)
- `api` (Node.js/Express backend)
- `db` (MySQL with persistent volume)

## 1) Build Images Locally

From the project root:

```bash
docker compose build
```

Optional, if deploying to EC2 and you know your public IP:

```bash
NEXT_PUBLIC_API_BASE_URL=http://<EC2_PUBLIC_IP>:3001 docker compose build web
```

## 2) Login To Docker Hub

```bash
docker login
```

## 3) Tag Images For Docker Hub

Replace `<DOCKERHUB_USERNAME>` with your username:

```bash
docker tag yourdockerhub/singitronic-web:latest <DOCKERHUB_USERNAME>/singitronic-web:latest
docker tag yourdockerhub/singitronic-api:latest <DOCKERHUB_USERNAME>/singitronic-api:latest
```

If you set `DOCKERHUB_USERNAME` before build, images are already tagged correctly:

```bash
DOCKERHUB_USERNAME=<DOCKERHUB_USERNAME> docker compose build
```

## 4) Push Images To Docker Hub

```bash
docker push <DOCKERHUB_USERNAME>/singitronic-web:latest
docker push <DOCKERHUB_USERNAME>/singitronic-api:latest
```

## 5) Deploy On EC2 (Pull + Run)

On your EC2 instance:

```bash
docker login
```

Create a deployment folder and copy only `docker-compose.yml` into it (or clone repo), then run:

```bash
export DOCKERHUB_USERNAME=<DOCKERHUB_USERNAME>
export NEXT_PUBLIC_API_BASE_URL=http://<EC2_PUBLIC_IP>:3001
export NEXTAUTH_SECRET=<LONG_RANDOM_SECRET>
export SEED_DEMO_DATA=true
docker compose pull
docker compose up -d
```

### Demo data import in setup

- Demo data is imported automatically by the `api` container on startup when `SEED_DEMO_DATA=true`.
- The seed script is idempotent, so reruns update existing demo rows instead of duplicating them.
- To skip demo data import, set `SEED_DEMO_DATA=false` before `docker compose up -d`.

## 6) Persistent Database Storage

The database service uses:

```yaml
volumes:
	- mysql_data:/var/lib/mysql
```

This keeps MySQL data persistent even if the DB container is recreated.

## 7) Useful Commands

```bash
docker compose ps
docker compose logs -f api
docker compose logs -f web
docker compose down
docker compose down -v
```

Use `docker compose down -v` only if you intentionally want to delete MySQL data.
