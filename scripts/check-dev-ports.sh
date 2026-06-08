#!/usr/bin/env bash
# Comprueba que backend (3000), gateway (3001) y Flutter web (8088) escuchan.
set -euo pipefail

PORT_WEB="${FLUTTER_WEB_PORT:-8088}"
if [[ -f .env ]]; then
  val=$(grep -E '^FLUTTER_WEB_PORT=' .env 2>/dev/null | cut -d= -f2- | tr -d '\r"' || true)
  [[ -n "$val" ]] && PORT_WEB="$val"
fi

check_port() {
  local port=$1 name=$2
  if lsof -iTCP:"$port" -sTCP:LISTEN -P -n >/dev/null 2>&1; then
    echo "  ✓ $name — puerto $port (activo)"
    return 0
  fi
  echo "  ✗ $name — puerto $port (NO hay proceso escuchando)"
  return 1
}

echo ""
echo "Estado de puertos Smart Medic"
echo "─────────────────────────────"

ok=0
check_port 3000 "Backend API" || ok=1
check_port 3001 "Gateway Socket" || ok=1
check_port "$PORT_WEB" "Flutter web" || ok=1

echo ""
if [[ $ok -ne 0 ]]; then
  echo "502 en Dev Tunnel = el puerto no tiene servicio local."
  echo ""
  echo "Arranca en dos terminales:"
  echo "  cd backend && pnpm run dev              # API :3000 + web :$PORT_WEB"
  echo "  cd realtime-gateway && pnpm run dev     # Gateway :3001"
  echo "  ./scripts/dev-services.sh               # atajo: ambos en paralelo"
  echo "  ./scripts/serve-web-tunnel.sh --build   # solo si cambiaste Dart"
  echo "  ./scripts/stop-dev-ports.sh        # detener todo y empezar limpio"
  echo ""
  echo "Luego en Cursor → Puertos: solo $PORT_WEB en Público (API/gateway vía proxy)."
  echo "Ver docs/DEV_TUNNELS.md"
  exit 1
fi

echo ""
echo "Todo listo."
if [[ -f .env ]]; then
  p=$(grep -E '^TUNNEL_PREFIX=' .env 2>/dev/null | cut -d= -f2- | tr -d '\r"' || true)
  if [[ -n "$p" ]]; then
    echo "  Túnel: https://${p}-${PORT_WEB}.use2.devtunnels.ms"
  fi
fi
echo "  Cursor → solo ${PORT_WEB} Público · 3000/3001 local"
echo "  Local: http://127.0.0.1:${PORT_WEB}"
exit 0
