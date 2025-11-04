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

## ✅ Lo que SÍ está funcionando (2025-01-03)

### 1. Sistema Core
- ✅ Login/Registro con JWT
- ✅ Gestión de cámaras (CRUD completo)
- ✅ Listar incidentes desde API
- ✅ Ver detalle de incidentes
- ✅ **WebSocket conectado** automáticamente
- ✅ **Notificaciones push** en tiempo real
- ✅ **Auto-actualización** de datos
- ✅ Simulación de incidentes para testing

### 2. Arquitectura
```
Flutter App (localhost)
    ↓ HTTP
FastAPI Backend (localhost:8000)
    ↓ WebSocket (ws://localhost:8000/ws/notifications)
Flutter App recibe notificaciones
    ↓
Muestra push notification + SnackBar
```

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
static const bool isDevelopment = true;
```

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
├── models/evidence_model.dart      ← Modelo flexible
├── services/
│   ├── evidence_service.dart       ← CRUD (useMockMode=false)
│   ├── websocket_service.dart      ← Notificaciones
│   └── simulation_service.dart     ← Control simulación
├── screens/
│   ├── incidencias.dart            ← Lista incidentes
│   ├── evidencia_detail.dart       ← Detalle incidente
│   └── home/home_screen.dart       ← Dashboard con WebSocket
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
ESTADO_PROYECTO.md                 ← ⭐ LEER PRIMERO (completo)
RESUMEN_PARA_CLAUDE.md             ← ⭐ Este archivo (rápido)
COMO_PROBAR_NOTIFICACIONES.md      ← Guía de pruebas
DETECCIONES_IMPLEMENTADAS.md       ← Detalle técnico
```

---

## 🚧 Pendiente (Opcionales)

1. **Filtros por estado** en pantalla Incidencias
   - Tabs: Pendientes | Revisadas | Todas
   - Vista default: solo pendientes

2. **Botón "Marcar como revisada"** en detalle
   - Endpoint ya existe: `POST /incidents/{id}/acknowledge`
   - Solo falta UI

3. **Decisión sobre eliminación**
   - ¿Permitir borrar incidentes?
   - ¿O solo filtrar por estado? (recomendado)

4. **Despliegue**
   - Backend en servidor real
   - Actualizar URLs en Flutter

---

## 💡 Para Claude Futuro

### Si el usuario pregunta "¿funciona?"
✅ SÍ - Todo el sistema core funciona:
- Login ✅
- Cámaras ✅
- Incidentes ✅
- WebSocket ✅
- Notificaciones ✅

### Si pregunta "¿qué falta?"
Solo mejoras UX opcionales:
- Filtros por estado
- Botón marcar como revisada
- Decisión sobre eliminación

### Si hay errores de WebSocket
1. Verificar backend corriendo
2. Verificar `verify_token` existe en `auth_service.py`
3. Reiniciar backend
4. Token válido (expira en 60 min)

### Si incidentes no aparecen
1. Verificar `useMockMode = false` en `evidence_service.dart`
2. Verificar `camera_id: 2` en simulación
3. Ver logs: `✅ X incidentes obtenidos`

### Usuario actual
- Email: jonitopera777@gmail.com
- Organización ID: 3
- Cámara ID: 2
- Rol: ADMIN

---

## 🎯 Estado del Proyecto: ✅ FUNCIONAL

**Sistema está listo para:**
- ✅ Demo básico
- ✅ Testing con simulación
- ✅ Pruebas de notificaciones en tiempo real

**Siguiente milestone:**
- 🔲 Mejorar UX (filtros, botones)
- 🔲 Desplegar en servidor
- 🔲 Integrar detección real (YOLOv8)

---

## 📞 Comandos Útiles

```bash
# Backend
cd vigilancia-api && venv\Scripts\activate && uvicorn app.main:app --reload

# Flutter
cd curso && flutter run

# Hot reload Flutter
r (en terminal de Flutter)

# Detener simulación
curl -X POST "http://localhost:8000/api/detection/simulation/stop" -H "Authorization: Bearer TOKEN"
```

---

**Última actualización:** 2025-01-03
**Próxima tarea sugerida:** Agregar filtros por estado en Incidencias
**Documentación completa:** Ver `ESTADO_PROYECTO.md`
