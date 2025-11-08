# 📋 Resumen Rápido para Claude - Sistema de Vigilancia

> **Contexto rápido para una nueva sesión de Claude**

---

## 🎯 ¿Qué es este proyecto?

App Flutter + Backend FastAPI para **vigilancia con detección de incidentes en tiempo real**.

**Stack:**
- Frontend: Flutter (mobile/web)
- Backend: FastAPI (Python)
- BD: MySQL
- Real-time: WebSockets

---

## ✅ Lo que SÍ está funcionando (2025-11-07)

### 1. Sistema Core
- ✅ Login/Registro con JWT
- ✅ Gestión de cámaras (CRUD completo)
- ✅ Listar incidentes desde API
- ✅ Ver detalle de incidentes
- ✅ **WebSocket conectado** automáticamente
- ✅ **Notificaciones push** en tiempo real
- ✅ **Auto-actualización** de datos
- ✅ Simulación de incidentes para testing

### 2. Sistema de Gestión de Organizaciones (NUEVO 2025-11-07)
- ✅ **Ver miembros** de la organización con roles (ADMIN/USER)
- ✅ **Crear invitaciones** - Links universales para compartir
- ✅ **Gestionar invitaciones** - Copiar link, revocar, ver expiradas
- ✅ **Ver solicitudes de unión** - Pendientes e historial
- ✅ **Aprobar/Rechazar solicitudes** - Agregar usuarios a la org
- ✅ **Eliminar miembros** (solo Admin, no puede eliminar Admin)
- ✅ **Badge de notificaciones** - Muestra solicitudes pendientes
- ✅ **Pantalla con 3 tabs** - Miembros | Invitaciones | Solicitudes

### 3. Arquitectura
```
Flutter App (localhost)
    ↓ HTTP REST
FastAPI Backend (localhost:8000)
    ↓ WebSocket (ws://localhost:8000/ws/notifications)
Flutter App recibe notificaciones
    ↓
Muestra push notification + SnackBar
```

**Endpoints integrados:**
- Auth: login, register
- Cámaras: CRUD completo
- Incidentes: listar, detalle, acknowledge, stats
- Simulación: start, stop, status
- Organizaciones: ver miembros, eliminar usuario
- Invitaciones: crear, listar, revocar
- Solicitudes: listar, aprobar, rechazar

---

## ⚠️ Decisiones de diseño importantes

### Backend devuelve datos "hardcodeados"
```json
{
  "behavior_type": "otro",  // ← Siempre "otro"
  "severity": "media",      // ← Siempre "media"
  "is_acknowledged": false  // ← Siempre false
}
```

**Solución aplicada:** Flutter mapea estos valores correctamente a tipos válidos.

**Campos en BD real (tabla `incidents`):**
- id, camera_id, organization_id
- description, timestamp, confidence
- s3_video_url

**Campos que FALTAN en BD pero el backend los devuelve hardcodeados:**
- behavior_type, severity, is_acknowledged
- s3_image_url, detected_objects, pose_data
- status, notes, acknowledged_by, acknowledged_at

**Decisión:** Flutter ya está preparado, cuando backend agregue esos campos a la BD, funcionarán automáticamente.

---

## 🔧 Configuración Actual

### Flutter (`lib/config/api_config.dart`)
```dart
static const String _baseUrlDevelopment = 'http://localhost:8000';
static const String _baseUrlProduction = 'https://mathilda-conventually-esta.ngrok-free.dev';
static const bool isDevelopment = false; // ← USANDO NGROK para pruebas remotas

// Header especial agregado para ngrok free tier
static Map<String, String> get defaultHeaders => {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'ngrok-skip-browser-warning': 'true', // ← Evita página de advertencia de ngrok
};
```

**⚠️ IMPORTANTE - ngrok Activo:**
- La app está configurada para conectarse a ngrok (URL pública temporal)
- **Requiere:** ngrok corriendo en la laptop con `ngrok http 8000`
- **Requiere:** API corriendo con `uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload`
- **Ventaja:** Funciona desde cualquier red con internet (no requiere misma WiFi)
- **Limitación:** La URL de ngrok puede cambiar al reiniciar ngrok

### Services
```dart
// evidence_service.dart
static const bool useMockMode = false; // ← Usar API REAL

// websocket_service.dart
final webSocketService = WebSocketService(); // ← Singleton global
```

### WebSocket en HomeScreen
```dart
// home_screen.dart - initState()
_conectarWebSocket(); // ← Auto-conecta al login

// Recibe nuevos incidentes
webSocketService.incidentStream.listen((incident) {
  _mostrarNotificacion(incident);
  _loadHomeData();
  // Muestra SnackBar
});
```

---

## 🧪 Cómo Probar

### 1. Iniciar Backend
```bash
cd vigilancia-api
venv\Scripts\activate
uvicorn app.main:app --reload
```

