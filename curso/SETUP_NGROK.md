# 🌐 Setup ngrok - Guía Rápida

**Fecha de configuración:** 2025-11-08
**Propósito:** Exponer API local a internet para demos remotas sin despliegue permanente

---

## ✅ Lo que ya está configurado

### 1. ngrok instalado
- Descargado de: https://ngrok.com/download
- Ubicación: Donde lo descargaste
- Versión: ngrok free tier

### 2. Flutter configurado para ngrok

**Archivo:** `lib/config/api_config.dart`

```dart
// URL de producción apunta a ngrok
static const String _baseUrlProduction = 'https://mathilda-conventually-esta.ngrok-free.dev';

// Modo producción activado
static const bool isDevelopment = false;

// Header especial para evitar página de advertencia de ngrok free
static Map<String, String> get defaultHeaders => {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'ngrok-skip-browser-warning': 'true', // ← CRÍTICO para ngrok free
};
```

### 3. Ruta web-only deshabilitada en mobile

**Archivo:** `lib/routes.dart`

- Removido import de `AcceptInvitationWebWrapper` (usa `dart:html`, solo funciona en web)
- Ruta `/accept-invite` deshabilitada para mobile

---

## 🚀 Cómo usar ngrok para demo

### Paso 1: Iniciar API en LAPTOP

```bash
cd vigilancia-api
venv\Scripts\activate
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

**IMPORTANTE:** `--host 0.0.0.0` permite que ngrok acceda al servidor.

### Paso 2: Iniciar ngrok en LAPTOP (otra terminal)

```bash
ngrok http 8000
```

Verás algo como:
```
Forwarding   https://mathilda-conventually-esta.ngrok-free.dev -> http://localhost:8000
```

**Copia esa URL HTTPS.**

### Paso 3: Actualizar Flutter (si la URL cambió)

Si la URL de ngrok es diferente a la que tenías:

1. Abre `lib/config/api_config.dart`
2. Actualiza `_baseUrlProduction` con la nueva URL
3. Guarda el archivo

### Paso 4: Correr Flutter

**Opción A: Desarrollo con cable USB**
```bash
flutter run
```

**Opción B: Compilar APK para instalación**
```bash
flutter build apk --release
```
El APK estará en: `build/app/outputs/flutter-apk/app-release.apk`

### Paso 5: Demo

- **LAPTOP:** Mantén API y ngrok corriendo
- **CELULAR:** Abre la app
- **DEMO:** Funciona desde cualquier red con internet

---

## ⚠️ Limitaciones de ngrok free

1. **URL temporal:** La URL puede cambiar cada vez que reinicias ngrok
2. **Página de advertencia:** Se soluciona con el header `ngrok-skip-browser-warning`
3. **Límite de conexiones:** Plan gratuito tiene límites
4. **Requiere laptop encendida:** La laptop debe estar con ngrok activo

---

## 🔄 Si la URL de ngrok cambia

**Síntomas:**
- App no se conecta a la API
- Errores de timeout o conexión

**Solución:**

1. Verifica la URL actual en la terminal de ngrok
2. Actualiza `lib/config/api_config.dart`:
   ```dart
   static const String _baseUrlProduction = 'https://NUEVA-URL-DE-NGROK.ngrok-free.dev';
   ```
3. Recompila o haz hot reload:
   ```bash
   flutter run
   # o
   flutter build apk --release
   ```

---

## 🛠️ Troubleshooting

### Error: "Unexpected token '<', "<!DOCTYPE "... is not valid JSON"

**Causa:** No está el header `ngrok-skip-browser-warning`

**Solución:** ✅ Ya está agregado en `api_config.dart`

### Error: "Connection refused"

**Causa:** API no está corriendo o ngrok apagado

**Solución:**
1. Verifica que API esté corriendo: `http://localhost:8000/docs`
2. Verifica que ngrok esté corriendo y apuntando al puerto 8000

### Error: "dart:html not found" en mobile

**Causa:** Archivo web-only importado en mobile

**Solución:** ✅ Ya está corregido - `AcceptInvitationWebWrapper` deshabilitado en routes

---

## 📱 Dispositivos probados

- ✅ Samsung Galaxy Note 10+ (SM-N975F) - Android
- ✅ Flutter run vía USB
- ⏳ APK release (pendiente de compilar)

---

## 🎯 Para despliegue permanente (futuro)

Si quieres eliminar la dependencia de ngrok, opciones:

### Opción 1: Railway (Recomendado)
- Gratis con cuenta GitHub
- Despliegue automático
- URL permanente
- Tutorial: https://docs.railway.app/deploy/deployments

### Opción 2: Render
- Plan gratuito disponible
- Despliegue desde GitHub
- URL permanente
- Tutorial: https://render.com/docs/deploy-fastapi

### Opción 3: DigitalOcean / AWS
- Más control
- Requiere configuración manual
- Costo mensual

---

**Última actualización:** 2025-11-08
**Estado:** ✅ Funcionando correctamente
**URL actual:** https://mathilda-conventually-esta.ngrok-free.dev
**Probado en:** Samsung Galaxy Note 10+ (SM-N975F)
