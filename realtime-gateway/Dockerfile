# Gateway Socket.IO — build fijo (evita Nixpacks + pnpm/node:sqlite en Node 20)
FROM node:22-bookworm-slim

WORKDIR /app

RUN corepack enable

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY tsconfig.json ./
COPY src ./src

RUN pnpm run build

ENV NODE_ENV=production
EXPOSE 3001

CMD ["node", "dist/index.js"]
