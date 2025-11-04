# Cambios en el Flujo de Autenticación

## ✅ Problemas Resueltos

### 1. Error en Login - Refresh Token (RESUELTO)
**Problema:**
```
❌ Error en login: TypeError: null: type 'Null' is not a subtype of type 'String'
```

**Causa:**
La API FastAPI no devuelve `refresh_token` en la respuesta del login, solo `access_token`.

**Solución:**
Actualizado `lib/services/api_auth_service.dart:145` para usar el `access_token` como fallback:
```dart
final refreshToken = response.data!['refresh_token'] as String? ?? accessToken;
```

### 2. Flujo de Confirmación de Email (ACTUALIZADO)
**Antes (con Cognito):**
1. Usuario se registra
2. Recibe email con código
3. Ingresa código en pantalla de confirmación
4. Puede hacer login

**Ahora (con FastAPI):**
1. Usuario se registra
2. **Ya puede hacer login inmediatamente** (sin confirmación)

**Cambios realizados:**
- ✅ `register_screen.dart:66-71` - Redirige directo a `/login` en lugar de `/confirm-email`
- ✅ Mensaje actualizado: "Registro exitoso. Ya puedes iniciar sesión."

---

## 📋 Estructura de Respuesta de la API

### Login Response (FastAPI)
```json
{
  "access_token": "eyJhbGci...",
  "token_type": "bearer",
  "expires_in": 3600,
  "user": {
    "id": 3,
    "email": "jonitopera777@gmail.com",
    "name": "Jonathan",
    "last_name": "Peña",
    "mother_last_name": "",      // ⚠️ Puede ser null o ""
    "role": "ADMIN",
    "organization_id": 3,
    "created_at": null            // ⚠️ Es null en la API actual
  }
}
```

**Notas:**
- ❌ No incluye `refresh_token`
- ⚠️ `mother_last_name` puede ser vacío o null
- ⚠️ `created_at` es null (la API no lo devuelve)

---

## 🔄 Flujo Actualizado

### Registro
```
Usuario → Formulario de registro
   ↓
POST /auth/register
   ↓
201 Created (usuario creado como ADMIN con su organización)
   ↓
Mensaje: "Registro exitoso. Ya puedes iniciar sesión."
   ↓
Redirige a /login automáticamente (1.5 segundos)
```

### Login
```
Usuario → Formulario de login
   ↓
POST /auth/login
   ↓
200 OK + access_token + user data
   ↓
Guardar token en SharedPreferences
   ↓
Guardar datos de usuario
   ↓
Redirigir a HomeScreen
```

---

## ⚠️ Funcionalidades Deshabilitadas Temporalmente

### 1. Confirmación de Email
**Estado:** ❌ No implementada en API
**Archivos afectados:**
- `lib/screens/auth/confirm_email_screen.dart` - Pantalla no se usa
- `lib/services/api_auth_service.dart:347-384` - Métodos retornan mensaje de "no implementado"

**Si necesitas habilitarla:**
1. Implementa endpoints en FastAPI:
   - `POST /auth/confirm-email`
   - `POST /auth/resend-code`
2. Actualiza `register_screen.dart` para volver a redirigir a `/confirm-email`

### 2. Recuperación de Contraseña
**Estado:** ❌ No implementada en API
**Comportamiento actual:**
```dart
forgotPassword() → Retorna error con mensaje:
"La recuperación de contraseña aún no está disponible. Contacta al administrador."
```

**Si necesitas habilitarla:**
1. Implementa endpoints en FastAPI:
   - `POST /auth/forgot-password`
   - `POST /auth/reset-password`
2. Los métodos en `api_auth_service.dart:367-384` ya están preparados (solo descomentar)

### 3. Refresh Token
**Estado:** ⚠️ Parcialmente implementado
**Actual:** Usa el mismo `access_token` como `refresh_token`

**Para implementar correctamente:**
1. Agrega endpoint en FastAPI: `POST /auth/refresh`
2. Modifica la respuesta de login para incluir `refresh_token`
3. Descomenta código en `api_auth_service.dart:263-295`

---

## 🧪 Cómo Probar

### 1. Registro
```bash
# Asegúrate de que la API esté corriendo
cd C:\Users\jonit\OneDrive\Documentos\GitHub\vigilancia-api
python -m uvicorn app.main:app --reload

# En la app Flutter:
# 1. Ir a pantalla de registro
# 2. Llenar formulario:
#    - Email: test@example.com
#    - Password: Test1234 (mínimo 8 caracteres, mayúsculas, números)
#    - Nombre: Jonathan
#    - Apellido: Peña
# 3. Presionar "Registrar"
# 4. Esperar mensaje: "Registro exitoso. Ya puedes iniciar sesión."
# 5. Automáticamente redirige a login
```

### 2. Login
```bash
# En la pantalla de login:
# 1. Ingresar mismo email y password del registro
# 2. Presionar "Iniciar Sesión"
# 3. Verificar en logs:
#    ✅ Login exitoso: Jonathan Peña
# 4. Debe redirigir a HomeScreen
```

---

## 🔍 Verificar en Logs

### Registro Exitoso
```
📝 Registrando admin via API: test@example.com
🌐 POST http://localhost:8000/auth/register
📥 Response status: 201
✅ Admin registrado exitosamente
```

### Login Exitoso
```
🔐 Login con backend: AuthBackend.api
🔐 Iniciando login via API: test@example.com
🌐 POST http://localhost:8000/auth/login
📦 Respuesta de login recibida
✅ Login exitoso: Jonathan Peña
```

### Si hay error
```
❌ Error en login: [descripción del error]
```

---

## 📝 Notas Importantes

1. **No hay confirmación de email:** El usuario puede hacer login inmediatamente después de registrarse.

2. **Todos los usuarios registrados son ADMIN:** La API crea automáticamente una organización para cada registro. Para usuarios "comunes", deben unirse mediante invitaciones.

3. **mother_last_name es opcional:** Si el usuario no lo llena, se guarda como string vacío.

4. **Sesión persiste:** Los tokens se guardan en SharedPreferences, el usuario permanece logueado al cerrar/abrir la app.

5. **Pantallas no usadas:**
   - `/confirm-email` - Ya no se usa
   - `/forgot-password` - Muestra mensaje de "no disponible"

---

## 🎯 Siguientes Pasos Recomendados

### Inmediato:
- [x] Probar registro completo
- [x] Probar login
- [ ] Probar que la sesión persiste (cerrar/abrir app)

### Corto plazo:
- [ ] Implementar sistema de invitaciones para usuarios comunes
- [ ] Conectar gestión de cámaras con la API
- [ ] Implementar refresh token en el backend

### Mediano plazo:
- [ ] Agregar recuperación de contraseña
- [ ] Implementar confirmación de email (opcional)
- [ ] Reconocimiento facial con la API

---

## 🐛 Problemas Conocidos

### 1. Refresh Token
**Problema:** La API no implementa refresh tokens.
**Impacto:** El token expira después de 1 hora (3600 segundos) y el usuario debe hacer login nuevamente.
**Solución temporal:** Usar el access_token como refresh_token.

### 2. created_at siempre null
**Problema:** La API no devuelve el campo `created_at` en las respuestas.
**Impacto:** Ninguno, Flutter usa `DateTime.now()` como fallback.
**Solución:** Actualizar la API para devolver este campo.

---

## 📚 Referencias

- **Documentación API:** http://localhost:8000/docs
- **Guía de conexión:** `CONEXION_API_GUIDE.md`
- **Código API:** `C:\Users\jonit\OneDrive\Documentos\GitHub\vigilancia-api`
