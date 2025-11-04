import 'package:curso/models/camera_model.dart';
import 'package:curso/services/api_service.dart';
import 'package:curso/config/api_config.dart';

class CameraService {
  static final ApiService _apiService = ApiService();

  // ==========================================
  // TOGGLE PARA MODO MOCK
  // ==========================================
  static const bool useMockMode = false; // Cambiar a true para usar datos mock

  // Datos mock (solo para desarrollo/testing)
  static List<CameraModel> _mockCameras = [
    CameraModel(
      id: '1',
      name: 'Cámara Principal',
      location: 'Entrada principal',
      status: CameraStatus.active,
      rtspUrl: 'rtsp://192.168.1.100:554/stream1',
      lastConnection: DateTime.now().subtract(const Duration(minutes: 2)),
      ipAddress: '192.168.1.100',
      port: 554,
    ),
    CameraModel(
      id: '2',
      name: 'Cámara Pasillo',
      location: 'Pasillo central',
      status: CameraStatus.inactive,
      rtspUrl: 'rtsp://192.168.1.101:554/stream1',
      lastConnection: DateTime.now().subtract(const Duration(hours: 2)),
      ipAddress: '192.168.1.101',
      port: 554,
    ),
  ];

  // ==========================================
  // MÉTODOS PÚBLICOS
  // ==========================================

  /// Obtener todas las cámaras
  static Future<List<CameraModel>> getCameras() async {
    if (useMockMode) {
      print('⚠️ MODO MOCK: Usando datos de prueba');
      await Future.delayed(const Duration(milliseconds: 300));
      return List.from(_mockCameras);
    }

    try {
      print('📹 Obteniendo cámaras desde API...');

      final response = await _apiService.get<Map<String, dynamic>>(
        ApiConfig.cameras,
        requiresAuth: true,
      );

      print('📥 Response isSuccess: ${response.isSuccess}');
      print('📥 Response data: ${response.data}');
      print('📥 Response message: ${response.message}');

      if (response.isSuccess && response.data != null) {
        final camerasData = response.data!['cameras'] as List;
        print('📊 Cámaras raw data: $camerasData');

        final cameras = camerasData
            .map((cameraJson) => CameraModel.fromJson(cameraJson))
            .toList();

        print('✅ ${cameras.length} cámaras obtenidas');
        return cameras;
      } else {
        print('❌ Error obteniendo cámaras: ${response.message}');
        return [];
      }
    } catch (e) {
      print('❌ Excepción obteniendo cámaras: $e');
      return [];
    }
  }

  /// Obtener estadísticas de cámaras
  static Future<CameraStats> getStats() async {
    if (useMockMode) {
      await Future.delayed(const Duration(milliseconds: 200));
      final activeCameras = _mockCameras.where((c) => c.status == CameraStatus.active).length;
      return CameraStats(
        totalCameras: _mockCameras.length,
        activeCameras: activeCameras,
        systemOnline: activeCameras > 0,
      );
    }

    try {
      print('📊 Obteniendo estadísticas de cámaras...');

      final response = await _apiService.get<Map<String, dynamic>>(
        ApiConfig.cameras,
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        final total = response.data!['total'] as int? ?? 0;
        final cameras = response.data!['cameras'] as List? ?? [];

        // Contar cámaras activas (recientes)
        int activeCameras = 0;
        for (var cameraJson in cameras) {
          final camera = CameraModel.fromJson(cameraJson);
          if (camera.status == CameraStatus.active) {
            activeCameras++;
          }
        }

        return CameraStats(
          totalCameras: total,
          activeCameras: activeCameras,
          systemOnline: activeCameras > 0,
        );
      } else {
        return const CameraStats(
          totalCameras: 0,
          activeCameras: 0,
          systemOnline: false,
        );
      }
    } catch (e) {
      print('❌ Error obteniendo stats: $e');
      return const CameraStats(
        totalCameras: 0,
        activeCameras: 0,
        systemOnline: false,
      );
    }
  }

  /// Agregar nueva cámara
  static Future<bool> addCamera({
    required String name,
    required String location,
    required String rtspUrl,
    String? ipAddress,
    int? port,
    String? username,
    String? password,
    String? description,
  }) async {
    if (useMockMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      final newCamera = CameraModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        location: location,
        status: CameraStatus.active,
        rtspUrl: rtspUrl,
        lastConnection: DateTime.now(),
        ipAddress: ipAddress,
        port: port,
      );
      _mockCameras.add(newCamera);
      return true;
    }

    try {
      print('➕ Creando cámara: $name');

      // Extraer IP y puerto desde RTSP URL si no se proporcionan
      String? finalIp = ipAddress;
      int? finalPort = port;

      if (finalIp == null || finalPort == null) {
        final rtspUri = Uri.tryParse(rtspUrl);
        if (rtspUri != null) {
          finalIp = finalIp ?? rtspUri.host;
          finalPort = finalPort ?? (rtspUri.port != 0 ? rtspUri.port : 554);
        }
      }

      if (finalIp == null || finalPort == null) {
        print('❌ No se pudo determinar IP o puerto');
        return false;
      }

      final body = {
        'alias': name,
        'ip_address': finalIp,
        'port': finalPort,
        'rtsp_url': rtspUrl.isNotEmpty ? rtspUrl : null,
        'username': username,
        'password': password,
        'location': location,
        'description': description,
      };

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConfig.cameras,
        body: body,
        requiresAuth: true,
      );

