FROM node:20-bookworm-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
COPY shared/package.json shared/
COPY server/package.json server/
COPY client/package.json client/
RUN PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 npm ci --include=dev
COPY . .
RUN npm run build

FROM node:20-bookworm-slim
ENV NODE_ENV=production
WORKDIR /app
COPY --from=build /app /app
EXPOSE 4000
CMD ["npm", "start"]
