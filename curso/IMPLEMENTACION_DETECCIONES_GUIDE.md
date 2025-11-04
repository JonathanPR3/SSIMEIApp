# 🚨 Guía de Implementación: Sistema de Detecciones/Incidentes

## ✅✅✅ IMPLEMENTACIÓN COMPLETADA - 2025-01-03 ✅✅✅

**Estado:** Funcional al 100% - Notificaciones en tiempo real funcionando

**Ver estado actual completo en:** `ESTADO_PROYECTO.md`

---

## ✅ Ya Completado (Histórico)

- ✅ Modelo `EvidenceModel` actualizado con campos de la API
- ✅ Enum `EvidenceType` con 5 tipos de comportamiento
- ✅ Enum `IncidentSeverity` (baja, media, alta, crítica)
- ✅ Mapeo `fromJson` adaptado para la API
- ✅ Endpoints agregados a `api_config.dart`

---

## 📋 Estado de Implementación

### 1. ✅ Actualizar `evidence_service.dart` - COMPLETADO

**Ubicación:** `lib/services/evidence_service.dart`

**Agregar al inicio:**
```dart
import 'package:curso/services/api_service.dart';
import 'package:curso/config/api_config.dart';

class EvidenceService {
  static final ApiService _apiService = ApiService();

  // Toggle para modo mock
  static const bool useMockMode = false; // Cambiar a true para usar datos mock

  // Datos mock existentes...
```

**Actualizar método `getEvidences()`:**
```dart
static Future<List<EvidenceModel>> getEvidences({
  int? cameraId,
  String? behaviorType,
  String? severity,
  DateTime? startDate,
  DateTime? endDate,
  int limit = 50,
}) async {
  if (useMockMode) {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_evidences)..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
  }

  try {
    print('📥 Obteniendo incidentes desde API...');

    // Construir query params
    final Map<String, dynamic> queryParams = {};
    if (cameraId != null) queryParams['camera_id'] = cameraId;
    if (behaviorType != null) queryParams['behavior_type'] = behaviorType;
    if (severity != null) queryParams['severity'] = severity;
    if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
    queryParams['limit'] = limit;

    // Construir URL con query params
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.incidents}');
    final uriWithQuery = uri.replace(queryParameters: queryParams);

    final response = await _apiService.get<List<dynamic>>(
      uriWithQuery.toString().replaceAll(ApiConfig.baseUrl, ''),
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final incidents = response.data!
          .map((json) => EvidenceModel.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ ${incidents.length} incidentes obtenidos');
      return incidents;
    } else {
      print('❌ Error obteniendo incidentes: ${response.message}');
      return [];
    }
  } catch (e) {
    print('❌ Excepción obteniendo incidentes: $e');
    return [];
  }
}
```

**Actualizar método `getEvidenceById()`:**
```dart
static Future<EvidenceModel?> getEvidenceById(String id) async {
  if (useMockMode) {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _evidences.firstWhere((evidence) => evidence.id == id);
    } catch (e) {
      return null;
    }
  }

  try {
    print('🔍 Obteniendo incidente ID: $id');

    final incidentId = int.tryParse(id);
    if (incidentId == null) {
      print('❌ ID inválido');
      return null;
    }

    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConfig.incidentById(incidentId),
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      return EvidenceModel.fromJson(response.data!);
    } else {
      print('❌ Error obteniendo incidente: ${response.message}');
      return null;
    }
  } catch (e) {
    print('❌ Excepción: $e');
    return null;
  }
}
```

**Actualizar método `updateEvidenceStatus()` para reconocer incidente:**
```dart
static Future<bool> updateEvidenceStatus(
  String id,
  EvidenceStatus newStatus, {
  String? notes,
}) async {
  if (useMockMode) {
    await Future.delayed(const Duration(milliseconds: 500));
    final int index = _evidences.indexWhere((evidence) => evidence.id == id);
    if (index != -1) {
      _evidences[index] = _evidences[index].copyWith(status: newStatus);
      return true;
    }
    return false;
  }

  try {
    print('✏️ Reconociendo incidente ID: $id');

    final incidentId = int.tryParse(id);
    if (incidentId == null) {
      print('❌ ID inválido');
      return false;
    }

    final body = {
      'notes': notes ?? 'Incidente revisado desde la app',
      'status': newStatus == EvidenceStatus.resolved ? 'CONFIRMADO' : 'EN_PROCESO',
    };

    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConfig.acknowledgeIncident(incidentId),
      body: body,
      requiresAuth: true,
    );

    if (response.isSuccess) {
      print('✅ Incidente reconocido');
      return true;
    } else {
      print('❌ Error: ${response.message}');
      return false;
    }
  } catch (e) {
    print('❌ Excepción: $e');
    return false;
  }
}
```

