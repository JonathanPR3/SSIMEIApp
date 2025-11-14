# 📊 Estado del Proyecto - Sistema de Vigilancia con Detección de Incidentes

**Última actualización:** 2025-11-08
**Proyecto:** App Flutter + FastAPI Backend
**Tema:** Sistema de seguridad con notificaciones en tiempo real + Gestión de organizaciones
**Estado actual:** ✅ **FUNCIONAL Y LISTO PARA DEMO** con ngrok

---

## 🚀 NOVEDAD: Despliegue con ngrok (2025-11-08)

### ✅ Configuración Completada
- ✅ **ngrok instalado y funcionando** - Expone API en URL pública temporal
- ✅ **Header especial agregado** - `ngrok-skip-browser-warning: true` para plan gratuito
- ✅ **Probado en dispositivo físico** - Samsung Galaxy Note 10+ (SM-N975F)
- ✅ **Funciona desde cualquier red** - No requiere estar en la misma WiFi que la laptop

### Configuración Actual en `lib/config/api_config.dart`:
```dart
static const String _baseUrlProduction = 'https://mathilda-conventually-esta.ngrok-free.dev';
static const bool isDevelopment = false; // ← Usando ngrok
```

### Flujo de Trabajo con ngrok:
1. **LAPTOP:** Correr API con `uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload`
2. **LAPTOP:** Correr ngrok con `ngrok http 8000`
3. **PC desarrollo:** Actualizar URL en `api_config.dart`
4. **CELULAR:** Instalar APK o conectar vía USB
5. **DEMO:** Funciona desde cualquier lugar con internet

### Archivos Modificados:
- `lib/config/api_config.dart` - URL de producción y header ngrok
- `lib/routes.dart` - Deshabilitada ruta web-only (`AcceptInvitationWebWrapper`)

---

## ✅ COMPLETADO

### 1. Autenticación y Login
- ✅ Login con JWT
- ✅ Registro de usuarios
- ✅ Gestión de sesión con SharedPreferences
- ✅ Middleware de autenticación en backend
- ✅ Token expira en 60 minutos
- ✅ Sistema de verificación de email ⭐ NUEVO 2025-11-13
- ✅ Recuperación de contraseña con código ⭐ NUEVO 2025-11-13
- ✅ Servicio de correo electrónico (yagmail) ⭐ NUEVO 2025-11-13

**Archivos:**
- `lib/services/api_auth_service.dart`
- `lib/screens/auth/login_screen.dart`
- `lib/screens/auth/register_screen.dart`
- `lib/screens/auth/confirm_email_screen.dart` ⭐ NUEVO

---

### 2. Gestión de Cámaras
- ✅ Listar cámaras de la organización
- ✅ Crear nueva cámara
- ✅ Editar cámara existente
- ✅ Eliminar cámara
- ✅ Ver stream RTSP (solo en mobile/desktop, no en web)
- ✅ Toggle modo mock/API

**Archivos:**
- `lib/services/camera_service.dart`
- `lib/screens/gestion_camaras.dart`
- `lib/screens/VistaCamara.dart`

**Modelo de BD:**
```sql
cameras: id, alias, ip_address, port, rtsp_url, username, location, description, organization_id
```

---

### 3. Sistema de Detecciones/Incidentes

#### 3.1 Modelos de Datos ✅
- ✅ `EvidenceModel` con campos de API
- ✅ 7 tipos de comportamiento (EvidenceType):
  - `suspiciousPose` - Pose Sospechosa
  - `unauthorizedPerson` - Persona No Autorizada
  - `forzadoCerradura` - Forzado de Cerradura
  - `agresionPuerta` - Agresión a Puerta
  - `escaladoVentana` - Escalado de Ventana
  - `arrojamientoObjetos` - Arrojamiento de Objetos
  - `vistaProlongada` - Vista Prolongada
- ✅ 4 niveles de severidad (IncidentSeverity):
  - `baja`, `media`, `alta`, `critica`
- ✅ Mapeo flexible desde API (maneja valores hardcodeados)

**Archivos:**
- `lib/models/evidence_model.dart`

