# 🚨 Sistema de Detecciones - Estado de Implementación

## ✅ Completado

### 1. Modelos de Datos (`lib/models/evidence_model.dart`)

**Enums implementados:**
- `EvidenceType`: 7 tipos de comportamiento
  - `suspiciousPose` - Pose Sospechosa
  - `unauthorizedPerson` - Persona No Autorizada
  - `forzadoCerradura` - Forzado de Cerradura
  - `agresionPuerta` - Agresión a Puerta
  - `escaladoVentana` - Escalado de Ventana
  - `arrojamientoObjetos` - Arrojamiento de Objetos
  - `vistaProlongada` - Vista Prolongada

- `IncidentSeverity`: 4 niveles de severidad
  - `baja` - Baja
  - `media` - Media
  - `alta` - Alta
  - `critica` - Crítica

**Campos nuevos en `EvidenceModel`:**
```dart
final IncidentSeverity? severity;
final double? confidence;
final bool? isAcknowledged;
final String? videoUrl;
final String? imageUrl;
```

**Mapeo completo API → Flutter:**
- `behavior_type` → `EvidenceType`
- `severity` → `IncidentSeverity`
- `is_acknowledged` → `EvidenceStatus`
- `s3_video_url` → `videoUrl`
- `s3_image_url` → `imageUrl`
- `camera_alias` → `cameraName`

---

### 2. Configuración de API (`lib/config/api_config.dart`)

**Endpoints agregados:**
```dart
// Incidentes
static const String incidents = '/api/detection/incidents';
static String incidentById(int incidentId) => '/api/detection/incidents/$incidentId';
static String acknowledgeIncident(int incidentId) => '/api/detection/incidents/$incidentId/acknowledge';
static const String incidentsStats = '/api/detection/incidents/stats/summary';

// Simulación
static const String simulationStart = '/api/detection/simulation/start';
static const String simulationStop = '/api/detection/simulation/stop';
static const String simulationStatus = '/api/detection/simulation/status';

// WebSocket
static String webSocketUrl(String token) => '${baseUrl.replaceAll('http', 'ws')}/ws/notifications?token=$token';
```

---

### 3. Servicio de Evidencias (`lib/services/evidence_service.dart`)

**Toggle de modo mock:**
```dart
static const bool useMockMode = true; // Cambiar a false para API real
```

**Métodos implementados con API:**

#### `getEvidences()` - ✅ Completado
- Soporta filtros: `cameraId`, `behaviorType`, `severity`, `startDate`, `endDate`, `limit`
- Query params dinámicos
- Mapeo de respuesta API a `EvidenceModel`

#### `getEvidenceById()` - ✅ Completado
- Obtiene incidente específico por ID
- Conversión String → int para ID
- Manejo de errores

#### `getStats()` - ✅ Completado
- Obtiene estadísticas desde `/api/detection/incidents/stats/summary`
- Mapea campos de API: `total_incidents`, `pending`, `acknowledged`
- Combina con lista de incidentes recientes

#### `updateEvidenceStatus()` - ✅ Completado (reconocer incidente)
- Llama a `/api/detection/incidents/{id}/acknowledge`
- Envía notas y status
- Mapeo de status Flutter → API:
  - `resolved` → `'CONFIRMADO'`
  - `reviewed` → `'EN_PROCESO'`

#### `getEvidencesByStatus()` - ✅ Completado
- Filtra incidentes por estado localmente
- Usa `is_acknowledged` de la API

#### `getEvidencesByCamera()` - ✅ Completado
- Filtra por ID de cámara
- Conversión String → int

#### `searchEvidences()` - ✅ Completado
- Búsqueda local en título, descripción, cámara, tipo

#### `deleteEvidence()` - ✅ Completado
- Nota: API no tiene delete, solo en modo mock

---

### 4. WebSocket Service (`lib/services/websocket_service.dart`) - ✅ NUEVO

**Características:**
- Conexión automática con token JWT
- Stream broadcast para notificaciones: `incidentStream`
- Manejo de mensajes:
  - `new_incident` - Nuevo incidente detectado
  - `incident_update` - Actualización de incidente
  - `ping` - Keep-alive
- Manejo de errores y reconexión
- Singleton global: `webSocketService`

**Uso básico:**
```dart
// Conectar
await webSocketService.connect();

// Escuchar nuevos incidentes
webSocketService.incidentStream.listen((incident) {
  print('🚨 Nuevo incidente: ${incident.title}');
  // Mostrar notificación
  // Recargar datos
});

// Desconectar
webSocketService.disconnect();
```

---

### 5. Servicio de Simulación (`lib/services/simulation_service.dart`) - ✅ NUEVO

**Métodos:**

#### `startSimulation()` - ✅ Completado
```dart
await SimulationService.startSimulation(
  cameraId: 1,
  intervalSeconds: 10,
  minConfidence: 0.6,
  maxConfidence: 0.95,
);
```