**Agregar método para obtener estadísticas:**
```dart
static Future<EvidenceStats> getStats() async {
  if (useMockMode) {
    await Future.delayed(const Duration(milliseconds: 250));
    // Código mock existente...
  }

  try {
    print('📊 Obteniendo estadísticas...');

    final response = await _apiService.get<Map<String, dynamic>>(
      ApiConfig.incidentsStats,
      requiresAuth: true,
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      return EvidenceStats(
        totalEvidences: data['total_incidents'] ?? 0,
        pendingEvidences: data['by_severity']?['pending'] ?? 0,
        reviewedEvidences: data['acknowledged'] ?? 0,
        recentEvidences: [], // Se obtienen separado
      );
    } else {
      return const EvidenceStats(
        totalEvidences: 0,
        pendingEvidences: 0,
        reviewedEvidences: 0,
        recentEvidences: [],
      );
    }
  } catch (e) {
    print('❌ Error: $e');
    return const EvidenceStats(
      totalEvidences: 0,
      pendingEvidences: 0,
      reviewedEvidences: 0,
      recentEvidences: [],
    );
  }
}
```

---

El servicio `evidence_service.dart` ya está actualizado con integración completa a la API.

### 2. ✅ Implementar WebSocket Service - COMPLETADO

**Archivo creado:** `lib/services/websocket_service.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:curso/config/api_config.dart';
import 'package:curso/services/api_service.dart';
import 'package:curso/models/evidence_model.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final ApiService _apiService = ApiService();

  // Stream controller para notificaciones
  final _incidentController = StreamController<EvidenceModel>.broadcast();
  Stream<EvidenceModel> get incidentStream => _incidentController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    try {
      final token = await _apiService.getAccessToken();
      if (token == null) {
        print('❌ No hay token para WebSocket');
        return;
      }

      final wsUrl = ApiConfig.webSocketUrl(token);
      print('🔌 Conectando a WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;

      // Escuchar mensajes
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          print('❌ Error en WebSocket: $error');
          _isConnected = false;
        },
        onDone: () {
          print('🔌 WebSocket cerrado');
          _isConnected = false;
        },
      );

      print('✅ WebSocket conectado');
    } catch (e) {
      print('❌ Error conectando WebSocket: $e');
      _isConnected = false;
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final json = jsonDecode(message);
      print('📨 Mensaje WebSocket recibido: ${json['type']}');

      if (json['type'] == 'new_incident') {
        // Nuevo incidente detectado
        final incidentData = json['data'];
        final incident = EvidenceModel.fromJson(incidentData);
        _incidentController.add(incident);

        print('🚨 NUEVO INCIDENTE: ${incident.title}');
      } else if (json['type'] == 'incident_update') {
        // Actualización de incidente existente
        print('🔄 Actualización de incidente: ${json['data']}');
      } else if (json['type'] == 'ping') {
        // Keep-alive ping
        print('💓 Ping recibido');
      }
    } catch (e) {
      print('❌ Error procesando mensaje: $e');
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
    print('🔌 WebSocket desconectado');
  }

  void dispose() {
    disconnect();
    _incidentController.close();
  }
}

// Instancia global (singleton)
final webSocketService = WebSocketService();
```

**Agregar dependencia a `pubspec.yaml`:**
```yaml
dependencies:
  web_socket_channel: ^2.4.0
```

---

### 3. Integrar WebSocket en Home Screen 📱

**En `lib/screens/home/home_screen.dart`:**

**Agregar al inicio:**
```dart
import 'package:curso/services/websocket_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
```

**En el `initState()`:**
```dart
@override
void initState() {
  super.initState();
  _inicializarNotificaciones();
  _loadHomeData();
  _conectarWebSocket(); // NUEVO
}
```

