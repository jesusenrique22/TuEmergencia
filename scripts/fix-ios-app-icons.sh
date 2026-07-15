#!/usr/bin/env bash
# Quita canal alpha de iconos iOS (requerido por App Store / TestFlight).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ICON_DIR="$ROOT/ios/Runner/Assets.xcassets/AppIcon.appiconset"

for f in "$ICON_DIR"/*.png; do
  base="${f%.png}"
  sips -s format jpeg "$f" --out "${base}.jpg" >/dev/null 2>&1
  sips -s format png "${base}.jpg" --out "$f" >/dev/null 2>&1
  rm -f "${base}.jpg"
done

echo "✓ Iconos iOS sin alpha ($(ls "$ICON_DIR"/*.png | wc -l | tr -d ' ') archivos)"
