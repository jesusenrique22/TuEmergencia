# Despliegue en Render (backend + gateway + frontend)

Stack en producción:

```
https://smart-medic-web.onrender.com      ← Flutter web (Static Site)
https://smart-medic-backend.onrender.com  ← API REST
https://smart-medic-gateway.onrender.com  ← Socket.IO
Neon PostgreSQL                           ← Base de datos (solo backend)
```

---

## 1. Backend (Render Web Service)

**Root directory:** `backend`

**Build command:**
```bash
corepack enable && pnpm install --frozen-lockfile && pnpm run build && pnpm exec prisma generate && pnpm exec prisma migrate deploy
```

**Start command:** `pnpm start`

**Variables de entorno:**

| Variable | Valor |
|----------|--------|
| `DATABASE_URL` | Connection string de Neon |
| `JWT_SECRET` | Secreto fuerte (generar uno nuevo) |
| `INTERNAL_REALTIME_SECRET` | Otro secreto (igual en gateway) |
| `REALTIME_GATEWAY_URL` | `https://TU-GATEWAY.onrender.com` |
| `NODE_ENV` | `production` |
| `APP_TIMEZONE` | `America/Caracas` |
| `APP_TZ_OFFSET_MINUTES` | `-240` |
| `GEMINI_API_KEY` | API key de [Google AI Studio](https://aistudio.google.com/apikey) |
| `GEMINI_MODEL` | `gemini-3.5-flash` |

**Health check:** `/health`

---

## 2. Gateway (Render Web Service)

**Root directory:** `realtime-gateway`

**Build command:**
```bash
corepack enable && pnpm install --frozen-lockfile && pnpm run build
```

**Start command:** `pnpm start`

**Variables de entorno:**

| Variable | Valor |
|----------|--------|
| `JWT_SECRET` | **Igual** que backend |
| `INTERNAL_REALTIME_SECRET` | **Igual** que backend |
| `BACKEND_URL` | `https://TU-BACKEND.onrender.com` |
| `NODE_ENV` | `production` |

**Health check:** `/health`

---

## 3. Frontend (Render Static Site)

Flutter web se compila **fuera** de Render (tu Mac o GitHub Actions).

### Opción A — GitHub Actions (recomendado)

1. En GitHub → repo → **Settings → Secrets → Actions**, crea:
   - `RENDER_API_BASE_URL` = `https://tu-backend.onrender.com`
   - `RENDER_SOCKET_URL` = `https://tu-gateway.onrender.com`

2. Push a `main` → el workflow `.github/workflows/deploy-web-render.yml` compila y sube la rama `render-web`.

3. En Render → **New Static Site**:
   - Repo conectado
   - **Branch:** `render-web`
   - **Publish directory:** `.` (raíz de la rama)
   - **Build command:** vacío o `echo ok`

4. Render aplicará rewrites SPA desde `render.yaml` o añade en el dashboard:
   - Source: `/*` → Destination: `/index.html` (Rewrite)

### Opción B — Build local

1. Edita `.env.production.example` con tus URLs de Render.

2. Compila:
   ```bash
   ./scripts/build-web-production.sh
   ```

3. Render → Static Site → **Manual Deploy** → arrastra `build/web`.

---

## 4. Blueprint completo (`render.yaml`)

Para un proyecto nuevo en Render:

```bash
# En Render Dashboard → New → Blueprint → conectar repo
```

El archivo `render.yaml` define los 3 servicios. Si ya tienes backend/gateway, crea solo el Static Site `smart-medic-web` apuntando a la rama `render-web`.

---

## 5. Neon — migraciones

Primera vez (desde tu Mac):

```bash
cd backend
DATABASE_URL="postgresql://..." pnpm exec prisma migrate deploy
DATABASE_URL="postgresql://..." pnpm run db:seed   # opcional: datos demo
```

En cada deploy, el build de Render ejecuta `prisma migrate deploy` automáticamente.

---

## 6. Comprobar que todo funciona

```bash
curl https://TU-BACKEND.onrender.com/health
curl https://TU-GATEWAY.onrender.com/health
# Abrir https://TU-FRONT.onrender.com → login
```

En la app: login, mensajes, ambulancia en tiempo real.

---

## 7. CORS

Los servicios aceptan orígenes `*.onrender.com` automáticamente. No hace falta `CORS_ORIGIN` si todo está en Render.

---

## 8. Plan free — cold start

Backend y gateway en free tier **se duermen** tras ~15 min. La primera petición tarda 30–60 s. Abre backend y gateway unos minutos antes de una demo.

El Static Site (frontend) **no se duerme**.

---

## Checklist rápido

- [ ] Neon: `DATABASE_URL` en backend
- [ ] `JWT_SECRET` igual en backend y gateway
- [ ] `INTERNAL_REALTIME_SECRET` igual en backend y gateway
- [ ] `REALTIME_GATEWAY_URL` en backend apunta al gateway público
- [ ] `BACKEND_URL` en gateway apunta al backend público
- [ ] GitHub Secrets `RENDER_API_BASE_URL` y `RENDER_SOCKET_URL`
- [ ] Static Site en rama `render-web`
- [ ] `/health` OK en backend y gateway
- [ ] Login funciona en el front

Ver también: [ENV.md](./ENV.md) · [COMMUNICATION.md](./COMMUNICATION.md)