**Modelo de BD (Backend):**
```sql
incidents:
- id (bigint, PK, auto_increment)
- camera_id (bigint, FK)
- organization_id (bigint, FK)
- description (text)
- timestamp (timestamp)
- confidence (float)
- s3_video_url (varchar 500)
```

**Nota:** Backend devuelve valores hardcodeados:
- `behavior_type = "otro"`
- `severity = "media"`
- `is_acknowledged = false`

Flutter mapea estos valores correctamente a tipos válidos.

#### 3.2 Servicios ✅
- ✅ `EvidenceService` - CRUD de incidentes
  - `getEvidences()` - Obtener lista con filtros
  - `getEvidenceById()` - Detalle de incidente
  - `getStats()` - Estadísticas
  - `updateEvidenceStatus()` - Reconocer incidente (acknowledge)
  - `getEvidencesByCamera()` - Filtrar por cámara
  - `searchEvidences()` - Búsqueda
- ✅ `WebSocketService` - Notificaciones en tiempo real
  - Conexión automática con JWT
  - Stream broadcast de incidentes
  - Manejo de mensajes: `new_incident`, `ping`, `incident_update`
- ✅ `SimulationService` - Control de simulación
  - `startSimulation()` - Iniciar generación de incidentes de prueba
  - `stopSimulation()` - Detener simulación
  - `getStatus()` - Estado de simulación

**Archivos:**
- `lib/services/evidence_service.dart` (`useMockMode = false`)
- `lib/services/websocket_service.dart`
- `lib/services/simulation_service.dart`

#### 3.3 UI/Pantallas ✅
- ✅ `Incidencias` - Lista de incidentes con timeline
  - Muestra tipo, cámara, timestamp
  - Colores e iconos por tipo de incidente
  - Pull-to-refresh
  - Navegación a detalle
- ✅ `EvidenciaDetail` - Detalle de incidente
  - Información completa
  - Thumbnail/placeholder de video
  - Colores e iconos dinámicos
- ✅ `HomeScreen` - Dashboard principal
  - Resumen de cámaras activas
  - Últimas 3 evidencias
  - **Integración WebSocket completa**
  - **Notificaciones push locales** ✅
  - **SnackBar en tiempo real** ✅
  - **Auto-actualización de datos** ✅

**Archivos:**
- `lib/screens/incidencias.dart`
- `lib/screens/evidencia_detail.dart`
- `lib/screens/home/home_screen.dart`

#### 3.4 Notificaciones en Tiempo Real ✅
- ✅ WebSocket conectado automáticamente al login
- ✅ Recibe notificaciones de nuevos incidentes
- ✅ Muestra notificación push local (Android)
- ✅ Muestra SnackBar en la app
- ✅ Recarga automática de datos
- ✅ Desconecta al cerrar sesión

**Configuración:**
```dart
// WebSocket URL se construye automáticamente
ws://localhost:8000/ws/notifications?token=JWT_TOKEN
```

---

### 4. API Endpoints Configurados ✅

**En `lib/config/api_config.dart`:**

```dart
// Autenticación
/auth/register
/auth/login
/auth/me

// Cámaras
/cameras
/cameras/{id}

// Incidentes/Detecciones
/api/detection/incidents
/api/detection/incidents/{id}
/api/detection/incidents/{id}/acknowledge
/api/detection/incidents/stats/summary

// Simulación
/api/detection/simulation/start
/api/detection/simulation/stop
/api/detection/simulation/status

// WebSocket
ws://localhost:8000/ws/notifications?token={token}
```

---

### 5. Backend (FastAPI) ✅

**Fixes aplicados:**
- ✅ Agregada función `verify_token()` en `app/services/auth_service.py`
- ✅ WebSocket endpoint funcional
- ✅ Simulación genera incidentes correctamente
- ✅ Endpoints de incidentes devuelven datos (aunque algunos hardcodeados)

**Archivo modificado:**
- `vigilancia-api/app/services/auth_service.py`

---

### 6. Sistema de Gestión de Organizaciones ✅ **NUEVO 2025-11-07**

