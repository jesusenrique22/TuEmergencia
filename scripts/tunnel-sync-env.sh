#!/usr/bin/env bash
# Actualiza TUNNEL_PREFIX en .env a partir del Dev Tunnel (panel Puertos de Cursor).
#
# Uso:
#   ./scripts/tunnel-sync-env.sh                    # muestra estado + ayuda
#   ./scripts/tunnel-sync-env.sh bbsl5rv7           # prefijo (región use2 por defecto)
#   ./scripts/tunnel-sync-env.sh https://bbsl5rv7-8088.use2.devtunnels.ms
#   ./scripts/tunnel-sync-env.sh --from-env         # reaplica TUNNEL_PREFIX y limpia PUBLIC_* obsoletos
#   ./scripts/tunnel-sync-env.sh --check            # comprueba si el túnel en .env responde
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT/.env"
PORT_WEB="${FLUTTER_WEB_PORT:-8088}"
REGION="${TUNNEL_REGION:-use2}"
QUIET=false

if [[ -f "$ENV_FILE" ]]; then
  val=$(grep -E '^FLUTTER_WEB_PORT=' "$ENV_FILE" 2>/dev/null | cut -d= -f2- | tr -d '\r"' || true)
  [[ -n "$val" ]] && PORT_WEB="$val"
  r=$(grep -E '^TUNNEL_REGION=' "$ENV_FILE" 2>/dev/null | cut -d= -f2- | tr -d '\r"' || true)
  if [[ -n "$r" ]]; then
    REGION="$r"
  fi
fi

for arg in "$@"; do
  case "$arg" in
    --quiet) QUIET=true ;;
    --check) MODE=check ;;
    --from-env) MODE=from_env ;;
  esac
done

log() {
  $QUIET && return 0
  echo "$@"
}

parse_prefix() {
  local input="${1:-}"
  input="${input%/}"
  if [[ -z "$input" ]]; then
    return 1
  fi
  if [[ "$input" =~ devtunnels\.ms ]]; then
    local host
    host=$(echo "$input" | sed -E 's#^https?://([^/]+).*#\1#')
    if [[ "$host" =~ ^(.+)-([0-9]+)\.([a-z0-9]+)\.devtunnels\.ms$ ]]; then
      REGION="${BASH_REMATCH[3]}"
      echo "${BASH_REMATCH[1]}"
      return 0
    fi
    return 1
  fi
  # prefijo suelto (sin URL)
  echo "$input" | tr -d '[:space:]'
}

read_env_var() {
  local key=$1
  grep -E "^${key}=" "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '\r"' || true
}

set_env_var() {
  local key=$1
  local value=$2
  if [[ ! -f "$ENV_FILE" ]]; then
    cp "$ROOT/.env.example" "$ENV_FILE" 2>/dev/null || touch "$ENV_FILE"
  fi
  if grep -qE "^${key}=" "$ENV_FILE" 2>/dev/null; then
    if [[ "$(uname)" == Darwin ]]; then
      sed -i '' "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
    else
      sed -i "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
    fi
  else
    echo "${key}=${value}" >>"$ENV_FILE"
  fi
}

apply_prefix() {
  local prefix=$1
  local web="https://${prefix}-${PORT_WEB}.${REGION}.devtunnels.ms"

  set_env_var TUNNEL_PREFIX "$prefix"

  # Modo un solo túnel: quitar PUBLIC_* obsoletos (evita confusión con -3000/-3001)
  for key in PUBLIC_API_URL PUBLIC_SOCKET_URL; do
    if [[ -f "$ENV_FILE" ]] && grep -qE "^${key}=" "$ENV_FILE" 2>/dev/null; then
      if [[ "$(uname)" == Darwin ]]; then
        sed -i '' "/^${key}=/d" "$ENV_FILE"
      else
        sed -i "/^${key}=/d" "$ENV_FILE"
      fi
    fi
  done

  log ""
  log "✓ .env actualizado (región ${REGION})"
  log "  TUNNEL_PREFIX=${prefix}"
  log "  URL app (única pública): ${web}"
  log ""
  log "  Cursor → Puertos → ${PORT_WEB} → Público"
  log "  3000 y 3001: solo local (Privado o sin túnel)"
  log "  API/socket en la app van por proxy en :${PORT_WEB}"
  log ""
  log "  Tras cambiar Dart: ./scripts/serve-web-tunnel.sh --build"
  log ""
}

