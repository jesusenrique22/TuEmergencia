# TestFlight — TuEmergencia (iOS)

## Requisitos

- Cuenta Apple Developer
- Xcode instalado
- Backend y gateway activos en Render:
  - `https://backend-pl89.onrender.com`
  - `https://gateway-i9yu.onrender.com`

## Causa típica de fallos (registro / login)

La build de release **solo** debe usar las URLs de `.env` (Render).

- **`.env.local`** es solo para desarrollo (LAN / Mac). En release **no** se carga.
- Si ves errores con `192.168.x.x` o `localhost`, la IPA se compiló con overrides de dev: vuelve a compilar release.

## 1. Variables de entorno

El archivo **`.env`** en la raíz del repo ya incluye las URLs de Render:

```env
API_BASE_URL=https://backend-pl89.onrender.com
SOCKET_URL=https://gateway-i9yu.onrender.com
ENABLE_DEV_TOOLS=false
```

Para dev local sin tocar `.env`, usa **`.env.local`** (ignorado por git).

## 2. Compilar

1. Sube el build number en `pubspec.yaml` (ej. `1.0.0+3`).
2. Ejecuta:

```bash
./scripts/build-ios-testflight.sh
```

Esto embebe el `.env` de producción. `.env.local` no afecta TestFlight.

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

1. Abre en Safari (despierta cold start de Render free tier):
   - `https://backend-pl89.onrender.com/health`
   - `https://gateway-i9yu.onrender.com/health`
2. Instala en dispositivo físico vía TestFlight
3. Registro / login + flujos clave
