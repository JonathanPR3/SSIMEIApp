/// Modelo para representar el estado de permisos de una cámara para un usuario
///
/// Usado principalmente en la UI para gestionar qué cámaras tiene/no tiene acceso un usuario
class CameraPermission {
  final int cameraId;
  final String cameraName;
  final String? cameraLocation;
  final bool hasAccess;
  final DateTime? grantedAt;
  final String? grantedByName;

  const CameraPermission({
    required this.cameraId,
    required this.cameraName,
    this.cameraLocation,
    required this.hasAccess,
    this.grantedAt,
    this.grantedByName,
  });

  /// Crea una instancia desde el JSON del backend
  ///
  /// Backend devuelve:
  /// {
  ///   "camera_id": 1,
  ///   "alias": "Cámara Entrada",
  ///   "location": "Entrada principal",
  ///   "granted_at": "2025-11-02T10:00:00", (opcional)
  ///   "granted_by_name": "Admin Demo" (opcional)
  /// }
  factory CameraPermission.fromJson(Map<String, dynamic> json) {
    DateTime? grantedAt;
    if (json['granted_at'] != null) {
      try {
        grantedAt = DateTime.parse(json['granted_at']);
      } catch (e) {
        print('Error parseando granted_at: $e');
      }
    }

    return CameraPermission(
      cameraId: json['camera_id'] as int,
      cameraName: json['alias'] ?? json['camera_alias'] ?? 'Cámara sin nombre',
      cameraLocation: json['location'] ?? json['camera_location'],
      hasAccess: true, // Si viene del endpoint de permisos, es porque tiene acceso
      grantedAt: grantedAt,
      grantedByName: json['granted_by_name'],
    );
  }

  /// Crea una copia con campos modificados
  CameraPermission copyWith({
    int? cameraId,
    String? cameraName,
    String? cameraLocation,
    bool? hasAccess,
    DateTime? grantedAt,
    String? grantedByName,
  }) {
    return CameraPermission(
      cameraId: cameraId ?? this.cameraId,
      cameraName: cameraName ?? this.cameraName,
      cameraLocation: cameraLocation ?? this.cameraLocation,
      hasAccess: hasAccess ?? this.hasAccess,
      grantedAt: grantedAt ?? this.grantedAt,
      grantedByName: grantedByName ?? this.grantedByName,
    );
  }

  @override
  String toString() {
    return 'CameraPermission(cameraId: $cameraId, cameraName: $cameraName, hasAccess: $hasAccess)';
  }
}

/// Modelo para representar una cámara con su estado de permiso para la UI
///
/// Usado en la pantalla de gestión para mostrar checkboxes
class CameraWithPermission {
  final int cameraId;
  final String cameraName;
  final String? cameraLocation;
  final String? ipAddress;
  bool hasPermission; // Mutable para el checkbox

  CameraWithPermission({
    required this.cameraId,
    required this.cameraName,
    this.cameraLocation,
    this.ipAddress,
    this.hasPermission = false,
  });

  /// Crea una instancia desde CameraModel
  factory CameraWithPermission.fromCameraModel(
    dynamic cameraModel, {
    bool hasPermission = false,
  }) {
    return CameraWithPermission(
      cameraId: int.parse(cameraModel.id.toString()),
      cameraName: cameraModel.name,
      cameraLocation: cameraModel.location,
      ipAddress: cameraModel.ipAddress,
      hasPermission: hasPermission,
    );
  }

  @override
  String toString() {
    return 'CameraWithPermission(cameraId: $cameraId, cameraName: $cameraName, hasPermission: $hasPermission)';
  }
}
