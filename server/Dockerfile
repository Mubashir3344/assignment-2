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
