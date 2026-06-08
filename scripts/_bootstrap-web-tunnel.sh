#!/usr/bin/env bash
# Interno: lo ejecuta «pnpm run dev» del backend (web + proxy :8088, NO gateway).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT_WEB="${FLUTTER_WEB_PORT:-8088}"

if [[ -f "$ROOT/.env" ]]; then
  val=$(grep -E '^FLUTTER_WEB_PORT=' "$ROOT/.env" 2>/dev/null | cut -d= -f2- | tr -d '\r"' || true)
  [[ -n "$val" ]] && PORT_WEB="$val"
fi

web_ok() {
  curl -sf --connect-timeout 2 "http://127.0.0.1:${PORT_WEB}/" >/dev/null 2>&1
}

build_ok() {
  [[ -f "$ROOT/build/web/index.html" ]]
}

"$ROOT/scripts/_bootstrap-dev-env.sh"

if web_ok; then
  echo "→ Web ya activa en http://127.0.0.1:${PORT_WEB} (Dev Tunnel :${PORT_WEB} Público en Cursor)"
elif ! build_ok; then
  echo "→ Compilando Flutter web (primera vez puede tardar un poco)…"
  "$ROOT/scripts/serve-web-tunnel.sh" --build >/dev/null 2>&1 || true
fi

if web_ok; then
  :
else
  echo "→ Arrancando web + proxy API/gateway en :${PORT_WEB}…"
  nohup "$ROOT/scripts/serve-web-tunnel.sh" --serve-only >>"$ROOT/.dev-web.log" 2>&1 &
  for _ in $(seq 1 30); do
    sleep 0.4
    web_ok && break
  done
  if web_ok; then
    echo "→ Web lista en http://127.0.0.1:${PORT_WEB}"
  else
    echo "⚠ Web no respondió aún; revisa $ROOT/.dev-web.log"
  fi
fi

if ! curl -sf --connect-timeout 2 "http://127.0.0.1:3000/health" >/dev/null 2>&1; then
  echo "→ API :3000 arrancará en unos segundos (espera «Smart Medic API en puerto 3000»)"
fi
