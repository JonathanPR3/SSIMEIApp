# Guía de Conexión con la Nueva API FastAPI

## ✅ Cambios Completados

### 1. Configuración Actualizada (`lib/config/api_config.dart`)
- ✅ `useMockMode` cambiado a `false` para usar API real
- ✅ Endpoints actualizados para FastAPI
- ✅ IDs cambiados de `String` a `int` según la API

### 2. Servicio de Autenticación (`lib/services/api_auth_service.dart`)
- ✅ Mapeo de datos actualizado para la nueva estructura:
  - API: `id`, `name`, `last_name`, `mother_last_name`, `role` (ADMIN/USER)
  - Flutter: `id`, `nombre`, `apellidoPaterno`, `apellidoMaterno`, `userType`
- ✅ Registro actualizado (crea automáticamente ADMIN con organización)
- ✅ Login actualizado con tokens JWT
- ✅ Endpoints de confirmación de email deshabilitados (no existen en nueva API)

### 3. Provider (`lib/providers/auth_provider.dart`)
- ✅ Ya está configurado para usar `ApiAuthService`
- ✅ `currentAuthBackend = AuthBackend.api` (línea 22)

---

## 🚀 Cómo Probar la Conexión

### Paso 1: Iniciar la API FastAPI

En una terminal, navega a tu API y ejecútala:

```bash
cd C:\Users\jonit\OneDrive\Documentos\GitHub\vigilancia-api
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Verifica que esté corriendo:
- Swagger UI: http://localhost:8000/docs
- Health check: http://localhost:8000/health

### Paso 2: Configurar la URL según tu entorno

**Si usas el emulador de Android:**
Edita `lib/config/api_config.dart` línea 8:

```dart
static const String _baseUrlDevelopment = 'http://10.0.2.2:8000';
```

**Si usas un dispositivo físico en la misma red:**
```dart
static const String _baseUrlDevelopment = 'http://TU_IP_LOCAL:8000';
// Ejemplo: 'http://192.168.1.100:8000'
```

Para encontrar tu IP local:
```bash
# Windows
ipconfig

# Busca "IPv4 Address" en tu adaptador de red
```

**Si usas iOS Simulator o web:**
```dart
static const String _baseUrlDevelopment = 'http://localhost:8000';
```

### Paso 3: Ejecutar la App Flutter

```bash
cd C:\Users\jonit\OneDrive\Documentos\GitHub\CamarasSeguridadTT\curso
flutter run
```

### Paso 4: Probar Registro y Login

1. **Registrar un nuevo usuario:**
   - Email: `test@example.com`
   - Password: `12345678` (mínimo 8 caracteres)
   - Nombre: `Juan`
   - Apellido: `Pérez`
   - Apellido Materno: `García`

2. **Verificar en logs:**
   ```
   📝 Registrando admin via API: test@example.com
   🌐 POST http://localhost:8000/auth/register
   📤 Body: {"email":"test@example.com","password":"...","name":"Juan",...}
   📥 Response status: 201
   ✅ Admin registrado exitosamente
   ```

3. **Hacer login:**
   - Email: `test@example.com`
   - Password: `12345678`

4. **Verificar en logs:**
   ```
   🔐 Iniciando login via API: test@example.com
   📦 Respuesta de login recibida
   ✅ Login exitoso: Juan Pérez García
   ```

---

## 🔍 Debugging

### Ver logs en detalle

Los servicios ya tienen logs integrados. Busca en la consola:
- `🌐` = Peticiones HTTP
- `📦` = Respuestas recibidas
- `✅` = Operaciones exitosas
- `❌` = Errores

### Problemas comunes

#### 1. Error: "Sin conexión a internet"
**Causa:** La app no puede conectarse a la API

**Solución:**
- Verifica que la API esté corriendo (`http://localhost:8000/health`)
- Revisa la URL en `api_config.dart`
- Si usas emulador Android, usa `10.0.2.2` en lugar de `localhost`

#### 2. Error: "Email ya registrado"
**Causa:** El email ya existe en la base de datos

**Solución:**
- Usa otro email
- O limpia la base de datos desde el backend

#### 3. Error: "Credenciales incorrectas"
**Causa:** Password incorrecto o usuario no existe

**Solución:**
- Verifica que el usuario esté registrado primero
- Asegúrate de usar la misma contraseña

#### 4. Error: "Error 500"
**Causa:** Error en el servidor

