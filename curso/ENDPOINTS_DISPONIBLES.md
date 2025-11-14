# 📡 Endpoints Disponibles en la API - Estado de Integración

**Fecha:** 2025-11-13 (Última actualización)
**Backend:** FastAPI v3.0.0
**URL Base:** http://localhost:8000

---

## ✅ ENDPOINTS YA INTEGRADOS EN FLUTTER

### 1. Autenticación (`/auth`)
- ✅ `POST /auth/register` - Registro de usuario
- ✅ `POST /auth/login` - Inicio de sesión
- ✅ `GET /auth/me` - Información del usuario actual
- ✅ `POST /auth/verify-email` - Verificar código de email ⭐ IMPLEMENTADO 2025-11-13
- ✅ `POST /auth/resend-verification` - Reenviar código de verificación ⭐ IMPLEMENTADO 2025-11-13
- ✅ `POST /auth/forgot-password` - Solicitar código de recuperación ⭐ IMPLEMENTADO 2025-11-13
- ✅ `POST /auth/verify-reset-code` - Verificar código de recuperación ⭐ IMPLEMENTADO 2025-11-13
- ✅ `POST /auth/reset-password` - Restablecer contraseña ⭐ IMPLEMENTADO 2025-11-13

**Archivos Flutter:**
- `lib/services/api_auth_service.dart`
- `lib/screens/auth/login_screen.dart`
- `lib/screens/auth/register_screen.dart`
- `lib/screens/auth/confirm_email_screen.dart` ⭐ Email verification
- `lib/screens/auth/forgot_password_screen.dart` ⭐ Password recovery
- `lib/screens/auth/reset_password_screen.dart` ⭐ Password reset

---

### 2. Gestión de Cámaras (`/cameras`)
- ✅ `GET /cameras` - Listar cámaras de la organización
- ✅ `POST /cameras` - Crear nueva cámara
- ✅ `GET /cameras/{id}` - Obtener detalle de cámara
- ✅ `PUT /cameras/{id}` - Actualizar cámara
- ✅ `DELETE /cameras/{id}` - Eliminar cámara

**Archivos Flutter:**
- `lib/services/camera_service.dart`
- `lib/screens/gestion_camaras.dart`
- `lib/screens/VistaCamara.dart`

---

### 3. Detecciones/Incidentes (`/api/detection`)
- ✅ `GET /api/detection/incidents` - Listar incidentes (con filtros)
- ✅ `GET /api/detection/incidents/{id}` - Detalle de incidente
- ✅ `POST /api/detection/incidents/{id}/acknowledge` - Marcar como revisado
- ✅ `GET /api/detection/incidents/stats/summary` - Estadísticas
- ✅ `POST /api/detection/simulation/start` - Iniciar simulación
- ✅ `POST /api/detection/simulation/stop` - Detener simulación
- ✅ `GET /api/detection/simulation/status` - Estado de simulación

**Archivos Flutter:**
- `lib/services/evidence_service.dart`
- `lib/services/simulation_service.dart`
- `lib/screens/incidencias.dart`
- `lib/screens/evidencia_detail.dart`

---

### 4. WebSocket Notificaciones
- ✅ `WS /ws/notifications?token={jwt}` - Notificaciones en tiempo real

**Archivos Flutter:**
- `lib/services/websocket_service.dart`
- `lib/screens/home/home_screen.dart`

---

## ✅ ENDPOINTS INTEGRADOS RECIENTEMENTE (2025-11-07)

### 1. Gestión de Organizaciones (`/organizations`) ✅ COMPLETADO

#### Endpoints integrados:
- ✅ `GET /organizations/my-organization` - Obtener info de mi organización
- ✅ `POST /organizations/transfer-ownership` - Transferir administración
- ✅ `DELETE /organizations/users/{user_id}` - Remover usuario (solo Admin)
- ✅ `POST /organizations/leave` - Salir de la organización

#### Implementado en:
- **Service:** `lib/services/organization_service.dart`
- **Model:** `lib/models/organization_model.dart`
- **UI:** `lib/screens/organization/manage_organization_screen.dart` (Tab Miembros)

#### Funcionalidades disponibles:
- Ver detalles de la organización actual
- Ver lista de miembros con roles
- Admin puede remover usuarios USER
- Admin puede transferir administración (endpoint listo, UI pendiente)
- Usuarios pueden salir de org (endpoint listo, UI pendiente)

---

### 2. Sistema de Invitaciones (`/invitations`) ✅ COMPLETADO

#### Endpoints integrados:
- ✅ `POST /invitations` - Crear invitación (Admin)
- ✅ `GET /invitations/verify/{token}` - Verificar invitación (público)
- ✅ `GET /invitations` - Listar invitaciones (Admin)
- ✅ `DELETE /invitations/{id}` - Revocar invitación (Admin)

