#!/usr/bin/env bash
# TuEmergencia — build + subida TestFlight 100% desde Terminal.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TEAM_ID="2L97DF8VG2"
BUNDLE_ID="com.tuemergencia.app"
ARCHIVE_PATH="$ROOT/build/ios/archive/Runner.xcarchive"
EXPORT_DIR="$ROOT/build/ios/ipa"
EXPORT_PLIST="$ROOT/ios/ExportOptions.plist"

echo ""
echo "TuEmergencia — TestFlight (Terminal)"
echo "════════════════════════════════════"

# ── 1. Desbloquear llavero (evita CodeSign failed) ──
echo ""
echo "→ Desbloquea el llavero (contraseña de tu Mac):"
security unlock-keychain ~/Library/Keychains/login.keychain-db 2>/dev/null || \
  security unlock-keychain login.keychain 2>/dev/null || true

# ── 2. Certificados ──
echo ""
echo "→ Certificados disponibles:"
security find-identity -v -p codesigning || true
if ! security find-identity -v -p codesigning 2>/dev/null | grep -q "Apple Distribution"; then
  echo ""
  echo "⚠ No hay certificado Apple Distribution."
  echo "  Una vez (solo la primera): Xcode → Settings → Accounts → SMART 2025 CA"
  echo "  → Manage Certificates → + → Apple Distribution"
  echo "  Luego vuelve a ejecutar este script."
  echo ""
fi

# ── 3. Preparar proyecto ──
echo ""
echo "→ Preparando proyecto…"
xattr -cr "$ROOT/ios" "$ROOT/build" 2>/dev/null || true
flutter pub get
(cd "$ROOT/ios" && pod install)

# ── 4. Archive con xcodebuild ──
echo ""
echo "→ Archive (10–15 min, no cierres la terminal)…"
mkdir -p "$(dirname "$ARCHIVE_PATH")"

xcodebuild \
  -workspace "$ROOT/ios/Runner.xcworkspace" \
  -scheme Runner \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  -destination "generic/platform=iOS" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
  CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates \
  archive

# ── 5. Exportar .ipa ──
echo ""
echo "→ Exportando .ipa…"
rm -rf "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR"

xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_PLIST" \
  -allowProvisioningUpdates

IPA="$(find "$EXPORT_DIR" -maxdepth 1 -name '*.ipa' | head -1)"
if [[ -z "$IPA" ]]; then
  echo "✗ No se generó el .ipa en $EXPORT_DIR"
  exit 1
fi

echo ""
echo "✓ IPA listo: $IPA"
echo ""

# ── 6. Subir (opcional) ──
if [[ "${1:-}" == "--upload" ]]; then
  APPLE_ID="${APPLE_ID:-}"
  APP_PASSWORD="${APP_PASSWORD:-}"

  if [[ -z "$APPLE_ID" || -z "$APP_PASSWORD" ]]; then
    echo "Para subir, define tu Apple ID y contraseña de app:"
    echo "  export APPLE_ID='tu@email.com'"
    echo "  export APP_PASSWORD='xxxx-xxxx-xxxx-xxxx'  # appleid.apple.com → Contraseñas de app"
    echo "  ./scripts/testflight-terminal.sh --upload"
    exit 0
  fi

  echo "→ Subiendo a App Store Connect…"
  xcrun altool --upload-app \
    --type ios \
    --file "$IPA" \
    --username "$APPLE_ID" \
    --password "$APP_PASSWORD"

  echo ""
  echo "✓ Subido. Ve a App Store Connect → TuEmergencia → TestFlight"
else
  echo "Para subir el .ipa a TestFlight:"
  echo ""
  echo "  Opción A — Transporter (App Store, gratis):"
  echo "    Abre Transporter y arrastra: $IPA"
  echo ""
  echo "  Opción B — Terminal:"
  echo "    export APPLE_ID='tu@email.com'"
  echo "    export APP_PASSWORD='xxxx-xxxx-xxxx-xxxx'"
  echo "    ./scripts/testflight-terminal.sh --upload"
  echo ""
fi
