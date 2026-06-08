#!/usr/bin/env bash
# Detiene procesos en 3000, 3001 y el puerto web del túnel (8088 por defecto).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PORT_WEB="${TUNNEL_WEB_PORT:-8088}"
if [[ -f .env ]]; then
  val=$(grep -E '^FLUTTER_WEB_PORT=' .env 2>/dev/null | cut -d= -f2- | tr -d '\r"' || true)
  [[ -n "$val" ]] && PORT_WEB="$val"
fi

kill_port() {
  local port=$1 name=$2
  local pids
  pids=$(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null || true)
  if [[ -z "$pids" ]]; then
    echo "  · $name (:$port) — no había proceso"
    return 0
  fi
  echo "  · $name (:$port) — deteniendo PID(s): $pids"
  kill $pids 2>/dev/null || true
  sleep 0.5
  pids=$(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null || true)
  if [[ -n "$pids" ]]; then
    kill -9 $pids 2>/dev/null || true
  fi
}

echo ""
echo "Deteniendo servicios Smart Medic…"
kill_port "$PORT_WEB" "Flutter web"
kill_port 3000 "Backend API"
kill_port 3001 "Gateway Socket"
echo ""
echo "Listo. Arranca de nuevo con:"
echo "  cd backend && pnpm run dev"
echo "  cd realtime-gateway && pnpm run dev"
echo ""