#### Implementado en:
- **Service:** `lib/services/invitation_service.dart`
- **Model:** `lib/models/invitation_model.dart`
- **UI:** `lib/screens/organization/manage_organization_screen.dart` (Tab Invitaciones)

#### Funcionalidades disponibles:
- Admin genera link de invitación universal (expira en 10 min)
- Admin copia link al portapapeles
- Admin ve lista de invitaciones activas y expiradas
- Admin revoca invitaciones
- Contador de tiempo hasta expiración
- Verificar validez de invitación (público)

**Flujo implementado:**
```
1. Admin → Tab Invitaciones → Crear Nueva
2. Backend genera link con token
3. Admin copia link y comparte
4. Usuario recibe link (pendiente: pantalla de unirse)
```

---

### 3. Solicitudes de Unión (`/join-requests`) ✅ COMPLETADO

#### Endpoints integrados:
- ✅ `POST /join-requests` - Crear solicitud con token de invitación
- ✅ `GET /join-requests/my-requests` - Mis solicitudes
- ✅ `GET /join-requests/pending` - Solicitudes pendientes (Admin)
- ✅ `GET /join-requests/all` - Todas las solicitudes (Admin)
- ✅ `POST /join-requests/{id}/review` - Aprobar/Rechazar (Admin)

#### Implementado en:
- **Service:** `lib/services/join_request_service.dart`
- **Model:** `lib/models/join_request_model.dart`
- **UI:** `lib/screens/organization/manage_organization_screen.dart` (Tab Solicitudes)

#### Funcionalidades disponibles:
- Ver solicitudes pendientes de la organización
- Ver historial completo (aprobadas/rechazadas)
- Aprobar solicitudes → Usuario agregado como USER
- Rechazar solicitudes
- Ver mensaje del solicitante
- Badge de notificaciones con contador
- Tiempo desde la solicitud ("Hace 2 horas")

**Flujo implementado:**
```
1. Usuario → POST /join-requests (pendiente: UI)
2. Admin → Tab Solicitudes → Ve nueva solicitud
3. Admin → Tap "Aprobar" → Usuario agregado
4. Admin → Tab Miembros → Ve nuevo miembro
```

---

## ❌ ENDPOINTS NO INTEGRADOS (DISPONIBLES PARA IMPLEMENTAR)

---

### 4. Permisos de Cámaras (`/permissions`) 🎯 MEDIA PRIORIDAD

#### Endpoints disponibles:
- ❌ `POST /permissions/grant` - Otorgar permiso a usuario
- ❌ `POST /permissions/grant-batch` - Otorgar múltiples permisos
- ❌ `DELETE /permissions/revoke` - Revocar permiso
- ❌ `DELETE /permissions/revoke-all/{user_id}` - Revocar todos los permisos
- ❌ `GET /permissions/user/{user_id}/cameras` - Cámaras del usuario
- ❌ `GET /permissions/camera/{camera_id}/users` - Usuarios con acceso
- ❌ `GET /permissions/stats` - Estadísticas de permisos
- ❌ `GET /permissions/check-access` - Verificar acceso específico

#### Casos de uso:
- **Sistema de permisos granular:**
  - ADMIN tiene acceso a todas las cámaras (automático)
  - USER solo tiene acceso a cámaras específicas asignadas
- Admin asigna permisos de cámaras a usuarios USER
- Admin revoca permisos
- Ver qué usuarios tienen acceso a qué cámaras
- Verificar si un usuario puede ver una cámara

#### Prioridad: **MEDIA** (útil para organizaciones grandes)

---

## 🎯 SUGERENCIA DE IMPLEMENTACIÓN POR FASES

### **Fase 1: Sistema de Membresía** ✅ COMPLETADA (2025-11-07)
Sistema completo de invitaciones y solicitudes de unión.

**Endpoints integrados:**
1. ✅ Invitaciones: crear, verificar, listar, revocar
2. ✅ Join Requests: crear, listar, aprobar/rechazar
3. ✅ Organizaciones: ver mi org, ver miembros, eliminar usuarios

**Pantallas Flutter creadas:**
- ✅ `lib/screens/organization/manage_organization_screen.dart` - 3 tabs (Miembros, Invitaciones, Solicitudes)

**Servicios Flutter creados:**
- ✅ `lib/services/invitation_service.dart`
- ✅ `lib/services/join_request_service.dart`
- ✅ `lib/services/organization_service.dart`

**Modelos creados:**
- ✅ `lib/models/organization_model.dart`
- ✅ `lib/models/invitation_model.dart`
- ✅ `lib/models/join_request_model.dart`

**Pendiente de Fase 1:**
- ⚠️ Agregar navegación desde HomeScreen
- ⚠️ Pantalla para que usuarios se unan con token (opcional)

---

### **Fase 2: Permisos Granulares (OPCIONAL)** 🎯
Implementar sistema de permisos de cámaras para organizaciones grandes.

