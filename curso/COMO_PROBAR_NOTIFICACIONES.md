# 🧪 Guía: Cómo Probar las Notificaciones en Tiempo Real

## ✅ Pre-requisitos

1. **Instalar dependencia del WebSocket**
   ```bash
   flutter pub get
   ```

2. **API debe estar corriendo**
   - Backend FastAPI en `http://localhost:8000` (o tu URL configurada)
   - Verifica que esté activo visitando: `http://localhost:8000/docs`

3. **Usuario autenticado**
   - Debes estar logged in en la app
   - El token JWT se usa para conectar al WebSocket

---

## 🎯 Método 1: Usar Postman/cURL (Recomendado)

### Paso 1: Obtener tu Token de Acceso

Desde la app Flutter, después de hacer login, revisa los logs:
```
✅ Login exitoso: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

O copia el token desde SharedPreferences/Debug tools.

### Paso 2: Iniciar Simulación via API

**Usando cURL:**
```bash
curl -X POST "http://localhost:8000/api/detection/simulation/start" \
  -H "Authorization: Bearer TU_TOKEN_AQUI" \
  -H "Content-Type: application/json" \
  -d '{
    "camera_id": 1,
    "interval_seconds": 5,
    "min_confidence": 0.6,
    "max_confidence": 0.95
  }'
```

**Usando Postman:**
1. Method: `POST`
2. URL: `http://localhost:8000/api/detection/simulation/start`
3. Headers:
   - `Authorization: Bearer TU_TOKEN_AQUI`
   - `Content-Type: application/json`
4. Body (raw JSON):
   ```json
   {
     "camera_id": 1,
     "interval_seconds": 5,
     "min_confidence": 0.6,
     "max_confidence": 0.95
   }
   ```

### Paso 3: Ver las Notificaciones

**En la App Flutter verás:**
- 📨 Notificación push local con título y descripción
- 📱 SnackBar en la pantalla mostrando "🚨 Nuevo Incidente"
- 🔄 Lista de incidentes se actualiza automáticamente

**En los logs verás:**
```
🔌 Conectando WebSocket...
✅ WebSocket conectado
💓 Ping recibido
📨 Mensaje WebSocket recibido: new_incident
🚨 Nuevo incidente recibido: Forzado de Cerradura
📨 Notificación mostrada: Forzado de Cerradura
🔄 Cargando datos del home...
📥 Obteniendo incidentes desde API...
✅ 1 incidentes obtenidos
```

### Paso 4: Detener Simulación

```bash
curl -X POST "http://localhost:8000/api/detection/simulation/stop" \
  -H "Authorization: Bearer TU_TOKEN_AQUI"
```

---

## 🎯 Método 2: Agregar Botón en la App (Opcional)

Si quieres control desde la app, agrega esto en `SettingsScreen.dart`:

```dart
import 'package:curso/services/simulation_service.dart';

// En el body del widget
ElevatedButton(
  onPressed: () async {
    final result = await SimulationService.startSimulation(
      cameraId: 1,
      intervalSeconds: 5,
    );

    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Simulación iniciada - Un incidente cada 5 seg'),
          backgroundColor: Colors.green,
        ),
      );
    }
  },
  child: const Text('🎬 Iniciar Simulación'),
),

const SizedBox(height: 10),

ElevatedButton(
  onPressed: () async {
    final result = await SimulationService.stopSimulation();
    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏹️  Simulación detenida'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  },
  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
  child: const Text('⏹️  Detener Simulación'),
),
```

---

## 🔍 Verificar Estado de la Simulación

**API Endpoint:**
```bash
curl -X GET "http://localhost:8000/api/detection/simulation/status" \
  -H "Authorization: Bearer TU_TOKEN_AQUI"
```

**Respuesta esperada:**
```json
{
  "is_running": true,
  "camera_id": 1,
  "interval_seconds": 5,
  "incidents_generated": 3,
  "started_at": "2025-01-03T10:30:00"
}
```

---

## 📊 Logs Esperados

