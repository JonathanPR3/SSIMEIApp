import 'package:curso/services/api_service.dart';
import 'package:curso/config/api_config.dart';

class SimulationService {
  static final ApiService _apiService = ApiService();

  /// Iniciar simulación de detecciones
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
        print('   Cámara: $cameraId');
        print('   Intervalo: ${intervalSeconds}s');
        print('   Confianza: $minConfidence - $maxConfidence');
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

  /// Detener simulación
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

  /// Obtener estado de la simulación
  static Future<Map<String, dynamic>?> getStatus() async {
    try {
      print('📊 Obteniendo estado de simulación...');

      final response = await _apiService.get<Map<String, dynamic>>(
        ApiConfig.simulationStatus,
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        final status = response.data!;
        print('✅ Estado obtenido:');
        print('   Activa: ${status['is_running']}');
        if (status['is_running'] == true) {
          print('   Cámara: ${status['camera_id']}');
          print('   Intervalo: ${status['interval_seconds']}s');
          print('   Incidentes generados: ${status['incidents_generated']}');
        }
        return status;
      }

      return null;
    } catch (e) {
      print('❌ Excepción: $e');
      return null;
    }
  }
}
