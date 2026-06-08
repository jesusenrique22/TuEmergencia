# Arquitectura de comunicación

## Vista general

```
Flutter (web / iOS / Android)
    │
    ├─ REST ──────────────► Backend API :3000  (/api/*, JWT Bearer)
    │
    └─ Socket.IO ─────────► Realtime Gateway :3001
                                │
                                └─ HTTP interno ─► Backend /internal/realtime/*
    
Backend ──push──► Gateway POST /internal/emit ──► salas Socket.IO
```

| Canal | Cliente Flutter | Servidor | Auth |
|-------|-----------------|----------|------|
| REST | `ApiClient` (singleton) | `backend` | `Authorization: Bearer` |
| Tiempo real | `ChatSocketService` → `AppRealtime` | `realtime-gateway` | `handshake.auth.token` (mismo JWT) |
| Interno | — | gateway → backend | `X-Internal-Key` |

## Capa Flutter (escalable)

| Módulo | Rol |
|--------|-----|
| `lib/core/config/api_config.dart` | Resuelve URLs (LAN, túnel, emulador) |
| `lib/core/config/service_ports.dart` | Puertos por defecto (3000, 3001, 8088) |
| `lib/core/network/api_client.dart` | **Un** cliente HTTP para todos los `*_api_service` |
| `lib/core/network/api_url.dart` | URLs de medios y rutas relativas |
| `lib/core/connectivity/service_connectivity.dart` | Health API + gateway (caché 3s) |
| `lib/core/di/service_locator.dart` | `get_it` — registro central (tests/mocks) |

Los 15+ `*_api_service.dart` usan `ApiClient()` → misma instancia.

## Backend ↔ Gateway

- Lógica de negocio y BD: **solo** en `backend/`.
- El gateway **no** sustituye la API; reenvía eventos de socket al backend.
- Secretos compartidos: ver [ENV.md](./ENV.md) y `config/secrets.defaults.cjs`.

## Escalar más adelante

| Hoy (dev) | Siguiente paso producción |
|-----------|---------------------------|
| Un proceso gateway | Redis adapter Socket.IO + sticky sessions |
| `POST /internal/emit` por evento | Cola / batch de emits |
| JWT 7 días | Refresh token o sesiones cortas |
| CORS `origin: true` | Allowlist en `CORS_ORIGIN` |
| Subidas base64 en JSON | Multipart o URLs firmadas (S3) |

## Arranque local

```bash
cd backend && pnpm run dev     # 3000 + 8088 · gateway aparte
./scripts/verify-dev-env.sh    # JWT/secretos alineados
```

Túnel: [DEV_TUNNELS.md](./DEV_TUNNELS.md) · LAN: [DEV_LAN.md](./DEV_LAN.md).