### En FastAPI Backend:
```
🎬 Simulación iniciada para cámara 1
📢 Notificación enviada: Incidente 1 a Org 3
✅ WebSocket conectado: User 3, Org 3
📨 Nuevo incidente generado: Forzado de Cerradura
📢 Enviando notificación a 1 clientes
```

### En Flutter App:
```
🔌 Conectando WebSocket...
✅ WebSocket conectado
💓 Ping recibido
📨 Mensaje WebSocket recibido: new_incident
🚨 Nuevo incidente recibido: Forzado de Cerradura
📨 Notificación mostrada: Forzado de Cerradura
🔄 Cargando datos del home...
✅ 1 incidentes obtenidos
```

---

## 🐛 Troubleshooting

### WebSocket no se conecta
**Síntoma:** Logs muestran `❌ Error conectando WebSocket`

**Solución:**
1. Verifica que la API esté corriendo
2. Verifica la URL en `api_config.dart`:
   ```dart
   static const String _baseUrlDevelopment = 'http://localhost:8000';
   ```
3. Si usas emulador Android, usa `http://10.0.2.2:8000`
4. Si usas dispositivo físico, usa tu IP local: `http://192.168.1.X:8000`

### No llegan notificaciones
**Síntoma:** WebSocket conectado pero no aparecen notificaciones

**Solución:**
1. Verifica que `useMockMode = false` en `evidence_service.dart`
2. Revisa que estés usando el mismo usuario/organización que la cámara
3. Verifica en logs del backend si se están generando incidentes

### Token inválido
**Síntoma:** Error 401 Unauthorized

**Solución:**
1. Cierra sesión y vuelve a iniciar sesión
2. Copia el token nuevo de los logs
3. El token JWT expira después de cierto tiempo

---

## 📱 Probar en Diferentes Plataformas

### Android (Emulador)
- Usa `http://10.0.2.2:8000` en `api_config.dart`
- WebSocket: `ws://10.0.2.2:8000/ws/notifications`

### Android (Dispositivo Físico)
- Usa tu IP local: `http://192.168.1.100:8000`
- Tu PC y el dispositivo deben estar en la misma red WiFi
- Verifica firewall no bloquee el puerto 8000

### Web
- WebSocket funciona
- Notificaciones locales NO funcionan (limitación del navegador)
- Solo verás SnackBars y actualización de datos

### iOS
- Similar a Android
- Notificaciones requieren permisos adicionales

---

## ✅ Checklist de Prueba

- [ ] Flutter pub get ejecutado
- [ ] API corriendo en localhost:8000
- [ ] Usuario logged in en la app
- [ ] Token JWT válido obtenido
- [ ] `useMockMode = false` en evidence_service.dart
- [ ] WebSocket conectado (verifica logs)
- [ ] Simulación iniciada via cURL/Postman
- [ ] Notificación push recibida
- [ ] SnackBar mostrado en app
- [ ] Lista de incidentes actualizada
- [ ] Simulación detenida correctamente

---

## 🎥 Flujo Completo de Prueba

1. **Iniciar backend FastAPI**
2. **Abrir app Flutter y hacer login**
3. **Verificar en logs:** `✅ WebSocket conectado`
4. **Desde Postman/cURL:** Iniciar simulación
5. **Esperar 5 segundos** (interval_seconds)
6. **Ver notificación:** Debe aparecer push notification
7. **Ver SnackBar:** Aparece en la app
8. **Ver lista actualizada:** Home screen muestra nuevo incidente
9. **Ir a "Evidencias":** Ver todos los incidentes generados
10. **Detener simulación** desde Postman/cURL

---

## 🚀 Próximos Pasos

Una vez que funcionen las notificaciones:
1. Desplegar API en servidor real
2. Cambiar `useMockMode = false` permanentemente
3. Configurar cámaras reales para detección
4. Las notificaciones funcionarán automáticamente cuando se detecten incidentes reales

---

¿Necesitas ayuda con algún paso? 🚀
