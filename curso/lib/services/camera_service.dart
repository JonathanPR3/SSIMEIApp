import 'package:curso/models/camera_model.dart';

class CameraService {
  // Datos demo - En futuro será reemplazado por API calls
  static List<CameraModel> _cameras = [
    CameraModel(
      id: '1',
      name: 'Cámara Principal',
      location: 'Entrada principal',
      status: CameraStatus.active,
      rtspUrl: 'rtsp://192.168.1.100:554/stream1',
      lastConnection: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    CameraModel(
      id: '2',
      name: 'Cámara Pasillo',
      location: 'Pasillo central',
      status: CameraStatus.inactive,
      rtspUrl: 'rtsp://192.168.1.101:554/stream1',
      lastConnection: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    CameraModel(
      id: '3',
      name: 'Cámara Parking',
      location: 'Estacionamiento',
      status: CameraStatus.active,
      rtspUrl: 'rtsp://192.168.1.102:554/stream1',
      lastConnection: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    CameraModel(
      id: '4',
      name: 'Cámara Trasera',
      location: 'Salida de emergencia',
      status: CameraStatus.maintenance,
      rtspUrl: 'rtsp://192.168.1.103:554/stream1',
      lastConnection: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  // Obtener todas las cámaras
  static Future<List<CameraModel>> getCameras() async {
    // Simular delay de API
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_cameras);
  }

  // Obtener estadísticas
  static Future<CameraStats> getStats() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final activeCameras = _cameras.where((c) => c.status == CameraStatus.active).length;
    
    return CameraStats(
      totalCameras: _cameras.length,
      activeCameras: activeCameras,
      systemOnline: activeCameras > 0,
    );
  }

  // Agregar nueva cámara
  static Future<bool> addCamera({
    required String name,
    required String location,
    required String rtspUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final newCamera = CameraModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      location: location,
      status: CameraStatus.active,
      rtspUrl: rtspUrl,
      lastConnection: DateTime.now(),
    );
    
    _cameras.add(newCamera);
    return true;
  }

  // Eliminar cámara
  static Future<bool> deleteCamera(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _cameras.removeWhere((camera) => camera.id == id);
    return true;
  }

  // Reconectar cámara
  static Future<bool> reconnectCamera(String id) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    final index = _cameras.indexWhere((camera) => camera.id == id);
    if (index != -1) {
      _cameras[index] = _cameras[index].copyWith(
        status: CameraStatus.active,
        lastConnection: DateTime.now(),
      );
      return true;
    }
    return false;
  }

  // Actualizar cámara
  static Future<bool> updateCamera(CameraModel updatedCamera) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    final index = _cameras.indexWhere((camera) => camera.id == updatedCamera.id);
    if (index != -1) {
      _cameras[index] = updatedCamera;
      return true;
    }
    return false;
  }
}