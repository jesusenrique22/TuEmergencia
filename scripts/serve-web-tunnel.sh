#!/usr/bin/env bash
# Compila y sirve la app web para Dev Tunnels (panel debug + sin caché agresiva).
#
# Uso:
#   ./scripts/serve-web-tunnel.sh              # compila + sirve (reinicia :8088)
#   ./scripts/serve-web-tunnel.sh --serve-only # sirve sin recompilar (o compila si falta build/)
#   ./scripts/serve-web-tunnel.sh --build      # fuerza recompilación
#   ./scripts/serve-web-tunnel.sh --status
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PORT="${TUNNEL_WEB_PORT:-8088}"
if [[ -f .env ]]; then
  val=$(grep -E '^FLUTTER_WEB_PORT=' .env 2>/dev/null | cut -d= -f2- | tr -d '\r"' || true)
  [[ -n "$val" ]] && PORT="$val"
fi

BUILD_DIR="$ROOT/build/web"
SERVE_ONLY=false
FORCE_BUILD=false
STATUS_ONLY=false

for arg in "$@"; do
  case "$arg" in
    --status) STATUS_ONLY=true ;;
    --serve-only) SERVE_ONLY=true ;;
    --build) FORCE_BUILD=true ;;
  esac
done

free_port() {
  local pids
  pids=$(lsof -tiTCP:"$PORT" -sTCP:LISTEN 2>/dev/null || true)
  if [[ -n "$pids" ]]; then
    echo "→ Liberando puerto $PORT (PID $pids)…"
    kill $pids 2>/dev/null || true
    sleep 0.5
    pids=$(lsof -tiTCP:"$PORT" -sTCP:LISTEN 2>/dev/null || true)
    [[ -n "$pids" ]] && kill -9 $pids 2>/dev/null || true
  fi
}

web_listening() {
  lsof -iTCP:"$PORT" -sTCP:LISTEN -P -n >/dev/null 2>&1
}

web_responds() {
  curl -sf --connect-timeout 2 "http://127.0.0.1:${PORT}/" >/dev/null 2>&1
}

ensure_build() {
  if $FORCE_BUILD || [[ ! -f "$BUILD_DIR/index.html" ]]; then
    echo "Compilando Flutter web (release + panel debug para túneles)…"
    flutter build web --release \
      --no-tree-shake-icons \
      --no-web-resources-cdn \
      --dart-define=ENABLE_DEV_TOOLS=true
  elif $SERVE_ONLY; then
    echo "→ Usando build existente en build/web (pasa --build para recompilar)."
  fi
}

if [[ "${STATUS_ONLY:-false}" == true ]]; then
  if web_responds; then
    echo "✓ Web activa en http://127.0.0.1:${PORT}"
    echo "  Túnel: https://….-${PORT}.devtunnels.ms"
    echo "  Para recompilar: ./scripts/serve-web-tunnel.sh --build"
  else
    echo "✗ Web NO está en el puerto $PORT"
    echo "  Arranca: cd backend && pnpm run dev"
  fi
  exit 0
fi

if $SERVE_ONLY && web_responds; then
  echo "✓ Flutter web ya responde en http://127.0.0.1:${PORT}"
  exit 0
fi

free_port
ensure_build
free_port

health_ok() {
  curl -sf --connect-timeout 2 "http://127.0.0.1:$1/health" >/dev/null 2>&1
}

echo ""
if ! health_ok 3000 || ! health_ok 3001; then
  echo "⚠  API (3000) o gateway (3001) NO están activos."
  echo "   Este script solo sirve la web; el proxy devolverá 502 en /api y /socket.io."
  echo ""
  echo "   Arranca el stack completo en otra terminal:"
  echo "     cd backend && pnpm run dev"
  echo ""
  echo "   O solo recompilar sin dejar web sola:"
  echo "     cd backend && pnpm run dev"
  echo ""
fi

echo "════════════════════════════════════════════════════════════"
echo "  Web en http://0.0.0.0:${PORT} (sin caché en HTML/JS)"
echo ""
echo "  Cursor → Solo puerto ${PORT} en Público (app + API + gateway vía proxy)"
echo "  App:    https://….-${PORT}.devtunnels.ms"
echo "  Debug:  🐛 en Mensajes o #/debug/gateway"
echo ""
echo "  Solo recompilar:  ./scripts/serve-web-tunnel.sh --build"
echo "  Stack: cd backend && pnpm run dev  (+ gateway en otra terminal)"
echo "════════════════════════════════════════════════════════════"
echo ""

exec python3 "$ROOT/scripts/serve_web_no_cache.py" --port "$PORT" --directory "$BUILD_DIR"