#### `stopSimulation()` - ✅ Completado
```dart
await SimulationService.stopSimulation();
```

#### `getStatus()` - ✅ Completado
```dart
final status = await SimulationService.getStatus();
print('Simulación activa: ${status['is_running']}');
print('Incidentes generados: ${status['incidents_generated']}');
```

---

### 6. Dependencias (`pubspec.yaml`) - ✅ Completado

**Agregado:**
```yaml
dependencies:
  web_socket_channel: ^2.4.0
```

---

## ⚠️ Pendiente de Implementar

### 1. Integración en `home_screen.dart`

**Lo que falta:**
```dart
import 'package:curso/services/websocket_service.dart';

@override
void initState() {
  super.initState();
  _loadHomeData();
  _conectarWebSocket(); // AGREGAR
}

void _conectarWebSocket() {
  webSocketService.connect();

  webSocketService.incidentStream.listen((incident) {
    print('🚨 Nuevo incidente: ${incident.title}');
    _mostrarNotificacion(incident);
    _loadHomeData(); // Recargar datos
  });
}

Future<void> _mostrarNotificacion(EvidenceModel incident) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'incidents_channel',
    'Incidentes',
    channelDescription: 'Notificaciones de incidentes detectados',
    importance: Importance.high,
    priority: Priority.high,
  );

  const NotificationDetails details = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    incident.id.hashCode,
    '🚨 ${incident.title}',
    incident.description,
    details,
  );
}

@override
void dispose() {
  webSocketService.disconnect();
  super.dispose();
}
```

### 2. Configurar Notificaciones Locales

**En `home_screen.dart` o `main.dart`:**
```dart
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void _inicializarNotificaciones() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}
```

### 3. Agregar Canal de Notificaciones en Android

**En `android/app/src/main/AndroidManifest.xml`:**
```xml
<application>
  <!-- Agregar esto -->
  <meta-data
      android:name="com.google.firebase.messaging.default_notification_channel_id"
      android:value="incidents_channel" />
</application>
```

---

## 🧪 Plan de Pruebas

### Fase 1: Modo Mock (Actual)
```dart
// En evidence_service.dart
static const bool useMockMode = true;
```
✅ Probar que la UI funciona con datos mock

### Fase 2: API Real sin Simulación
```dart
// En evidence_service.dart
static const bool useMockMode = false;
```
1. Hacer login
2. Verificar que carga incidentes existentes (si hay)
3. Ver estadísticas

### Fase 3: Con Simulación
```dart
// En algún botón de admin o debug
ElevatedButton(
  onPressed: () async {
    await SimulationService.startSimulation(
      cameraId: 1,
      intervalSeconds: 5, // Un incidente cada 5 segundos
    );
  },
  child: Text('Iniciar Simulación'),
)
```

**Logs esperados:**
```
🎬 Iniciando simulación para cámara 1
✅ Simulación iniciada
🔌 Conectando a WebSocket...
✅ WebSocket conectado
💓 Ping recibido
📨 Mensaje WebSocket recibido: new_incident
🚨 NUEVO INCIDENTE: Forzado de Cerradura
📥 Obteniendo incidentes desde API...
✅ 1 incidentes obtenidos
```

### Fase 4: Con WebSocket y Notificaciones
1. Integrar WebSocket en home_screen
2. Configurar notificaciones locales
3. Iniciar simulación
4. Verificar que:
   - ✅ Aparecen notificaciones push
   - ✅ La lista se actualiza automáticamente
   - ✅ Los contadores se actualizan

---

## 📊 Resumen

| Componente | Estado | Notas |
|------------|--------|-------|
| Modelos (EvidenceModel) | ✅ 100% | Todos los campos mapeados |
| API Config | ✅ 100% | Endpoints completos |
| EvidenceService | ✅ 100% | Todos los métodos con API |
| WebSocketService | ✅ 100% | Archivo creado |
| SimulationService | ✅ 100% | Archivo creado |
| Dependencias | ✅ 100% | web_socket_channel agregado |
| Home Screen | ⚠️ 0% | Falta integrar WebSocket |
| Notificaciones | ⚠️ 0% | Falta configurar |

**Progreso Total: 75%**

---

## 🚀 Siguiente Paso

El siguiente paso es integrar WebSocket en `home_screen.dart` siguiendo el código de la sección "Pendiente de Implementar" arriba.

Una vez hecho eso, ya se puede probar con la simulación y ver notificaciones en tiempo real.

---

## 📝 Notas Importantes

1. **Modo Mock**: Mantener `useMockMode = true` hasta que la API esté desplegada
2. **WebSocket URL**: Se construye automáticamente cambiando `http` → `ws`
3. **Autenticación**: El token JWT se obtiene automáticamente de `ApiService`
4. **IDs**: Conversión automática String ↔ int en todos los servicios
5. **Severidad**: 4 niveles mapeados desde la API
6. **Tipos de Comportamiento**: 7 tipos totales (5 nuevos + 2 anteriores)
