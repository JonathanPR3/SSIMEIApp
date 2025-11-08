import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:curso/config/api_config.dart';
import 'package:curso/services/api_service.dart';
import 'package:curso/models/evidence_model.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final ApiService _apiService = ApiService();

  // Stream controller para notificaciones de nuevos incidentes
  final _incidentController = StreamController<EvidenceModel>.broadcast();
  Stream<EvidenceModel> get incidentStream => _incidentController.stream;

  // Stream controller para notificaciones de cambios en organización
  final _orgChangeController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get orgChangeStream => _orgChangeController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// Conectar al WebSocket del servidor
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

  /// Manejar mensajes recibidos del WebSocket
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
      } else if (json['type'] == 'organization_removed') {
        // Usuario fue removido de la organización
        print('⚠️ USUARIO REMOVIDO DE ORGANIZACIÓN');
        _orgChangeController.add({
          'action': 'removed',
          'message': json['message'] ?? 'Has sido removido de la organización',
        });
      } else if (json['type'] == 'organization_updated') {
        // Cambios en la organización (rol cambiado, etc)
        print('🔄 ORGANIZACIÓN ACTUALIZADA');
        _orgChangeController.add({
          'action': 'updated',
          'message': json['message'] ?? 'Tu organización ha sido actualizada',
          'data': json['data'],
        });
      } else if (json['type'] == 'ping') {
        // Keep-alive ping
        print('💓 Ping recibido');
      }
    } catch (e) {
      print('❌ Error procesando mensaje: $e');
    }
  }

  /// Desconectar del WebSocket
  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
    print('🔌 WebSocket desconectado');
  }

  /// Limpiar recursos
  void dispose() {
    disconnect();
    _incidentController.close();
    _orgChangeController.close();
  }
}

// Instancia global (singleton)
final webSocketService = WebSocketService();