      if (response.isSuccess) {
        print('✅ Cámara creada exitosamente');
        return true;
      } else {
        print('❌ Error creando cámara: ${response.message}');
        return false;
      }
    } catch (e) {
      print('❌ Excepción creando cámara: $e');
      return false;
    }
  }

  /// Eliminar cámara
  static Future<bool> deleteCamera(String id) async {
    if (useMockMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      _mockCameras.removeWhere((camera) => camera.id == id);
      return true;
    }

    try {
      print('🗑️ Eliminando cámara ID: $id');

      final cameraId = int.tryParse(id);
      if (cameraId == null) {
        print('❌ ID de cámara inválido');
        return false;
      }

      final response = await _apiService.delete(
        ApiConfig.cameraById(cameraId),
        requiresAuth: true,
      );

      if (response.isSuccess) {
        print('✅ Cámara eliminada exitosamente');
        return true;
      } else {
        print('❌ Error eliminando cámara: ${response.message}');
        return false;
      }
    } catch (e) {
      print('❌ Excepción eliminando cámara: $e');
      return false;
    }
  }

  /// Reconectar cámara (test de conexión)
  static Future<bool> reconnectCamera(String id) async {
    if (useMockMode) {
      await Future.delayed(const Duration(milliseconds: 800));
      final index = _mockCameras.indexWhere((camera) => camera.id == id);
      if (index != -1) {
        _mockCameras[index] = _mockCameras[index].copyWith(
          status: CameraStatus.active,
          lastConnection: DateTime.now(),
        );
        return true;
      }
      return false;
    }

    try {
      print('🔄 Probando conexión de cámara ID: $id');

      final cameraId = int.tryParse(id);
      if (cameraId == null) {
        print('❌ ID de cámara inválido');
        return false;
      }

      final response = await _apiService.get<Map<String, dynamic>>(
        '${ApiConfig.cameraById(cameraId)}/test-connection',
        requiresAuth: true,
      );

      if (response.isSuccess) {
        print('✅ Test de conexión exitoso');
        return true;
      } else {
        print('⚠️ Test de conexión falló: ${response.message}');
        return false;
      }
    } catch (e) {
      print('❌ Excepción probando conexión: $e');
      return false;
    }
  }

  /// Actualizar cámara existente
  static Future<bool> updateCamera(CameraModel updatedCamera) async {
    if (useMockMode) {
      await Future.delayed(const Duration(milliseconds: 400));
      final index = _mockCameras.indexWhere((camera) => camera.id == updatedCamera.id);
      if (index != -1) {
        _mockCameras[index] = updatedCamera;
        return true;
      }
      return false;
    }

    try {
      print('✏️ Actualizando cámara ID: ${updatedCamera.id}');

      final cameraId = int.tryParse(updatedCamera.id);
      if (cameraId == null) {
        print('❌ ID de cámara inválido');
        return false;
      }

      final body = {
        'alias': updatedCamera.name,
        'ip_address': updatedCamera.ipAddress,
        'port': updatedCamera.port,
        'rtsp_url': updatedCamera.rtspUrl.isNotEmpty ? updatedCamera.rtspUrl : null,
        'username': updatedCamera.username,
        'location': updatedCamera.location,
        'description': updatedCamera.description,
      };

      final response = await _apiService.put<Map<String, dynamic>>(
        ApiConfig.cameraById(cameraId),
        body: body,
        requiresAuth: true,
      );

      if (response.isSuccess) {
        print('✅ Cámara actualizada exitosamente');
        return true;
      } else {
        print('❌ Error actualizando cámara: ${response.message}');
        return false;
      }
    } catch (e) {
      print('❌ Excepción actualizando cámara: $e');
      return false;
    }
  }

  /// Obtener cámara por ID
  static Future<CameraModel?> getCameraById(String id) async {
    if (useMockMode) {
      await Future.delayed(const Duration(milliseconds: 200));
      return _mockCameras.firstWhere(
        (camera) => camera.id == id,
        orElse: () => _mockCameras.first,
      );
    }

    try {
      print('🔍 Obteniendo cámara ID: $id');

      final cameraId = int.tryParse(id);
      if (cameraId == null) {
        print('❌ ID de cámara inválido');
        return null;
      }

      final response = await _apiService.get<Map<String, dynamic>>(
        ApiConfig.cameraById(cameraId),
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        return CameraModel.fromJson(response.data!);
      } else {
        print('❌ Error obteniendo cámara: ${response.message}');
        return null;
      }
    } catch (e) {
      print('❌ Excepción obteniendo cámara: $e');
      return null;
    }
  }
}