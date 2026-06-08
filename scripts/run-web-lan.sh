#!/usr/bin/env bash
# Arranca Flutter web en 0.0.0.0 para abrir la app desde otro dispositivo (misma Wi‑Fi).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PORT="${FLUTTER_WEB_PORT:-8088}"
if [[ -f .env ]]; then
  # shellcheck disable=SC1091
  source <(grep -E '^FLUTTER_WEB_PORT=' .env 2>/dev/null | sed 's/^/export /') || true
  PORT="${FLUTTER_WEB_PORT:-$PORT}"
fi

detect_ip() {
  for iface in en0 en1; do
    ip=$(ipconfig getifaddr "$iface" 2>/dev/null || true)
    if [[ -n "$ip" ]]; then
      echo "$ip"
      return
    fi
  done
  echo "127.0.0.1"
}

IP="$(detect_ip)"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Smart Medic — Web en red local"
echo "════════════════════════════════════════════════════════════"
echo "  En .env del proyecto raíz, define:"
echo "    DEV_HOST=$IP"
echo "    FLUTTER_WEB_PORT=$PORT"
echo ""
echo "  URL para otro dispositivo (misma Wi‑Fi):"
echo "    http://${IP}:${PORT}"
echo ""
echo "  También deben estar activos:"
echo "    backend (3000)  → cd backend && pnpm run dev"
echo "    gateway (3001)  → cd realtime-gateway && pnpm run dev"
echo "════════════════════════════════════════════════════════════"
echo "  Dev Tunnel: docs/DEV_TUNNELS.md (PUBLIC_* en .env)"
echo "  Comprobar:   ./scripts/check-dev-ports.sh"
echo "════════════════════════════════════════════════════════════"
echo ""
exec flutter run -d web-server --web-hostname 0.0.0.0 --web-port "$PORT"