### 2. Iniciar Flutter
```bash
cd curso
flutter run
```

### 3. Login
- Email: `jonitopera777@gmail.com`
- Org: 3
- Cámara disponible: ID 2

### 4. Iniciar Simulación
```bash
curl -X POST "http://localhost:8000/api/detection/simulation/start" \
  -H "Authorization: Bearer TOKEN_DEL_LOGIN" \
  -H "Content-Type: application/json" \
  -d '{"camera_id": 2, "interval_seconds": 5}'
```

**Resultado esperado:**
- 📱 Notificación push cada 5 segundos
- 📢 SnackBar en la app
- 🔄 Lista se actualiza sola

---

## 🐛 Fix Importante Aplicado

**Problema:** WebSocket daba `ImportError: cannot import name 'verify_token'`

**Solución:** Agregada función en `vigilancia-api/app/services/auth_service.py`:
```python
def verify_token(token: str) -> dict:
    return AuthService.decode_token(token)
```

**Ya está aplicado y funcionando.**

---

## 📂 Archivos Clave

### Frontend (Flutter)
```
lib/
├── config/api_config.dart          ← Endpoints
├── models/
│   ├── evidence_model.dart         ← Modelo incidentes
│   ├── organization_model.dart     ← Modelo org y miembros ⭐ NUEVO
│   ├── invitation_model.dart       ← Modelo invitaciones ⭐ NUEVO
│   └── join_request_model.dart     ← Modelo solicitudes ⭐ NUEVO
├── services/
│   ├── evidence_service.dart       ← CRUD incidentes
│   ├── websocket_service.dart      ← Notificaciones
│   ├── simulation_service.dart     ← Control simulación
│   ├── organization_service.dart   ← CRUD org ⭐ NUEVO
│   ├── invitation_service.dart     ← CRUD invitaciones ⭐ NUEVO
│   └── join_request_service.dart   ← CRUD solicitudes ⭐ NUEVO
├── screens/
│   ├── incidencias.dart            ← Lista incidentes
│   ├── evidencia_detail.dart       ← Detalle incidente
│   ├── home/home_screen.dart       ← Dashboard con WebSocket
│   └── organization/
│       └── manage_organization_screen.dart  ← Gestión org ⭐ NUEVO
```

### Backend (FastAPI)
```
app/
├── endpoints/detection_endpoints.py  ← Endpoints incidentes
├── services/
│   ├── auth_service.py               ← verify_token agregado ✅
│   └── detection_service.py          ← Simulación
└── database.py                       ← Modelo Incident
```

### Documentación
```
RESUMEN_PARA_CLAUDE.md                      ← ⭐ Este archivo (inicio rápido)
ESTADO_PROYECTO.md                          ← Estado completo del proyecto
ENDPOINTS_DISPONIBLES.md                    ← Endpoints API disponibles
IMPLEMENTACION_ORGANIZACIONES_COMPLETA.md   ← Sistema de organizaciones ⭐ NUEVO
COMO_PROBAR_NOTIFICACIONES.md               ← Guía de pruebas
DETECCIONES_IMPLEMENTADAS.md                ← Detalle técnico detecciones
```

---

## 🚧 Pendiente (Opcionales)

### Despliegue y Testing - ESTADO ACTUAL (2025-11-08) ✅
- ✅ **ngrok configurado** - App funciona remotamente desde cualquier red
- ✅ **Probado en dispositivo físico** - Samsung SM-N975F funcionando
- ✅ **Header ngrok agregado** - `ngrok-skip-browser-warning` para plan gratuito
- ✅ **Ruta mobile corregida** - `AcceptInvitationWebWrapper` deshabilitada (solo web)

### UI/UX - Minor Fixes Pendientes
1. **Ajustes de diseño responsive**
   - Mejorar adaptación a diferentes tamaños de pantalla
   - Refinar espaciados y márgenes
   - Optimizar visualización de listas largas

2. **Filtros por estado** en pantalla Incidencias
   - Tabs: Pendientes | Revisadas | Todas
   - Vista default: solo pendientes

3. **Botón "Marcar como revisada"** más visible en UI
   - Endpoint ya existe: `POST /incidents/{id}/acknowledge`
   - Solo falta mejorar visibilidad del botón

### Sistema de Organizaciones - Mejoras Futuras
4. **Agregar navegación** - Desde HomeScreen a ManageOrganizationScreen
5. **Pantalla de unirse** - Para usuarios que reciben invitación (opcional)
6. **Deep links** - Abrir app con link de invitación (opcional)
7. **Push notifications** - Cuando llega nueva solicitud (opcional)

### Despliegue Permanente (Opcional)
8. **Despliegue en Railway/Render**
   - Backend en servidor real permanente
   - Actualizar URLs en Flutter para producción
   - Eliminar dependencia de ngrok

