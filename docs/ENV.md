# Variables de entorno — matriz única

Tres capas deben estar **alineadas** o fallan login, chat o túneles.

## Puertos de desarrollo

| Puerto | Servicio | Script |
|--------|----------|--------|
| **3000** | API REST (`backend/`) | `cd backend && pnpm run dev` |
| **3001** | Gateway Socket.IO (`realtime-gateway/`) | idem |
| **8088** | Flutter web estática (túnel) | idem |

## Archivos `.env`

| Archivo | Quién lo lee | Obligatorio en dev |
|---------|--------------|-------------------|
| `.env` (raíz) | Flutter | `API_BASE_URL`, `SOCKET_URL`; túnel: `TUNNEL_PREFIX` |
| `config/local-paths.env` | Flutter/iOS/Android (opcional) | `FLUTTER_SDK`, `ANDROID_SDK` — ver `config/local-paths.env.example` |
| `backend/.env` | API | `JWT_SECRET`, `INTERNAL_REALTIME_SECRET`, `DATABASE_URL` |
| `realtime-gateway/.env` | Gateway | **Mismos** `JWT_SECRET` e `INTERNAL_REALTIME_SECRET` |

Valores por defecto de desarrollo (solo local): `config/secrets.defaults.cjs`.

## Reglas críticas

1. **`JWT_SECRET` idéntico** en `backend/.env` y `realtime-gateway/.env` → el socket valida el mismo token que emite el login REST.
2. **`INTERNAL_REALTIME_SECRET` idéntico** en ambos → el gateway llama a `/internal/realtime/*` del backend.
3. **Dev Tunnel:** solo túnel **Público** en puerto **8088**; `TUNNEL_PREFIX` en `.env`. API/socket van por proxy (mismo origen). No uses túneles públicos en 3000/3001.
4. **LAN:** `DEV_HOST=<IP Mac>` en `.env` raíz; no mezclar con `PUBLIC_*`.

## Rutas del proyecto (Smart_Medic vs GitHub/Smart-Medic)

Si el proyecto se movió de `Documents/GitHub/Smart-Medic` a `Documents/Smart_Medic`:

```bash
./scripts/ensure-local-paths.sh
```

Actualiza `ios/Flutter/Generated.xcconfig`, `macos/Flutter/ephemeral/…` y `android/local.properties`.  
Opcional: `config/local-paths.env` (copia desde `config/local-paths.env.example`).

`dart.flutterSdkPath` en `.vscode/settings.json` debe ser `/Users/smart/flutter` (no el Flutter dentro del repo viejo).

## Comprobar alineación

```bash
./scripts/verify-dev-env.sh
./scripts/check-dev-ports.sh
./scripts/ensure-local-paths.sh
```

Ver arquitectura: [COMMUNICATION.md](./COMMUNICATION.md).
