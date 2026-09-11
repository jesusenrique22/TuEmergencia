#!/usr/bin/env bash
# Build para Render (repo jesusenrique22/backend).
set -euo pipefail

corepack enable
# --prod=false: NODE_ENV=production no debe omitir typescript/prisma
pnpm install --frozen-lockfile --prod=false
pnpm exec prisma generate
pnpm exec tsc
pnpm exec prisma migrate deploy