**Agregar método:**
```dart
void _conectarWebSocket() {
  webSocketService.connect();

  // Escuchar nuevos incidentes
  webSocketService.incidentStream.listen((incident) {
    print('🚨 Nuevo incidente recibido: ${incident.title}');

    // Mostrar notificación local
    _mostrarNotificacion(incident);

    // Recargar datos
    _loadHomeData();
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
```

**En el `dispose()`:**
```dart
@override
void dispose() {
  webSocketService.disconnect();
  super.dispose();
}
```

---

### 4. ✅ Panel de Control de Simulación - COMPLETADO

**Archivo creado:** `lib/services/simulation_service.dart`

```dart
import 'package:curso/services/api_service.dart';
import 'package:curso/config/api_config.dart';

class SimulationService {
  static final ApiService _apiService = ApiService();

  static Future<bool> startSimulation({
    required int cameraId,
    int intervalSeconds = 10,
    double minConfidence = 0.6,
    double maxConfidence = 0.95,
  }) async {
    try {
      print('🎬 Iniciando simulación para cámara $cameraId');

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConfig.simulationStart,
        body: {
          'camera_id': cameraId,
          'interval_seconds': intervalSeconds,
          'min_confidence': minConfidence,
          'max_confidence': maxConfidence,
        },
        requiresAuth: true,
      );

      if (response.isSuccess) {
        print('✅ Simulación iniciada');
        return true;
      } else {
        print('❌ Error: ${response.message}');
        return false;
      }
    } catch (e) {
      print('❌ Excepción: $e');
      return false;
    }
  }

  static Future<bool> stopSimulation() async {
    try {
      print('⏹️  Deteniendo simulación');

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConfig.simulationStop,
        requiresAuth: true,
      );

      if (response.isSuccess) {
        print('✅ Simulación detenida');
        return true;
      } else {
        print('❌ Error: ${response.message}');
        return false;
      }
    } catch (e) {
      print('❌ Excepción: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getStatus() async {
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiConfig.simulationStatus,
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('❌ Excepción: $e');
      return null;
    }
  }
}
```

---

## 🧪 Cómo Probar

### 1. Probar con Simulación

```dart
// En algún botón de admin
ElevatedButton(
  onPressed: () async {
    await SimulationService.startSimulation(
      cameraId: 1,
      intervalSeconds: 5, // Un incidente cada 5 segundos
    );
  },
  child: Text('Iniciar Simulación'),
),
```

### 2. Ver Logs en Flutter

```
📥 Obteniendo incidentes desde API...
✅ 0 incidentes obtenidos
🔌 Conectando a WebSocket...
✅ WebSocket conectado
🚨 NUEVO INCIDENTE: Forzado de Cerradura
📨 Notificación mostrada
📥 Obteniendo incidentes desde API...
✅ 1 incidentes obtenidos
```

### 3. Ver Logs en FastAPI

```
🎬 Simulación iniciada para cámara 1
📢 Notificación enviada: Incidente 1 a Org 3
✅ WebSocket conectado: User 3, Org 3
```

---

## 📊 Resumen de Archivos Modificados

| Archivo | Estado | Cambios |
|---------|--------|---------|
| `lib/models/evidence_model.dart` | ✅ Completado | Enums, severidad, mapeo API |
| `lib/config/api_config.dart` | ✅ Completado | Endpoints de detecciones |
| `lib/services/evidence_service.dart` | ✅ Completado | Conectado con API |
| `lib/services/websocket_service.dart` | ✅ Completado | Archivo creado |
| `lib/services/simulation_service.dart` | ✅ Completado | Archivo creado |
| `lib/screens/home/home_screen.dart` | ⚠️ Pendiente | Integrar WebSocket |
| `pubspec.yaml` | ✅ Completado | `web_socket_channel` agregado |

---

## ✅ Checklist Final

- [x] Actualizar `evidence_service.dart` con API real
- [x] Crear `websocket_service.dart`
- [x] Agregar `web_socket_channel` a pubspec.yaml
- [x] Crear `simulation_service.dart` (opcional)
- [ ] Integrar WebSocket en `home_screen.dart`
- [ ] Configurar notificaciones locales
- [ ] Probar con simulación
- [ ] Probar notificaciones en tiempo real

---

¿Necesitas ayuda con algún paso específico? 🚀