MODE="${MODE:-}"

if [[ "$MODE" == "check" ]]; then
  prefix=$(read_env_var TUNNEL_PREFIX)
  if [[ -z "$prefix" ]]; then
    echo "✗ Sin TUNNEL_PREFIX en .env"
    echo "  Copia la URL del puerto ${PORT_WEB} (Público) en Cursor → Puertos y ejecuta:"
    echo "    ./scripts/tunnel-sync-env.sh TU-PREFIJO-o-URL-8088"
    exit 1
  fi
  if ! curl -sf --connect-timeout 2 "http://127.0.0.1:${PORT_WEB}/" >/dev/null 2>&1; then
    echo "✗ Nada escucha en http://127.0.0.1:${PORT_WEB} (causa habitual del 502)."
    echo "  El túnel de Cursor reenvía :${PORT_WEB} → tu Mac; sin servidor local = 502."
    echo ""
    echo "  Arranca la web en otra terminal (con backend + gateway ya activos):"
    echo "    cd backend && pnpm run dev"
    echo "  (arranca la web en :${PORT_WEB} automáticamente)"
    exit 1
  fi
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 \
    "https://${prefix}-${PORT_WEB}.${REGION}.devtunnels.ms/" 2>/dev/null || echo "000")
  if [[ "$code" == "200" ]]; then
    echo "✓ Local :${PORT_WEB} OK · túnel web responde (${prefix}, HTTP ${code})"
    exit 0
  fi
  echo "✗ Local :${PORT_WEB} OK pero el túnel devuelve HTTP ${code}."
  echo "  Prueba: Cursor → Puertos → elimina ${PORT_WEB} y vuelve a marcar Público."
  echo "  Si cambió la URL: ./scripts/tunnel-sync-env.sh NUEVA-URL-${PORT_WEB}"
  exit 1
fi

if [[ "$MODE" == "from_env" ]]; then
  prefix=$(read_env_var TUNNEL_PREFIX)
  if [[ -z "$prefix" ]]; then
    echo "✗ Define TUNNEL_PREFIX=… en .env o pasa el prefijo como argumento."
    exit 1
  fi
  apply_prefix "$prefix"
  exit 0
fi

# Sin argumentos: estado + ayuda
if [[ $# -eq 0 ]] || [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  prefix=$(read_env_var TUNNEL_PREFIX)
  pub_web=""
  if [[ -n "$prefix" ]]; then
    pub_web="https://${prefix}-${PORT_WEB}.${REGION}.devtunnels.ms"
  fi
  echo ""
  echo "Dev Tunnel — sincronizar .env"
  echo "────────────────────────────"
  if [[ -n "$prefix" ]]; then
    echo "  TUNNEL_PREFIX=${prefix}"
    echo "  Web (única URL pública): ${pub_web}"
  else
    echo "  (sin TUNNEL_PREFIX en .env)"
  fi
  echo ""
  echo "  1) Cursor → Puertos → ${PORT_WEB} → Visibilidad → Público"
  echo "  2) Copia la URL (ej. https://abcd1234-${PORT_WEB}.use2.devtunnels.ms)"
  echo "  3) Ejecuta:"
  echo "       ./scripts/tunnel-sync-env.sh https://TU-URL-${PORT_WEB}.use2.devtunnels.ms"
  echo "     o solo el prefijo:"
  echo "       ./scripts/tunnel-sync-env.sh abcd1234"
  echo ""
  echo "  Al arrancar backend: en .env define TUNNEL_PREFIX=abcd1234 y pnpm run dev lo aplica"
  echo "  Comprobar: ./scripts/tunnel-sync-env.sh --check"
  echo ""
  exit 0
fi

# Primer arg que no sea flag
INPUT=""
for arg in "$@"; do
  case "$arg" in
    --quiet | --check | --from-env) ;;
    *) INPUT="$arg" ;;
  esac
done

PREFIX=$(parse_prefix "$INPUT" || true)
if [[ -z "$PREFIX" ]]; then
  echo "✗ No pude leer el prefijo desde: $INPUT"
  echo "  Usa: ./scripts/tunnel-sync-env.sh https://PREFIJO-${PORT_WEB}.use2.devtunnels.ms"
  exit 1
fi

apply_prefix "$PREFIX"
