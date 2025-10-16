enum CameraStatus {
  active('Activa'),
  inactive('Inactiva'),
  maintenance('Mantenimiento');

  const CameraStatus(this.displayName);
  final String displayName;
}

class CameraModel {
  final String id;
  final String name;
  final String location;
  final CameraStatus status;
  final String rtspUrl;
  final DateTime lastConnection;

  const CameraModel({
    required this.id,
    required this.name,
    required this.location,
    required this.status,
    required this.rtspUrl,
    required this.lastConnection,
  });

  // Para futuro backend
  factory CameraModel.fromJson(Map<String, dynamic> json) {
    return CameraModel(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      status: CameraStatus.values.firstWhere(
        (status) => status.displayName == json['status'],
        orElse: () => CameraStatus.inactive,
      ),
      rtspUrl: json['rtsp_url'],
      lastConnection: DateTime.parse(json['last_connection']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'status': status.displayName,
      'rtsp_url': rtspUrl,
      'last_connection': lastConnection.toIso8601String(),
    };
  }

  CameraModel copyWith({
    String? id,
    String? name,
    String? location,
    CameraStatus? status,
    String? rtspUrl,
    DateTime? lastConnection,
  }) {
    return CameraModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      status: status ?? this.status,
      rtspUrl: rtspUrl ?? this.rtspUrl,
      lastConnection: lastConnection ?? this.lastConnection,
    );
  }
}

class CameraStats {
  final int totalCameras;
  final int activeCameras;
  final bool systemOnline;

  const CameraStats({
    required this.totalCameras,
    required this.activeCameras,
    required this.systemOnline,
  });
}