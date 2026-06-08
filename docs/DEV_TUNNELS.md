# Dev Tunnels (Cursor / VS Code) — compartir URL HTTPS

El **502/504** casi siempre significa: el túnel existe pero **no hay nada escuchando** en ese puerto en tu Mac, o la VPN bloquea el reenvío.

```bash
./scripts/check-dev-ports.sh
./scripts/tunnel-sync-env.sh --check
```

## Arquitectura (un solo túnel público)

```
https://PREFIJO-8088.devtunnels.ms   ← única URL que compartes
        │
        ├── /              Flutter web
        ├── /api/*         → proxy → Backend :3000
        ├── /health        → proxy → Backend :3000
        ├── /gateway-health→ proxy → Gateway :3001
        └── /socket.io/*   → proxy → Gateway :3001

:3000  API        (solo local)
:3001  Gateway    (solo local)
:8088  Web+proxy  (túnel PÚBLICO en Cursor)
```

Ventajas: un HTTPS, sin CORS entre subdominios, sin 401 de Microsoft en `-3000`/`-3001`, mismo patrón que escalar en producción (edge + servicios detrás).

---

## 1. Arrancar servicios (2 terminales)

```bash
# Terminal 1 — API + web :8088
cd backend && pnpm run dev

# Terminal 2 — Gateway :3001
cd realtime-gateway && pnpm run dev
```

Espera: `Smart Medic API en puerto 3000` y `→ Web lista en http://127.0.0.1:8088`.

Atajo: `./scripts/dev-services.sh` (ambos en paralelo).

En Cursor: **Run Task…** → `smart-medic: dev stack`.

**No uses** `flutter run -d chrome` para probar el túnel (usa localhost directo). Para túnel: build estático en :8088.

Tras cambiar Dart: `./scripts/serve-web-tunnel.sh --build`

---

## 2. Puertos en Cursor (importante)

| Puerto | ¿Túnel? | Visibilidad |
|--------|---------|-------------|
| **8088** | ✅ Sí | **Público** — abre/comparte esta URL |
| **3000** | No (opcional) | **Privado** o elimínalo del panel |
| **3001** | No (opcional) | **Privado** o elimínalo del panel |

Pasos:

1. Elimina túneles **públicos** de 3000 y 3001 si los tienes (icono X).
2. Deja solo **8088** → clic derecho → **Port Visibility** → **Public**.
3. La columna **Running Process** en 8088 debe mostrar **python** (no vacía).

URL de la app:

```text
https://TU-PREFIJO-8088.use2.devtunnels.ms
```

El proyecto ya configura esto en `.vscode/settings.json` (`8088` public, `3000`/`3001` private).

---

## 3. `.env` en la raíz

Solo necesitas el prefijo del túnel (copiado de la URL del 8088):

```env
TUNNEL_PREFIX=bbsl5rv7
FLUTTER_WEB_PORT=8088
API_BASE_URL=http://127.0.0.1:3000
SOCKET_URL=http://127.0.0.1:3001
```

**No** uses `PUBLIC_API_URL` / `PUBLIC_SOCKET_URL` con túneles `-3000`/`-3001`. La app detecta `devtunnels.ms` y usa el **mismo origen** `:8088` (proxy).

Sincronizar prefijo:

```bash
./scripts/tunnel-sync-env.sh https://TU-PREFIJO-8088.use2.devtunnels.ms
# o
./scripts/tunnel-sync-env.sh TU-PREFIJO
```

---

## 4. Probar antes del túnel

En tu Mac (sin internet extra):

```text
http://127.0.0.1:8088
```

Si eso no carga, el túnel dará 502/504.

Recarga forzada en el navegador del túnel: `Cmd+Shift+R`.

---

## 5. Panel debug

- Icono **🐛** en **Mensajes**
- O: `https://TU-PREFIJO-8088…/#/debug/gateway`

---

## 504 / pantalla en blanco

- **VPN** (Surfshark, etc.): desactívala al probar túneles.
- **504 en main.dart.js**: el proxy ya envía gzip. Comprueba `./scripts/tunnel-health.sh`.
- **Proceso vacío** en Puertos → reinicia `cd backend && pnpm run dev`.

Rehacer túnel 8088:

1. `./scripts/stop-dev-ports.sh`
2. `cd backend && pnpm run dev` + `cd realtime-gateway && pnpm run dev`
3. Cursor → elimina puerto 8088 → vuelve a aparecer → **Público**
4. Abre la **nueva** URL

---

## Checklist

- [ ] `./scripts/check-dev-ports.sh` → 3000, 3001, 8088 ✓
- [ ] Solo **8088** en **Público** (no 3000/3001 públicos)
- [ ] `TUNNEL_PREFIX` en `.env`
- [ ] `http://127.0.0.1:8088` carga en el Mac
- [ ] VPN desactivada (opcional pero recomendado)

---

## LAN vs Dev Tunnel

| Modo | URL |
|------|-----|
| **Misma Wi‑Fi** | `http://192.168.x.x:8088` (`DEV_HOST` en `.env`) |
| **Dev Tunnel** | `https://PREFIJO-8088.use2.devtunnels.ms` |

Ver [DEV_LAN.md](./DEV_LAN.md) · [DEV_TERMINALS.md](./DEV_TERMINALS.md) · [COMMUNICATION.md](./COMMUNICATION.md)

## Videollamadas

Dev Tunnels dan **HTTPS** → mejor para mic/cámara en móvil.  
Usa **Mensajes** → chat → llamada, con **dos cuentas distintas**.