#### 6.1 Modelos de Datos ✅
- ✅ `Organization` - Modelo de organización con miembros
- ✅ `OrganizationMember` - Modelo de miembro con rol (ADMIN/USER)
- ✅ `Invitation` - Modelo de invitación con token y link
- ✅ `InvitationVerification` - Verificar validez de invitación
- ✅ `JoinRequest` - Modelo de solicitud de unión

**Archivos:**
- `lib/models/organization_model.dart`
- `lib/models/invitation_model.dart`
- `lib/models/join_request_model.dart`

#### 6.2 Servicios ✅
- ✅ `OrganizationService` - CRUD de organizaciones
  - `getMyOrganization()` - Obtener org con miembros
  - `removeUser(userId)` - Eliminar miembro (solo Admin)
  - `transferOwnership(newAdminId)` - Transferir administración
  - `leaveOrganization()` - Salir de la org
- ✅ `InvitationService` - CRUD de invitaciones
  - `createInvitation({expiresInMinutes})` - Crear link universal
  - `verifyInvitation(token)` - Verificar validez (público)
  - `listInvitations()` - Listar todas (Admin)
  - `revokeInvitation(id)` - Revocar invitación
  - `getActiveInvitations()` - Filtrar activas
- ✅ `JoinRequestService` - CRUD de solicitudes
  - `createJoinRequest({token, message})` - Crear solicitud
  - `getMyRequests()` - Mis solicitudes
  - `getPendingRequests()` - Pendientes (Admin)
  - `getAllRequests()` - Todas (Admin)
  - `reviewRequest({id, approved, notes})` - Aprobar/Rechazar
  - `approveRequest(id)` - Helper aprobar
  - `rejectRequest(id)` - Helper rechazar

**Archivos:**
- `lib/services/organization_service.dart`
- `lib/services/invitation_service.dart`
- `lib/services/join_request_service.dart`

#### 6.3 UI/Pantallas ✅
- ✅ `ManageOrganizationScreen` - Pantalla principal con 3 tabs
  - **Tab 1: Miembros**
    - Header con estadísticas (Total, Admins, Users)
    - Lista de miembros con avatar, rol, email
    - Badge ADMIN con estrella
    - Eliminar usuarios USER (no Admin)
    - Pull to refresh
  - **Tab 2: Invitaciones** (solo ADMIN)
    - Botón "Crear Nueva Invitación"
    - Lista de invitaciones activas y expiradas
    - Copiar link al portapapeles
    - Contador de tiempo hasta expiración
    - Revocar invitación
    - Contador de invitaciones activas
  - **Tab 3: Solicitudes** (solo ADMIN)
    - Sección de solicitudes pendientes
    - Sección de historial (aprobadas/rechazadas)
    - Botones Aprobar/Rechazar
    - Mostrar mensaje del solicitante
    - Badge de estado

**Archivos:**
- `lib/screens/organization/manage_organization_screen.dart`

#### 6.4 Funcionalidades Extra ✅
- ✅ Badge de notificaciones en AppBar (muestra solicitudes pendientes)
- ✅ Botón refresh en AppBar
- ✅ Loading states en todas las operaciones
- ✅ Dialogs de confirmación para acciones críticas
- ✅ SnackBars con feedback
- ✅ Permisos basados en rol (ADMIN vs USER)
- ✅ Manejo completo de errores
- ✅ Estados vacíos informativos
- ✅ Pull to refresh en todos los tabs
- ✅ Dark theme consistente

---

## 🟡 PARCIALMENTE COMPLETADO

### 1. Gestión de Incidentes - Filtrado y Estados
**Estado:** Funciona básicamente pero falta UX mejorada

**Lo que funciona:**
- ✅ Listar todos los incidentes
- ✅ Ver detalle de incidente
- ✅ Reconocer incidente (endpoint existe)

**Lo que falta mejorar:**
- ⚠️ Filtros por estado (Pendientes/Revisadas/Todas)
- ⚠️ Botón "Marcar como revisada" visible en UI
- ⚠️ Botón "Marcar todas como revisadas"
- ⚠️ Vista por defecto: solo pendientes (evitar saturación)
- ⚠️ Paginación para muchos incidentes