**Endpoints a integrar:**
1. Permisos: otorgar, revocar, listar

**Pantallas Flutter necesarias:**
- `lib/screens/camera_permissions_screen.dart` (Admin)
- Modificar `lib/screens/gestion_camaras.dart` para mostrar permisos

**Servicios Flutter necesarios:**
- `lib/services/permission_service.dart`

**Beneficio:**
- Control fino de acceso a cámaras
- Usuarios USER solo ven cámaras asignadas
- Útil para organizaciones con muchos usuarios

---

### **Fase 3: Gestión Avanzada de Org (OPCIONAL)** 📊
Funciones adicionales de administración.

**Endpoints a integrar:**
1. Transferir administración
2. Salir de organización
3. Remover usuarios

**Beneficio:**
- Admin puede delegar administración
- Usuarios pueden salir de organizaciones
- Gestión completa de membresía

---

## 📋 PRÓXIMOS PASOS SUGERIDOS

### ✅ Sistema de Organizaciones: COMPLETADO
Todo el flujo de invitaciones está implementado y funcionando.

**Lo que falta:**
1. ⚠️ Agregar navegación desde HomeScreen a ManageOrganizationScreen
2. ⚠️ (Opcional) Pantalla para usuarios que reciben link de invitación
3. ⚠️ (Opcional) Deep links para abrir app con link
4. ⚠️ (Opcional) Push notifications para nuevas solicitudes

**Para agregar navegación (ejemplo):**
```dart
// En home_screen.dart
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ManageOrganizationScreen(),
      ),
    );
  },
  icon: const Icon(Icons.business),
  label: const Text('Gestionar Organización'),
),
```

---

### Opción B: Solo Gestión de Organización
Si solo quieres ver/gestionar miembros actuales:

**Implementar:**
1. `GET /organizations/my-organization` - Ver organización y miembros
2. `DELETE /organizations/users/{user_id}` - Remover usuarios (Admin)

**Tiempo estimado:** 4-6 horas de desarrollo

---

### Opción C: Sistema de Permisos de Cámaras
Si quieres control fino de acceso a cámaras:

**Implementar:**
1. `GET /permissions/user/{user_id}/cameras` - Ver cámaras del usuario
2. `POST /permissions/grant` - Otorgar permiso
3. `DELETE /permissions/revoke` - Revocar permiso
4. `GET /permissions/camera/{camera_id}/users` - Ver usuarios con acceso

**Tiempo estimado:** 1 día de desarrollo

---

## 🔧 CONFIGURACIÓN ACTUAL EN FLUTTER

### ApiConfig ya tiene definidos algunos endpoints:
```dart
// lib/config/api_config.dart
static const String organizations = '/organizations';
static const String invitations = '/invitations';
static const String joinRequests = '/join-requests';
```

**Pero NO tienen servicios ni pantallas implementadas.**

---

## 💡 PRÓXIMOS PASOS SUGERIDOS

1. **Decidir qué funcionalidad implementar primero:**
   - ¿Sistema de invitaciones?
   - ¿Gestión de miembros?
   - ¿Permisos de cámaras?
   - ¿Filtros de incidentes? (pendiente de fase 1)

2. **Crear los servicios necesarios:**
   - `invitation_service.dart`
   - `join_request_service.dart`
   - `organization_service.dart`
   - `permission_service.dart`

3. **Crear las pantallas correspondientes**

4. **Integrar con WebSocket** (opcional):
   - Notificar cuando hay nueva solicitud de unión
   - Notificar cuando se aprueba/rechaza solicitud

---

## 📊 RESUMEN EJECUTIVO

**Total de endpoints en backend:** ~50+

**Ya integrados:** ~25 (50%) ⭐ ACTUALIZADO 2025-11-07
- ✅ Auth: 3 endpoints
- ✅ Cámaras: 5 endpoints
- ✅ Incidentes: 7 endpoints
- ✅ WebSocket: 1 endpoint
- ✅ Organizaciones: 4 endpoints ⭐ NUEVO
- ✅ Invitaciones: 4 endpoints ⭐ NUEVO
- ✅ Join Requests: 5 endpoints ⭐ NUEVO

**Pendientes:** ~25 (50%)
- ❌ Permisos de Cámaras: 8 endpoints
- ❌ Usuarios: ~10 endpoints (cambio contraseña, búsqueda, etc.)
- ❌ Otros: ~7 endpoints

**Prioridad sugerida:**
1. ✅ ~~Sistema de Invitaciones + Join Requests~~ **COMPLETADO** ⭐
2. ✅ ~~Gestión de Organización~~ **COMPLETADO** ⭐
3. 🎯 **Permisos de Cámaras** (control de acceso granular)
4. ⚙️ **Gestión de Usuarios** (cambiar contraseña, perfil, etc.)
5. 🔗 **Navegación a pantalla de organizaciones**

---

**¿Qué quieres implementar primero?** 🚀
