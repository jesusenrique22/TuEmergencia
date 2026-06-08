#!/usr/bin/env bash
# Atajo: mismo stack que 2 terminales, en un solo proceso (Ctrl+C detiene API + web).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "Arrancando API + web (:8088) + gateway en una terminal…"
echo "  (Recomendado: cd backend && pnpm run dev  |  cd realtime-gateway && pnpm run dev)"
echo ""

PIDS=()
cleanup() {
  for pid in "${PIDS[@]}"; do kill "$pid" 2>/dev/null || true; done
}
trap cleanup EXIT INT TERM

(cd "$ROOT/backend" && pnpm run dev) &
PIDS+=($!)
sleep 1
(cd "$ROOT/realtime-gateway" && pnpm run dev) &
PIDS+=($!)

wait