**Archivos a modificar:**
- `lib/screens/incidencias.dart` - Agregar filtros/tabs
- `lib/screens/evidencia_detail.dart` - Agregar botón "Marcar como revisada"

---

## ❌ PENDIENTE / NO IMPLEMENTADO

### 1. Sistema de Organizaciones - Mejoras Opcionales
**Estado:** Funcional, faltan solo mejoras UX

**Pendiente:**
- ⚠️ Agregar navegación desde HomeScreen
- ⚠️ Pantalla de "Unirse con Token" para usuarios que reciben invitación
- ⚠️ Deep links para abrir app con link de invitación
- ⚠️ Push notifications cuando llega nueva solicitud

**Decisión:** Sistema funcional completo, solo faltan mejoras opcionales

---

### 2. Eliminación de Incidentes
**Estado:** No implementado (diseño pendiente)

**Opciones a considerar:**
- **Opción A (Recomendada):** NO eliminar, solo filtrar por estado
- **Opción B:** Crear endpoint DELETE y botones de eliminar (requiere backend)

**Decisión:** Pendiente de definir con el equipo

---

### 3. Campos Extendidos en BD
**Estado:** Backend devuelve valores hardcodeados

**Campos que faltan en tabla `incidents`:**
- `behavior_type` - Tipo de comportamiento real
- `severity` - Nivel de severidad real
- `is_acknowledged` - Estado de reconocimiento
- `acknowledged_by_user_id` - Usuario que reconoció
- `acknowledged_at` - Timestamp de reconocimiento
- `notes` - Notas del reconocimiento
- `s3_image_url` - URL de imagen capturada
- `detected_objects` - JSON de objetos detectados
- `pose_data` - JSON de poses detectadas
- `status` - Estado detallado (DETECTADO, EN_PROCESO, CONFIRMADO)

**Nota:** Flutter ya está preparado para recibir estos campos cuando el backend los implemente.

**Solución actual:** Flutter mapea valores hardcodeados correctamente, funciona pero con datos limitados.

---

### 4. Despliegue
**Estado:** Todo corriendo en localhost

