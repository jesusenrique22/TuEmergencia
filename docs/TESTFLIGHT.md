# TestFlight — TuEmergencia (iOS)

## Requisitos

- Cuenta Apple Developer
- Xcode instalado
- Backend y gateway activos en Render:
  - `https://backend-pl89.onrender.com`
  - `https://gateway-i9yu.onrender.com`

## 1. Variables de entorno

El archivo **`.env`** en la raíz del repo ya incluye las URLs de Render (está en git):

```env
API_BASE_URL=https://backend-pl89.onrender.com
SOCKET_URL=https://gateway-i9yu.onrender.com
ENABLE_DEV_TOOLS=false
```

Para dev local sin tocar `.env`, crea **`.env.local`** (ignorado por git) — ver `.env.example`.

## 2. Compilar

```bash
./scripts/build-ios-testflight.sh
```

Esto embebe el `.env` en la app (asset bundle).

## 3. App Store Connect

1. Crear app **TuEmergencia**
2. **Bundle ID:** `com.tuemergencia.app` (debe coincidir con Xcode)
3. No uses `com.example.*` — Apple lo rechaza

## 4. Xcode → Archive → TestFlight

```bash
open ios/Runner.xcworkspace
```

1. Signing & Capabilities → tu Team
2. Product → Archive
3. Distribute App → App Store Connect → TestFlight

## 5. Probar antes de enviar

1. Abre en Safari (despierta cold start):
   - `https://backend-pl89.onrender.com/health`
   - `https://gateway-i9yu.onrender.com/health`
2. Instala en dispositivo físico
3. Login + ambulancia / chat

## Renombrar repo en GitHub

```bash
gh repo rename TuEmergencia
git remote set-url origin https://github.com/jesusenrique22/TuEmergencia.git
```
