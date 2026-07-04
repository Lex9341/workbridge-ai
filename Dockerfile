# Builds only backend/ - the NestJS API service. app/ is the Flutter
# client, which isn't something you `docker run` as a web service, so it's
# out of scope for this image.
FROM node:22-alpine AS build
WORKDIR /app
COPY backend/package.json backend/package-lock.json* ./
RUN npm install
COPY backend/ .
RUN npx prisma generate
RUN npm run build

FROM node:22-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/prisma ./prisma
# No DATABASE_URL/STORAGE_DRIVER set here on purpose: runtime-config.ts
# only switches to Postgres when STORAGE_DRIVER=postgres AND DATABASE_URL
# are both set, so without them the backend runs standalone against its
# local JSON file storage - no external Postgres container required.
EXPOSE 3000
CMD ["node", "dist/main.js"]
