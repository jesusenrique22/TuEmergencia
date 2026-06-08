#!/usr/bin/env bash
# Comprueba que JWT e INTERNAL_REALTIME_SECRET coinciden entre backend y gateway.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

read_env() {
  local file=$1 key=$2
  if [[ -f "$file" ]]; then
    grep -E "^${key}=" "$file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '\r"' || true
  fi
}

jwt_be=$(read_env backend/.env JWT_SECRET)
jwt_gw=$(read_env realtime-gateway/.env JWT_SECRET)
int_be=$(read_env backend/.env INTERNAL_REALTIME_SECRET)
int_gw=$(read_env realtime-gateway/.env INTERNAL_REALTIME_SECRET)

ok=0
warn() { echo "  ⚠ $1"; ok=1; }
fail() { echo "  ✗ $1"; ok=1; }
pass() { echo "  ✓ $1"; }

echo ""
echo "Verificación de entorno Smart Medic"
echo "──────────────────────────────────"

if [[ -z "$jwt_be" && -z "$jwt_gw" ]]; then
  pass "JWT_SECRET: usando defaults de config/secrets.defaults.cjs"
elif [[ -n "$jwt_be" && "$jwt_be" == "$jwt_gw" ]]; then
  pass "JWT_SECRET alineado (backend ↔ gateway)"
elif [[ -n "$jwt_be" && -z "$jwt_gw" ]]; then
  warn "JWT solo en backend/.env — copia a realtime-gateway/.env"
elif [[ -n "$jwt_be" && -n "$jwt_gw" && "$jwt_be" != "$jwt_gw" ]]; then
  fail "JWT_SECRET distinto: backend y gateway deben coincidir"
else
  warn "Define JWT_SECRET en backend/.env y realtime-gateway/.env"
fi

if [[ -z "$int_be" && -z "$int_gw" ]]; then
  pass "INTERNAL_REALTIME_SECRET: defaults de desarrollo"
elif [[ -n "$int_be" && "$int_be" == "$int_gw" ]]; then
  pass "INTERNAL_REALTIME_SECRET alineado"
elif [[ -n "$int_be" && -n "$int_gw" && "$int_be" != "$int_gw" ]]; then
  fail "INTERNAL_REALTIME_SECRET distinto entre servicios"
else
  warn "Define INTERNAL_REALTIME_SECRET en ambos .env"
fi

if [[ -f .env ]]; then
  pass "Flutter .env presente"
  tunnel_prefix=$(read_env .env TUNNEL_PREFIX)
  if [[ -n "$tunnel_prefix" ]]; then
    pass "TUNNEL_PREFIX definido (modo Dev Tunnel, origen :8088)"
  fi
  pub_api=$(read_env .env PUBLIC_API_URL)
  pub_sock=$(read_env .env PUBLIC_SOCKET_URL)
  if [[ -n "$pub_api" || -n "$pub_sock" ]]; then
    warn "PUBLIC_* obsoleto — elimínalo; usa solo TUNNEL_PREFIX (./scripts/tunnel-sync-env.sh --from-env)"
  fi
else
  warn "Falta .env en raíz (copia desde .env.example)"
fi

FLUTTER_SDK="${FLUTTER_SDK:-/Users/smart/flutter}"
if [[ -f "$ROOT/config/local-paths.env" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT/config/local-paths.env"
fi
xcc="$ROOT/ios/Flutter/Generated.xcconfig"
legacy_re='GitHub/Smart-Medic|GitHub/Smart_Medic|Documents/GitHub/'
if [[ -f "$xcc" ]]; then
  if grep -qE "$legacy_re" "$xcc" 2>/dev/null; then
    fail "Generated.xcconfig tiene rutas GitHub/Smart-Medic — ./scripts/ensure-local-paths.sh"
  elif ! grep -q "FLUTTER_APPLICATION_PATH=$ROOT" "$xcc"; then
    fail "FLUTTER_APPLICATION_PATH no es $ROOT — ./scripts/ensure-local-paths.sh"
  elif ! grep -q "FLUTTER_ROOT=$FLUTTER_SDK" "$xcc"; then
    fail "FLUTTER_ROOT no es $FLUTTER_SDK — ./scripts/ensure-local-paths.sh"
  else
    pass "Generated.xcconfig (iOS) alineado"
  fi
else
  warn "Falta Generated.xcconfig — ./scripts/ensure-local-paths.sh"
fi

if [[ -x "$FLUTTER_SDK/bin/flutter" ]]; then
  pass "Flutter SDK en $FLUTTER_SDK"
else
  fail "No hay Flutter en $FLUTTER_SDK (ajusta dart.flutterSdkPath en .vscode/settings.json)"
fi

if [[ -f "$ROOT/android/local.properties" ]]; then
  and_sdk=$(grep '^flutter.sdk=' "$ROOT/android/local.properties" 2>/dev/null | cut -d= -f2- || true)
  if [[ "$and_sdk" == "$FLUTTER_SDK" ]]; then
    pass "android/local.properties alineado con Flutter SDK"
  elif [[ -n "$and_sdk" ]]; then
    warn "android/local.properties flutter.sdk=$and_sdk (esperado $FLUTTER_SDK)"
  fi
fi

echo ""
if [[ $ok -ne 0 ]]; then
  echo "Corrige antes de depurar sockets/CORS. Ver docs/ENV.md"
  exit 1
fi
echo "Entorno coherente. docs/COMMUNICATION.md"
exit 0
