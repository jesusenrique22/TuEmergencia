#!/usr/bin/env bash
# Alinea rutas del proyecto (Smart_Medic en Documents) y elimina referencias a GitHub/Smart-Medic.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Valores por defecto para esta Mac
FLUTTER="${FLUTTER_SDK:-/Users/smart/flutter}"
ANDROID_SDK="${ANDROID_SDK:-${ANDROID_HOME:-$HOME/Library/Android/sdk}}"

if [[ -f "$ROOT/config/local-paths.env" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT/config/local-paths.env"
  FLUTTER="${FLUTTER_SDK:-$FLUTTER}"
  ANDROID_SDK="${ANDROID_SDK:-${ANDROID_HOME:-$ANDROID_SDK}}"
fi

if [[ ! -x "$FLUTTER/bin/flutter" ]]; then
  echo "No se encontró Flutter en $FLUTTER/bin/flutter"
  echo "Copia config/local-paths.env.example → config/local-paths.env y ajusta FLUTTER_SDK"
  exit 1
fi

echo "→ Proyecto: $ROOT"
echo "→ Flutter:  $FLUTTER"
echo "→ Android:  $ANDROID_SDK"
cd "$ROOT"

# Rutas legacy (repo clonado en GitHub/Smart-Medic o Smart_Medic)
LEGACY_PATTERN='GitHub/Smart-Medic|GitHub/Smart_Medic|Documents/GitHub/'

xcconfig_is_stale() {
  local file=$1
  [[ ! -f "$file" ]] && return 1
  if grep -qE "$LEGACY_PATTERN" "$file" 2>/dev/null; then
    return 0
  fi
  if grep -q '^FLUTTER_APPLICATION_PATH=' "$file" 2>/dev/null; then
    local app_path
    app_path=$(grep '^FLUTTER_APPLICATION_PATH=' "$file" | cut -d= -f2-)
    [[ "$app_path" != "$ROOT" ]] && return 0
  fi
  if grep -q '^FLUTTER_ROOT=' "$file" 2>/dev/null; then
    local flutter_root
    flutter_root=$(grep '^FLUTTER_ROOT=' "$file" | cut -d= -f2-)
    [[ "$flutter_root" != "$FLUTTER" ]] && return 0
  fi
  if grep -q '^PACKAGE_CONFIG=' "$file" 2>/dev/null; then
    local pkg
    pkg=$(grep '^PACKAGE_CONFIG=' "$file" | cut -d= -f2-)
    [[ "$pkg" != "$ROOT/.dart_tool/package_config.json" ]] && return 0
  fi
  return 1
}

remove_stale_xcconfigs() {
  local label=$1
  shift
  local removed=false
  for f in "$@"; do
    if xcconfig_is_stale "$f"; then
      echo "→ $label: rutas viejas en $(basename "$(dirname "$f")")/$(basename "$f") — regenerando…"
      rm -f "$f"
      removed=true
    fi
  done
  $removed
}

IOS_XC="$ROOT/ios/Flutter/Generated.xcconfig"
MACOS_XC="$ROOT/macos/Flutter/ephemeral/Flutter-Generated.xcconfig"

remove_stale_xcconfigs "iOS" "$IOS_XC" || true
remove_stale_xcconfigs "macOS" "$MACOS_XC" || true

# Regenera configs de Flutter (iOS + macOS ephemeral)
"$FLUTTER/bin/flutter" pub get

remove_stale_xcconfigs "iOS" "$IOS_XC" || true
remove_stale_xcconfigs "macOS" "$MACOS_XC" || true

# Si otro «flutter» en PATH regeneró rutas GitHub/Smart-Medic, corrige en el archivo.
patch_xcconfig_paths() {
  local file=$1
  [[ ! -f "$file" ]] && return 0
  xcconfig_is_stale "$file" || return 0
  echo "→ Parcheando rutas en $(basename "$file")…"
  if [[ "$(uname)" == Darwin ]]; then
    sed -i '' \
      -e "s|^FLUTTER_ROOT=.*|FLUTTER_ROOT=$FLUTTER|" \
      -e "s|^FLUTTER_APPLICATION_PATH=.*|FLUTTER_APPLICATION_PATH=$ROOT|" \
      -e "s|^FLUTTER_TARGET=.*|FLUTTER_TARGET=$ROOT/lib/main.dart|" \
      -e "s|^PACKAGE_CONFIG=.*|PACKAGE_CONFIG=$ROOT/.dart_tool/package_config.json|" \
      -e "s|/Documents/GitHub/Smart-Medic/flutter/flutter|$FLUTTER|g" \
      -e "s|/Documents/GitHub/Smart_Medic|$ROOT|g" \
      -e "s|/Documents/GitHub/Smart-Medic|$ROOT|g" \
      "$file"
  else
    sed -i \
      -e "s|^FLUTTER_ROOT=.*|FLUTTER_ROOT=$FLUTTER|" \
      -e "s|^FLUTTER_APPLICATION_PATH=.*|FLUTTER_APPLICATION_PATH=$ROOT|" \
      -e "s|^FLUTTER_TARGET=.*|FLUTTER_TARGET=$ROOT/lib/main.dart|" \
      -e "s|^PACKAGE_CONFIG=.*|PACKAGE_CONFIG=$ROOT/.dart_tool/package_config.json|" \
      -e "s|/Documents/GitHub/Smart-Medic/flutter/flutter|$FLUTTER|g" \
      -e "s|/Documents/GitHub/Smart_Medic|$ROOT|g" \
      -e "s|/Documents/GitHub/Smart-Medic|$ROOT|g" \
      "$file"
  fi
}

patch_xcconfig_paths "$IOS_XC"
[[ -f "$MACOS_XC" ]] && patch_xcconfig_paths "$MACOS_XC"

if [[ ! -f "$IOS_XC" ]]; then
  echo "✗ No se generó $IOS_XC — ejecuta: $FLUTTER/bin/flutter pub get"
  exit 1
fi

if xcconfig_is_stale "$IOS_XC"; then
  echo "✗ ios/Flutter/Generated.xcconfig sigue con rutas incorrectas."
  echo "  Asegura que Cursor use dart.flutterSdkPath=$FLUTTER"
  echo "  y que «flutter» en PATH no sea otro SDK:"
  echo "    which flutter"
  grep -E '^FLUTTER_ROOT=|^FLUTTER_APPLICATION_PATH=' "$IOS_XC" || true
  exit 1
fi

# android/local.properties
mkdir -p "$ROOT/android"
LP="$ROOT/android/local.properties"
write_android_props() {
  cat >"$LP" <<EOF
sdk.dir=$ANDROID_SDK
flutter.sdk=$FLUTTER
EOF
}

if [[ ! -f "$LP" ]]; then
  echo "→ Creando android/local.properties"
  write_android_props
elif ! grep -q "^flutter.sdk=$FLUTTER\$" "$LP" 2>/dev/null; then
  echo "→ Actualizando android/local.properties"
  write_android_props
elif grep -qE "$LEGACY_PATTERN" "$LP" 2>/dev/null; then
  echo "→ android/local.properties con rutas viejas — corrigiendo"
  write_android_props
else
  echo "✓ android/local.properties OK"
fi

if command -v pod >/dev/null 2>&1 && [[ -f "$ROOT/ios/Podfile" ]]; then
  (cd "$ROOT/ios" && pod install >/dev/null)
  echo "✓ pod install OK"
fi

echo "✓ Rutas alineadas a Smart_Medic ($ROOT)"
echo ""
grep -E '^FLUTTER_ROOT=|^FLUTTER_APPLICATION_PATH=|^PACKAGE_CONFIG=' "$IOS_XC"
echo "flutter.sdk=$FLUTTER (android)"
