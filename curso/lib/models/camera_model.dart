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
  final String? ipAddress;  // NUEVO: de la API
  final int? port;  // NUEVO: de la API
  final String? username;  // NUEVO: de la API
  final String? description;  // NUEVO: de la API

  const CameraModel({
    required this.id,
    required this.name,
    required this.location,
    required this.status,
    required this.rtspUrl,
    required this.lastConnection,
    this.ipAddress,
    this.port,
    this.username,
    this.description,
  });

  // Mapeo desde la API FastAPI
  factory CameraModel.fromJson(Map<String, dynamic> json) {
    // Construir RTSP URL si no viene completa
    String rtspUrl = json['rtsp_url'] ?? '';
    if (rtspUrl.isEmpty && json['ip_address'] != null && json['port'] != null) {
      final ip = json['ip_address'];
      final port = json['port'];
      final username = json['username'];

      if (username != null && username.isNotEmpty) {
        rtspUrl = 'rtsp://$username@$ip:$port/stream';
      } else {
        rtspUrl = 'rtsp://$ip:$port/stream';
      }
    }

    // Determinar status basado en created_at (si fue creada hace menos de 5 minutos, considerarla activa)
    CameraStatus status = CameraStatus.active;
    DateTime lastConnection = DateTime.now();

    if (json['created_at'] != null) {
      try {
        lastConnection = DateTime.parse(json['created_at']);
        final difference = DateTime.now().difference(lastConnection);

        if (difference.inHours > 24) {
          status = CameraStatus.inactive;
        }
      } catch (e) {
        print('Error parseando created_at: $e');
      }
    }

    return CameraModel(
      id: json['id'].toString(), // Convertir int a String
      name: json['alias'] ?? 'Cámara sin nombre',  // API usa 'alias' en lugar de 'name'
      location: json['location'] ?? 'Sin ubicación',
      status: status,
      rtspUrl: rtspUrl,
      lastConnection: lastConnection,
      ipAddress: json['ip_address'],
      port: json['port'],
      username: json['username'],
      description: json['description'],
    );
  }

  // Mapeo hacia la API FastAPI
  Map<String, dynamic> toJson() {
    return {
      'alias': name,
      'location': location,
      'ip_address': ipAddress,
      'port': port,
      'rtsp_url': rtspUrl.isNotEmpty ? rtspUrl : null,
      'username': username,
      'description': description,
    };
  }

  // Mapearhacia la API para crear (sin id)
  Map<String, dynamic> toCreateJson() {
    return {
      'alias': name,
      'ip_address': ipAddress ?? '',
      'port': port ?? 554,
      'rtsp_url': rtspUrl.isNotEmpty ? rtspUrl : null,
      'username': username,
      'location': location,
      'description': description,
    };
  }

  CameraModel copyWith({
    String? id,
    String? name,
    String? location,
    CameraStatus? status,
    String? rtspUrl,
    DateTime? lastConnection,
    String? ipAddress,
    int? port,
    String? username,
    String? description,
  }) {
    return CameraModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      status: status ?? this.status,
      rtspUrl: rtspUrl ?? this.rtspUrl,
      lastConnection: lastConnection ?? this.lastConnection,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      username: username ?? this.username,
      description: description ?? this.description,
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