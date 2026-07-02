#!/usr/bin/env bash
# Compila iOS release para TestFlight (usa .env del repo).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f "$ROOT/.env" ]]; then
  echo "✗ Falta .env en la raíz del proyecto."
  exit 1
fi

API_URL="$(grep -E '^API_BASE_URL=' "$ROOT/.env" | cut -d= -f2- | tr -d '\r"')"
SOCKET_URL="$(grep -E '^SOCKET_URL=' "$ROOT/.env" | cut -d= -f2- | tr -d '\r"')"

echo ""
echo "TuEmergencia — build iOS (TestFlight)"
echo "────────────────────────────────────"
echo "  App:     TuEmergencia"
echo "  Bundle:  com.tuemergencia.app"
echo "  API:     ${API_URL}"
echo "  Socket:  ${SOCKET_URL}"
echo ""

if [[ "$API_URL" == *"127.0.0.1"* || "$API_URL" == *"localhost"* ]]; then
  echo "✗ API_BASE_URL no puede ser localhost en TestFlight. Edita .env con URLs Render."
  exit 1
fi

flutter pub get
flutter build ios --release --no-codesign

echo ""
echo "✓ Build iOS listo. Abre ios/Runner.xcworkspace → Archive → TestFlight"
echo ""

if [[ "${1:-}" == "--archive" ]]; then
  open ios/Runner.xcworkspace
fi
