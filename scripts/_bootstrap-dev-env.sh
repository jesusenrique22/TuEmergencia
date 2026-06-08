#!/usr/bin/env bash
# Sincroniza .env del Dev Tunnel y muestra estado de puertos (no arranca servicios).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT_WEB="${FLUTTER_WEB_PORT:-8088}"

if [[ -f "$ROOT/.env" ]]; then
  val=$(grep -E '^FLUTTER_WEB_PORT=' "$ROOT/.env" 2>/dev/null | cut -d= -f2- | tr -d '\r"' || true)
  [[ -n "$val" ]] && PORT_WEB="$val"
fi

if [[ -f "$ROOT/.env" ]] && grep -qE '^TUNNEL_PREFIX=' "$ROOT/.env" 2>/dev/null; then
  "$ROOT/scripts/tunnel-sync-env.sh" --from-env --quiet 2>/dev/null || true
fi

api_ok() {
  curl -sf --connect-timeout 2 "http://127.0.0.1:3000/health" >/dev/null 2>&1
}

gateway_ok() {
  curl -sf --connect-timeout 2 "http://127.0.0.1:3001/health" >/dev/null 2>&1
}

prefix=$(grep -E '^TUNNEL_PREFIX=' "$ROOT/.env" 2>/dev/null | cut -d= -f2- | tr -d '\r"' || true)
if [[ -n "$prefix" ]]; then
  region=$(grep -E '^TUNNEL_REGION=' "$ROOT/.env" 2>/dev/null | cut -d= -f2- | tr -d '\r"' || true)
  [[ -z "$region" ]] && region="use2"
  echo "→ Túnel app: https://${prefix}-${PORT_WEB}.${region}.devtunnels.ms"
  echo "→ Cursor Puertos: solo ${PORT_WEB} Público (3000/3001 local)"
fi

if ! api_ok; then
  echo "→ API :3000 — arranca en otra terminal: cd backend && pnpm run dev"
fi

if ! gateway_ok; then
  echo "→ Gateway :3001 — arranca en otra terminal: cd realtime-gateway && pnpm run dev"
fi
