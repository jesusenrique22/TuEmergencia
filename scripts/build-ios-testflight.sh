#!/usr/bin/env bash
# Prepara .env y compila iOS release para TestFlight / App Store.
#
# Uso:
#   ./scripts/build-ios-testflight.sh
#   ./scripts/build-ios-testflight.sh --archive   # abre Xcode archive después
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ENV_SOURCE=""
if [[ -f "$ROOT/.env.production.local" ]]; then
  ENV_SOURCE="$ROOT/.env.production.local"
elif [[ -f "$ROOT/.env.ios.production.local" ]]; then
  ENV_SOURCE="$ROOT/.env.ios.production.local"
elif [[ -f "$ROOT/.env.ios.production.example" ]]; then
  ENV_SOURCE="$ROOT/.env.ios.production.example"
else
  echo "✗ Crea .env.ios.production.local con API_BASE_URL y SOCKET_URL (Render)."
  exit 1
fi

ENV_BACKUP=""
if [[ -f "$ROOT/.env" ]]; then
  ENV_BACKUP="$(mktemp)"
  cp "$ROOT/.env" "$ENV_BACKUP"
fi
cleanup() {
  if [[ -n "$ENV_BACKUP" && -f "$ENV_BACKUP" ]]; then
    cp "$ENV_BACKUP" "$ROOT/.env"
    rm -f "$ENV_BACKUP"
  fi
}
trap cleanup EXIT

cp "$ENV_SOURCE" "$ROOT/.env"

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
  echo "✗ API_BASE_URL no puede ser localhost en TestFlight."
  exit 1
fi

echo "→ flutter pub get"
flutter pub get

echo "→ Compilando iOS release (sin codesign automático)…"
flutter build ios --release --no-codesign

echo ""
echo "✓ Build iOS listo en build/ios/iphoneos/Runner.app"
echo ""
echo "Siguiente paso en Xcode:"
echo "  1) open ios/Runner.xcworkspace"
echo "  2) Product → Archive"
echo "  3) Distribute App → TestFlight"
echo ""
echo "En App Store Connect crea la app «TuEmergencia» con bundle id:"
echo "  com.tuemergencia.app"
echo ""

if [[ "${1:-}" == "--archive" ]]; then
  open ios/Runner.xcworkspace
fi
