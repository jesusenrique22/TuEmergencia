#!/usr/bin/env bash
# Comprueba stack local + URL Dev Tunnel única (:8088, proxy API/gateway).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PORT_WEB="${FLUTTER_WEB_PORT:-8088}"
REGION="${TUNNEL_REGION:-use2}"
TUNNEL_PREFIX=""
if [[ -f .env ]]; then
  val=$(grep -E '^FLUTTER_WEB_PORT=' .env 2>/dev/null | cut -d= -f2- | tr -d '\r"' || true)
  [[ -n "$val" ]] && PORT_WEB="$val"
  TUNNEL_PREFIX=$(grep -E '^TUNNEL_PREFIX=' .env 2>/dev/null | cut -d= -f2- | tr -d '\r"' || true)
  r=$(grep -E '^TUNNEL_REGION=' .env 2>/dev/null | cut -d= -f2- | tr -d '\r"' || true)
  [[ -n "$r" ]] && REGION="$r"
fi

echo ""
echo "Salud local"
./scripts/check-dev-ports.sh || true

if [[ -z "$TUNNEL_PREFIX" ]]; then
  echo ""
  echo "Sin TUNNEL_PREFIX en .env."
  echo "  Cursor → Puertos → ${PORT_WEB} → Público → copia la URL y ejecuta:"
  echo "    ./scripts/tunnel-sync-env.sh https://TU-PREFIJO-${PORT_WEB}.${REGION}.devtunnels.ms"
  exit 0
fi

BASE="https://${TUNNEL_PREFIX}-${PORT_WEB}.${REGION}.devtunnels.ms"

probe() {
  local name=$1 url=$2
  local code time
  local line
  line=$(curl -s -o /dev/null -w "%{http_code} %{time_total}" --max-time 90 "$url" 2>/dev/null || echo "000 0")
  code=$(echo "$line" | awk '{print $1}')
  time=$(echo "$line" | awk '{print $2}')
  if [[ "$code" == "200" ]]; then
    echo "  ✓ $name — $code (${time}s)"
  elif [[ "$code" == "502" || "$code" == "504" ]]; then
    echo "  ✗ $name — $code (${time}s) ← sin servicio local o timeout del túnel"
  else
    echo "  ✗ $name — $code (${time}s)"
  fi
}

echo ""
echo "Túnel ($TUNNEL_PREFIX, origen único :${PORT_WEB})"
probe "Web /" "${BASE}/"
probe "Web main.dart.js" "${BASE}/main.dart.js"
probe "API /health (proxy)" "${BASE}/health"
probe "Gateway /gateway-health (proxy)" "${BASE}/gateway-health"
echo ""
echo "Si main.dart.js da 504: reinicia cd backend && pnpm run dev y recarga forzada."
echo "Alternativa rápida: http://127.0.0.1:${PORT_WEB} en el Mac o LAN (DEV_HOST)."
echo ""
