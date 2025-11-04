# ✅ Fix WebSocket - Problema Resuelto

## 🐛 Problema Encontrado

El endpoint de WebSocket en el backend estaba intentando importar `verify_token` que no existía en `auth_service.py`.

**Error:**
```
ImportError: cannot import name 'verify_token' from 'app.services.auth_service'
```

## ✅ Solución Aplicada

He agregado la función `verify_token` en el archivo:
`vigilancia-api/app/services/auth_service.py`

```python
# Función auxiliar para compatibilidad con endpoints que usan verify_token
def verify_token(token: str) -> dict:
    """
    Alias de decode_token para compatibilidad con endpoints

    Returns:
        dict con los datos del token (user_id, email, role, organization_id)

    Raises:
        JWTError si el token es inválido o ha expirado
    """
    return AuthService.decode_token(token)
```

---

## 🔄 Siguiente Paso: Reiniciar el Backend

### Opción 1: Si el servidor está corriendo en una terminal

1. **Ve a la terminal donde está corriendo FastAPI**
2. **Presiona `Ctrl + C`** para detener el servidor
3. **Reinicia el servidor:**
   ```bash
   cd C:\Users\jonit\OneDrive\Documentos\GitHub\vigilancia-api
   venv\Scripts\activate
   uvicorn app.main:app --reload
   ```

### Opción 2: Si no sabes dónde está corriendo

1. **Busca el proceso de Python:**
   ```bash
   tasklist | findstr python
   ```

2. **Mata el proceso (usa el PID que veas):**
   ```bash
   taskkill /F /PID <número_del_pid>
   ```

3. **Inicia el servidor:**
   ```bash
   cd C:\Users\jonit\OneDrive\Documentos\GitHub\vigilancia-api
   venv\Scripts\activate
   uvicorn app.main:app --reload
   ```

---

## 🧪 Probar que Funciona

### 1. Reinicia el Backend (arriba ↑)

### 2. Hot Reload en Flutter
Si tu app Flutter sigue corriendo, presiona `r` en la terminal de Flutter para hot reload, o reinicia la app:
```bash
flutter run
```

### 3. Logs Esperados

**En FastAPI (Backend):**
```
INFO:     Application startup complete.
INFO:     Uvicorn running on http://127.0.0.1:8000
WebSocket conectado: User 3, Org 3
```

**En Flutter (App):**
```
🔌 Conectando WebSocket...
✅ WebSocket conectado
💓 Ping recibido
```

---

## ✅ Confirmación de que Funciona

Si ves estos logs en Flutter, **ya está funcionando**:
- ✅ `🔌 Conectando WebSocket...`
- ✅ `✅ WebSocket conectado`

Si aún ves el error:
- ❌ Asegúrate de haber reiniciado el backend
- ❌ Verifica que no haya otro proceso de Python corriendo el servidor viejo

---

## 🚀 Probar Notificaciones

Una vez que el WebSocket conecte correctamente, sigue la guía:
**`COMO_PROBAR_NOTIFICACIONES.md`**

Resumen rápido:
1. Backend corriendo ✅
2. App Flutter corriendo ✅
3. WebSocket conectado ✅
4. Iniciar simulación con cURL/Postman:
   ```bash
   curl -X POST "http://localhost:8000/api/detection/simulation/start" \
     -H "Authorization: Bearer TU_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"camera_id": 2, "interval_seconds": 5}'
   ```
5. Ver notificaciones cada 5 segundos 🚨

---

## 📝 Notas

- El cambio ya está aplicado en `auth_service.py`
- Solo necesitas **reiniciar el backend**
- Flutter no necesita cambios, solo hot reload o restart
