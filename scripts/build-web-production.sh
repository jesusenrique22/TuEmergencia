#!/usr/bin/env bash
# Compila Flutter web para Render (usa .env del repo).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f "$ROOT/.env" ]]; then
  echo "✗ Falta .env en la raíz del proyecto."
  exit 1
fi

API_BASE_URL="$(grep -E '^API_BASE_URL=' .env | cut -d= -f2- | tr -d '\r"')"
SOCKET_URL="$(grep -E '^SOCKET_URL=' .env | cut -d= -f2- | tr -d '\r"')"

echo ""
echo "TuEmergencia — build web producción"
echo "──────────────────────────────────"
echo "  API:    ${API_BASE_URL}"
echo "  Socket: ${SOCKET_URL}"
echo ""

flutter build web --release \
  --no-tree-shake-icons \
  --no-web-resources-cdn \
  --dart-define=ENABLE_DEV_TOOLS=false

if [[ -f "$ROOT/deploy/web/_redirects" ]]; then
  cp "$ROOT/deploy/web/_redirects" "$ROOT/build/web/_redirects"
fi

echo ""
echo "✓ Listo: $ROOT/build/web"
echo ""
