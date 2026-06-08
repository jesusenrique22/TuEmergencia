# Desarrollo local (2 terminales)

## Arranque

**Terminal 1 — backend** (API + web Dev Tunnel en :8088 automático):

```bash
cd backend && pnpm run dev
```

**Terminal 2 — gateway:**

```bash
cd realtime-gateway && pnpm run dev
```

**Simulador / iOS** (otra terminal, como siempre):

```bash
flutter run
```

No hace falta ningún script extra: al iniciar el backend se sincroniza el túnel (si `TUNNEL_PREFIX` está en `.env`) y se levanta la web con proxy hacia API y gateway.

## Dev Tunnel (Cursor → Puertos)

1. Pon en `.env` (una sola vez, cuando Cursor te da la URL pública del **8088**):

```env
TUNNEL_PREFIX=bbsl5rv7
```

2. `cd backend && pnpm run dev` — arranca `:8088` y sincroniza `TUNNEL_PREFIX`.
3. Cursor → **Puertos** → **8088** → **Público** (3000/3001 solo local, no públicos).
4. Abre `https://TU-PREFIJO-8088.use2.devtunnels.ms`

Si Cursor cambia el prefijo, edita `TUNNEL_PREFIX` en `.env` y reinicia el backend.

Comprobar:

```bash
./scripts/check-dev-ports.sh
```

Tras cambiar Dart en web (build estático del túnel):

```bash
./scripts/serve-web-tunnel.sh --build
```

Luego reinicia el backend o `./scripts/stop-dev-ports.sh` y vuelve a `pnpm run dev`.

## Web con hot reload (sin túnel)

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8088
```

(o `./scripts/run-web-lan.sh` en LAN). Requiere backend + gateway en 3000/3001.

## Detener todo

```bash
./scripts/stop-dev-ports.sh
```

## Opcional: una sola terminal

```bash
./scripts/dev-services.sh
```

Ver también: [DEV_TUNNELS.md](./DEV_TUNNELS.md) · [DEV_LAN.md](./DEV_LAN.md)
