# TuEmergencia — Flutter app (iOS TestFlight / web) + backend en Render.

App multiplataforma. Backend y gateway en Render; PostgreSQL en Neon.

## Desarrollo local

| Servicio | Puerto | Comando |
|----------|--------|---------|
| API | 3000 | `cd backend && pnpm run dev` |
| Gateway | 3001 | `cd realtime-gateway && pnpm run dev` |
| Flutter web | **8088** | Con `cd backend && pnpm run dev` (túnel) · `flutter run` (LAN) |

**Cursor Puertos:** solo **8088** → **Público**. Backend y gateway en 3000/3001 locales.

Copia `.env.example` → `.env` en la raíz del proyecto.

## Web desde otro dispositivo (videollamadas, etc.)

1. Pon en `.env`: `DEV_HOST=<IP Wi‑Fi de tu Mac>` y `FLUTTER_WEB_PORT=8088`
2. Arranca: `cd backend && pnpm run dev` y `cd realtime-gateway && pnpm run dev` (la web :8088 sube sola)
3. En el móvil (misma Wi‑Fi): `http://<DEV_HOST>:8088`

Guías: [DEV_LAN](docs/DEV_LAN.md) · [Dev Tunnels](docs/DEV_TUNNELS.md) · [Comunicación](docs/COMMUNICATION.md) · [ENV](docs/ENV.md)

```bash
cd backend && pnpm run dev           # API + web :8088 + túnel (.env)
cd realtime-gateway && pnpm run dev  # Socket.IO
flutter run                          # simulador
./scripts/verify-dev-env.sh
./scripts/check-dev-ports.sh
```

Guía: [docs/DEV_TERMINALS.md](docs/DEV_TERMINALS.md) · Dev Tunnel: `TUNNEL_PREFIX` en `.env`

## Producción (Render + Neon)

| Servicio | Render | Docs |
|----------|--------|------|
| API | Web Service `backend/` | [DEPLOY_RENDER.md](docs/DEPLOY_RENDER.md) |
| Gateway | Web Service `realtime-gateway/` | idem |
| Flutter web | Static Site (rama `render-web`) | idem |
| PostgreSQL | Neon | `DATABASE_URL` en backend |

```bash
# Compilar front con URLs de Render
cp .env.production.example .env.production.local   # edita tus URLs
./scripts/build-web-production.sh

# O automático: GitHub Secrets RENDER_API_BASE_URL + RENDER_SOCKET_URL → push a main
```