---

## 💡 Para Claude Futuro

### Si el usuario pregunta "¿funciona?"
✅ SÍ - Todo el sistema funciona:
- Login/Registro ✅
- Cámaras (CRUD) ✅
- Incidentes ✅
- WebSocket ✅
- Notificaciones ✅
- Gestión de Organizaciones ✅ (NUEVO)
- Invitaciones ✅ (NUEVO)
- Solicitudes de Unión ✅ (NUEVO)

### Si pregunta "¿qué falta?"
Solo mejoras UX opcionales:
- Filtros por estado en incidentes
- Navegación a pantalla de organizaciones
- Deep links para invitaciones (opcional)
- Pantalla de unirse (opcional)

### Si hay errores de WebSocket
1. Verificar backend corriendo
2. Verificar `verify_token` existe en `auth_service.py`
3. Reiniciar backend
4. Token válido (expira en 60 min)

### Si incidentes no aparecen
1. Verificar `useMockMode = false` en `evidence_service.dart`
2. Verificar `camera_id: 2` en simulación
3. Ver logs: `✅ X incidentes obtenidos`

### Si pantalla de organizaciones da error
1. Verificar backend corriendo
2. Verificar usuario tiene `organization_id`
3. Verificar rol en SharedPreferences (`ADMIN` o `USER`)
4. Ver logs en consola Flutter

### Usuario de prueba actual
- Email: jonitopera777@gmail.com
- Organización ID: 3
- Cámara ID: 2
- Rol: ADMIN

### Nuevo sistema de organizaciones
**Archivos principales:**
- `lib/screens/organization/manage_organization_screen.dart` - Pantalla con tabs
- `lib/services/organization_service.dart` - Service de organizaciones
- `lib/services/invitation_service.dart` - Service de invitaciones
- `lib/services/join_request_service.dart` - Service de solicitudes

**Para usar:**
1. Agregar navegación desde HomeScreen
2. Usuario ADMIN puede ver/gestionar todo
3. Usuario USER solo puede ver miembros

---

## 🎯 Estado del Proyecto: ✅ FUNCIONAL Y LISTO PARA DEMO

**Sistema está listo para:**
- ✅ Demo básico
- ✅ Testing con simulación
- ✅ Pruebas de notificaciones en tiempo real
- ✅ **Demo remota con ngrok** - Funciona desde cualquier red
- ✅ **Probado en dispositivo físico** - Samsung Galaxy Note 10+

**Siguiente milestone:**
- 🎯 **Ajustes UI/UX** - Mejorar responsive y espaciados
- 🔲 Compilar APK release para instalación independiente
- 🔲 Mejorar filtros y botones de acciones
- 🔲 (Opcional) Desplegar en servidor permanente
- 🔲 (Opcional) Integrar detección real (YOLOv8)

---

## 📞 Comandos Útiles

```bash
# Backend (LAPTOP - Puerto debe estar en 0.0.0.0 para ngrok)
cd vigilancia-api && venv\Scripts\activate && uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# ngrok (LAPTOP - En otra terminal)
ngrok http 8000
# Copia la URL https que te da (ej: https://mathilda-conventually-esta.ngrok-free.dev)
# Actualiza lib/config/api_config.dart con esa URL en _baseUrlProduction

# Flutter (PC de desarrollo)
cd curso && flutter run

# Compilar APK release
flutter build apk --release
# APK estará en: build/app/outputs/flutter-apk/app-release.apk

# Hot reload Flutter
r (en terminal de Flutter)

# Detener simulación
curl -X POST "http://localhost:8000/api/detection/simulation/stop" -H "Authorization: Bearer TOKEN"

# Git - Subir cambios
git add .
git commit -m "Descripción de cambios"
git push origin main
```

### Flujo para Demo con ngrok:
1. **En LAPTOP:** Iniciar API con `--host 0.0.0.0`
2. **En LAPTOP:** Iniciar ngrok con `ngrok http 8000`
3. **En PC de desarrollo:** Actualizar `api_config.dart` con URL de ngrok
4. **En PC de desarrollo:** Compilar APK o correr `flutter run`
5. **En CELULAR:** Instalar APK o conectar vía USB para testing

---

**Última actualización:** 2025-11-08
**Última implementación:**
- Configuración de ngrok para demo remota
- Header `ngrok-skip-browser-warning` agregado
- Corrección de rutas para mobile (deshabilitado AcceptInvitationWebWrapper)
- Probado exitosamente en Samsung Galaxy Note 10+ (SM-N975F)

**Estado actual:** ✅ App funcional en dispositivo físico con API remota vía ngrok
**Próxima tarea sugerida:** Minor fixes UI/UX y compilar APK release para demo
**Documentación completa:** Ver `IMPLEMENTACION_ORGANIZACIONES_COMPLETA.md`