**Solución:**
- Revisa los logs del servidor FastAPI
- Verifica que la base de datos esté corriendo

---

## 📋 Diferencias Clave vs AWS Cognito

| Característica | AWS Cognito (Viejo) | FastAPI API (Nuevo) |
|----------------|---------------------|---------------------|
| Confirmación de email | ✅ Requerida | ❌ No requerida |
| Recuperación de contraseña | ✅ Con códigos | ❌ No implementada aún |
| Refresh tokens | ✅ Automático | ⚠️ TODO |
| Tipo de usuario | admin/common | ADMIN/USER |
| Organización | adminId | organization_id |
| IDs | String (UUID) | Integer (auto_increment) |

---

## 🔄 Flujo de Registro Actualizado

### Antes (Cognito):
1. Registro → Email de confirmación
2. Ingresar código → Cuenta activada
3. Login

### Ahora (FastAPI):
1. Registro → Cuenta creada inmediatamente
2. Login directamente (sin confirmación)

**NOTA:** Los usuarios comunes deben unirse mediante **invitaciones**, no mediante registro directo.

---

## 🎯 Siguientes Pasos

### 1. Implementar Sistema de Invitaciones (PRIORITARIO)

Tu API tiene endpoints de invitaciones, pero Flutter aún no los usa:

**Endpoints disponibles:**
- `POST /invitations` - Crear invitación (admin)
- `POST /invitations/accept` - Aceptar invitación
- `GET /invitations` - Listar invitaciones

**TODO en Flutter:**
- Crear `lib/services/invitation_service.dart`
- Agregar pantalla para generar invitaciones
- Agregar pantalla para aceptar invitaciones

### 2. Implementar Gestión de Cámaras

**Endpoints disponibles:**
- `POST /cameras` - Crear cámara
- `GET /cameras` - Listar cámaras
- `PUT /cameras/{id}` - Actualizar cámara
- `DELETE /cameras/{id}` - Eliminar cámara

**TODO en Flutter:**
- Actualizar `lib/services/camera_service.dart` para usar API
- Conectar pantallas existentes con la API real

### 3. Implementar Detecciones/Incidentes

**Endpoints disponibles:**
- `POST /api/detection/simulate` - Simular detección
- `GET /api/detection/last` - Última detección
- WebSocket: `/ws/notifications` - Notificaciones en tiempo real

**TODO en Flutter:**
- Actualizar `lib/services/evidence_service.dart`
- Implementar WebSocket client para notificaciones

### 4. Reconocimiento Facial

Tu `lib/services/face_api_service.dart` ya está preparado. Solo falta:
- Actualizar URL base en el servicio
- Implementar endpoints de rostros en el backend

### 5. Refresh Tokens

**TODO:**
- Implementar endpoint `/auth/refresh` en FastAPI
- Actualizar `lib/services/api_service.dart` para refrescar tokens automáticamente

---

## 🧪 Testing Checklist

- [ ] Registro de admin funciona
- [ ] Login funciona
- [ ] Logout funciona
- [ ] Sesión persiste al cerrar/abrir app
- [ ] Token se guarda correctamente
- [ ] Endpoint `/auth/me` funciona
- [ ] Cambio de contraseña funciona
- [ ] Listar usuarios de organización funciona
- [ ] Actualizar perfil funciona

---

## 📝 Notas Importantes

1. **Modo Mock deshabilitado:** La app ahora hace peticiones reales a la API. Si necesitas volver a modo mock, cambia `useMockMode = true` en `api_config.dart`.

2. **Tokens JWT:** Los tokens se guardan en `SharedPreferences` con las keys:
   - `api_access_token`
   - `api_refresh_token`

3. **Organización:** Al registrarse, el usuario automáticamente se convierte en ADMIN de su propia organización creada por la API.

4. **Códigos AWS:** El código de Cognito sigue en `lib/services/auth_service.dart` por si necesitas volver atrás. Para eliminarlo completamente:
   - Elimina `lib/services/auth_service.dart`
   - Elimina `lib/config/aws_config.dart`
   - Remueve `amazon_cognito_identity_dart_2` de `pubspec.yaml`

---

## 🐛 Reportar Problemas

Si encuentras errores:

1. Revisa los logs de Flutter (busca `❌`)
2. Revisa los logs de FastAPI
3. Verifica el estado con `/health`
4. Usa Swagger UI para probar endpoints manualmente

---

## 📚 Documentación de la API

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc
- Health Check: http://localhost:8000/health
