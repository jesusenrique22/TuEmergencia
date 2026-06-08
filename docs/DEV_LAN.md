# Probar la app web desde otro dispositivo (LAN)

Backend (**3000**), gateway (**3001**) y Flutter web (**8088** por defecto) deben estar activos.

## 1. IP del Mac

Ajustes → Red → Wi‑Fi → detalles → **Dirección IP** (ej. `192.168.1.42`).

## 2. `.env` en la raíz del proyecto

```env
API_BASE_URL=http://127.0.0.1:3000
SOCKET_URL=http://127.0.0.1:3001
DEV_HOST=192.168.1.42
FLUTTER_WEB_PORT=8088
```

`DEV_HOST` hace que la app web (en el móvil) llame a la API y al socket en tu Mac, no a `127.0.0.1`.

## 3. Servicios

```bash
# Terminal 1
cd backend && pnpm run dev

# Terminal 2
cd realtime-gateway && pnpm run dev

# Terminal 3 — script que imprime la URL para compartir
./scripts/run-web-lan.sh
```

O en Cursor: **Run and Debug** → **Flutter Web (LAN · puerto 8088)**.

## 4. Abrir en el otro dispositivo

Misma red Wi‑Fi:

```
http://192.168.1.42:8088
```

(Sustituye por tu `DEV_HOST` y `FLUTTER_WEB_PORT`.)

## 5. Puertos en Cursor (opcional)

En la pestaña **Puertos**, añade **8088**, **3000** y **3001** si quieres reenvío; en LAN suele bastar la IP directa.

## 6. Videollamadas

- Dos cuentas distintas (paciente + médico).
- Flujo: **Mensajes** → chat → llamada / videollamada.
- Micrófono en móvil: a veces hace falta **HTTPS**; en LAN con HTTP puede fallar en iOS Safari.

## Puertos (no confundir)

| URL | Servicio | Qué probar en el navegador |
|-----|----------|---------------------------|
| `http://127.0.0.1:3000` | **API REST** (backend) | `/health` o `/` → JSON "smart-medic-api" |
| `http://127.0.0.1:3001` | **Gateway WebSocket** | `/health` o `/` → JSON "realtime-gateway" |
| `http://127.0.0.1:8088` | **App Flutter web** | pantalla de login |

**3001 no es la API.** Si abres solo `:3001` esperando login, es el socket; la API está en **:3000**.

## Comprobación rápida

Desde el móvil:

- `http://DEV_HOST:3001/health` → JSON del gateway
- `http://DEV_HOST:8088` → app Flutter