**Pendiente:**
- ⚠️ Desplegar backend FastAPI en servidor (Heroku, AWS, Railway, etc.)
- ⚠️ Actualizar `api_config.dart` con URL de producción
- ⚠️ Configurar CORS en backend para producción
- ⚠️ Certificados SSL para WebSocket seguro (wss://)

---

### 5. Notificaciones iOS
**Estado:** Solo Android configurado

**Pendiente:**
- ⚠️ Configurar `flutter_local_notifications` para iOS
- ⚠️ Permisos de notificaciones en iOS
- ⚠️ Testing en dispositivo iOS

---

### 6. Pruebas con Cámaras Reales
**Estado:** Solo simulación probada

**Pendiente:**
- ⚠️ Conectar con modelo de detección real (YOLOv8, etc.)
- ⚠️ Integrar con streams RTSP reales
- ⚠️ Procesar frames y generar detecciones
- ⚠️ Subir videos/imágenes a S3

---

## 🧪 CÓMO PROBAR TODO

### 1. Iniciar Backend
```bash
cd C:\Users\jonit\OneDrive\Documentos\GitHub\vigilancia-api
venv\Scripts\activate
uvicorn app.main:app --reload
```

### 2. Iniciar Flutter App
```bash
cd C:\Users\jonit\OneDrive\Documentos\GitHub\CamarasSeguridadTT\curso
flutter run
```

### 3. Login
- Usuario: `jonitopera777@gmail.com`
- Organización: 3
- Cámara disponible: ID 2
- Rol: ADMIN (puede ver toda la gestión de organizaciones)

### 3.5 Probar Sistema de Organizaciones
- Navegar a "Gestión de Organización" (necesitas agregar navegación desde HomeScreen)
- **Tab Miembros**: Ver lista de miembros
- **Tab Invitaciones**: Crear invitación → Copiar link
- **Tab Solicitudes**: Ver solicitudes pendientes (si las hay)

### 4. Iniciar Simulación (Generar Incidentes)
```bash
curl -X POST "http://localhost:8000/api/detection/simulation/start" \
  -H "Authorization: Bearer TU_TOKEN_JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "camera_id": 2,
    "interval_seconds": 5,
    "behavior_types": ["forzado_cerradura"],
    "min_confidence": 0.6,
    "max_confidence": 0.95,
    "enabled": true
  }'
```

### 5. Ver Notificaciones
- 📱 Notificación push local (cada 5 segundos)
- 📢 SnackBar en la app
- 🔄 Lista de incidencias se actualiza automáticamente

### 6. Detener Simulación
```bash
curl -X POST "http://localhost:8000/api/detection/simulation/stop" \
  -H "Authorization: Bearer TU_TOKEN_JWT"
```

---

## 🐛 PROBLEMAS CONOCIDOS Y SOLUCIONES

### 1. WebSocket no conecta
**Síntoma:** `❌ Error en WebSocket: WebSocketChannelException`

**Solución:**
1. Verificar que backend esté corriendo
2. Reiniciar backend después de cambios
3. Verificar URL en `api_config.dart`
   - Emulador Android: `http://10.0.2.2:8000`
   - Dispositivo físico: `http://192.168.1.X:8000`

### 2. Token 401 Unauthorized
**Síntoma:** `INFO: 127.0.0.1 - "POST /api/..." 401 Unauthorized`

**Solución:**
1. Cerrar sesión y volver a iniciar sesión
2. Copiar el nuevo token de los logs
3. Token expira en 60 minutos

### 3. Simulación da 404
**Síntoma:** `POST /api/detection/simulation/start 404 Not Found`

**Solución:**
1. Verificar que el router esté registrado en `main.py`
2. URL correcta: `/api/detection/simulation/start`
3. Reiniciar backend

### 4. Incidentes no aparecen
**Síntoma:** Notificaciones llegan pero pantalla vacía

**Solución:**
1. Verificar `useMockMode = false` en `evidence_service.dart`
2. Verificar que `camera_id` existe (usar ID 2)
3. Verificar logs: `✅ X incidentes obtenidos`

### 5. VLC Player no funciona en Web
**Síntoma:** Error al cargar stream RTSP en navegador

**Solución:**
- Esto es esperado, VLC solo funciona en mobile/desktop
- Web muestra mensaje informativo
- Para web necesitarías HLS o WebRTC

---

## 📁 ARCHIVOS IMPORTANTES

### Flutter (App Móvil)
```
lib/
├── config/
│   └── api_config.dart ⭐ Configuración de endpoints
├── models/
│   ├── evidence_model.dart ⭐ Modelo de incidentes
│   └── camera_model.dart
├── services/
│   ├── evidence_service.dart ⭐ CRUD de incidentes
│   ├── websocket_service.dart ⭐ Notificaciones en tiempo real
│   ├── simulation_service.dart ⭐ Control de simulación
│   ├── camera_service.dart
│   └── api_auth_service.dart
├── screens/
│   ├── incidencias.dart ⭐ Lista de incidentes
│   ├── evidencia_detail.dart ⭐ Detalle de incidente
│   └── home/
│       └── home_screen.dart ⭐ Dashboard con WebSocket
└── pubspec.yaml (web_socket_channel: ^2.4.0)
```

### Backend (FastAPI)
```
app/
├── endpoints/
│   └── detection_endpoints.py ⭐ Endpoints de incidentes
├── services/
│   ├── auth_service.py ⭐ verify_token agregado
│   ├── detection_service.py
│   └── notification_service.py
├── database.py (modelo Incident)
└── main.py (routers registrados)
```

### Documentación
```
ESTADO_PROYECTO.md ⭐ Este archivo
DETECCIONES_IMPLEMENTADAS.md ⭐ Detalle técnico de implementación
COMO_PROBAR_NOTIFICACIONES.md ⭐ Guía de pruebas
FIX_WEBSOCKET.md - Fix aplicado
IMPLEMENTACION_DETECCIONES_GUIDE.md - Guía original (completada)
```

---

## 🚀 PRÓXIMOS PASOS SUGERIDOS

### Corto Plazo (Esta semana)
1. ✅ ~~WebSocket funcionando~~ **COMPLETADO**
2. ✅ ~~Notificaciones en tiempo real~~ **COMPLETADO**
3. 🔲 Agregar filtros por estado en pantalla de Incidencias
4. 🔲 Botón "Marcar como revisada" en detalle
5. 🔲 Testing exhaustivo de notificaciones

### Mediano Plazo (Próxima semana)
1. 🔲 Desplegar backend en servidor
2. 🔲 Actualizar campos de BD para datos reales (no hardcodeados)
3. 🔲 Implementar paginación en lista de incidentes
4. 🔲 Testing en dispositivo físico Android
5. 🔲 Configurar notificaciones iOS

### Largo Plazo (Mes siguiente)
1. 🔲 Integrar con modelo de detección real (YOLOv8)
2. 🔲 Procesar streams RTSP reales
3. 🔲 Subir videos/imágenes a S3
4. 🔲 Dashboard de analíticas
5. 🔲 Reportes y exportación

---

## 💡 NOTAS PARA CLAUDE FUTURO

1. **Modo Mock:** Actualmente `useMockMode = false` en `evidence_service.dart` (usar API real)

2. **Backend devuelve hardcoded:** `behavior_type="otro"`, `severity="media"`, `is_acknowledged=false`
   - Flutter mapea correctamente a tipos válidos
   - No hay problema, funciona

3. **WebSocket:** Ya integrado en `home_screen.dart`
   - Se conecta automáticamente al login
   - Muestra notificaciones push + SnackBar
   - Recarga datos automáticamente

4. **Simulación:** Usar `camera_id: 2` (única cámara en BD)
   - Usuario org 3, cámara org 3
   - Token expira en 60 min

5. **No eliminar incidentes:** Decisión pendiente
   - Opción recomendada: Filtros por estado
   - Mantener historial para auditoría

6. **Testing:** Ver `COMO_PROBAR_NOTIFICACIONES.md`

---

## ✅ CHECKLIST RÁPIDO

**Sistema Core:**
- [x] Login/Registro
- [x] Gestión de cámaras
- [x] Listar incidentes
- [x] Ver detalle de incidente
- [x] WebSocket notificaciones
- [x] Notificaciones push locales
- [x] Simulación de incidentes
- [x] Auto-actualización en tiempo real

**Despliegue y Testing (ACTUALIZADO 2025-11-08):**
- [x] ✅ **ngrok configurado** - App funciona remotamente desde cualquier red
- [x] ✅ **Probado en dispositivo físico** - Samsung Galaxy Note 10+ funcionando
- [x] ✅ **Header ngrok agregado** - Soluciona página de advertencia de ngrok free
- [x] ✅ **Rutas mobile corregidas** - AcceptInvitationWebWrapper deshabilitado en mobile
- [ ] Compilar APK release para instalación independiente

**Pendiente UX (Minor Fixes):**
- [ ] **Ajustes responsive** - Mejorar adaptación a diferentes tamaños de pantalla
- [ ] **Refinar espaciados** - Mejorar márgenes y padding en listas
- [ ] Filtros por estado (Pendientes/Revisadas)
- [ ] Botón "Marcar como revisada" más visible
- [ ] Vista por defecto: solo pendientes
- [ ] Paginación (opcional)

**Pendiente Backend (Opcional):**
- [ ] Campos extendidos en BD (behavior_type, severity real)
- [ ] Valores reales (no hardcoded)
- [ ] Despliegue permanente en Railway/Render (opcional - actualmente usa ngrok)

**Pendiente Producción (Futuro):**
- [ ] Testing exhaustivo
- [ ] Notificaciones iOS
- [ ] Modelo de detección real (YOLOv8)
- [ ] S3 para videos/imágenes

---

**Estado Actual (2025-11-08):**
- ✅ App completamente funcional en dispositivo físico
- ✅ Conectada a API remota vía ngrok
- ✅ Sistema de organizaciones completo
- ✅ WebSocket funcionando en tiempo real
- 🎯 **Próximo paso:** Minor fixes UI/UX y compilar APK release

🚀 **El sistema está funcional y listo para demo completo con profesor**
