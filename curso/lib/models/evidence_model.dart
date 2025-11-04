// Mapeo de tipos de comportamiento de la API
enum EvidenceType {
  suspiciousPose('Pose Sospechosa', 'pose_sospechosa'),
  unauthorizedPerson('Persona No Autorizada', 'persona_no_autorizada'),
  // Nuevos tipos de la API
  forzadoCerradura('Forzado de Cerradura', 'forzado_cerradura'),
  agresionPuerta('Agresión a Puerta', 'agresion_puerta'),
  escaladoVentana('Escalado de Ventana', 'escalado_ventana'),
  arrojamientoObjetos('Arrojamiento de Objetos', 'arrojamiento_objetos'),
  vistaProlongada('Vista Prolongada', 'vista_prolongada');

  const EvidenceType(this.displayName, this.code);
  final String displayName;
  final String code;

  // Mapear desde el BehaviorType de la API
  static EvidenceType fromBehaviorType(String behaviorType) {
    switch (behaviorType.toLowerCase()) {
      case 'forzado_cerradura':
        return EvidenceType.forzadoCerradura;
      case 'agresion_puerta':
        return EvidenceType.agresionPuerta;
      case 'escalado_ventana':
        return EvidenceType.escaladoVentana;
      case 'arrojamiento_objetos':
        return EvidenceType.arrojamientoObjetos;
      case 'vista_prolongada':
        return EvidenceType.vistaProlongada;
      case 'persona_no_autorizada':
        return EvidenceType.unauthorizedPerson;
      case 'pose_sospechosa':
        return EvidenceType.suspiciousPose;
      // Valores genéricos o desconocidos del backend
      case 'otro':
      case 'unknown':
      case '':
      default:
        // Si viene "otro" o cualquier valor desconocido, usar suspiciousPose como default
        return EvidenceType.suspiciousPose;
    }
  }
}

enum EvidenceStatus {
  pending('Pendiente'),
  reviewed('Revisada'),
  resolved('Resuelta');

  const EvidenceStatus(this.displayName);
  final String displayName;
}

// Severidad del incidente (de la API)
enum IncidentSeverity {
  baja('Baja', 'baja'),
  media('Media', 'media'),
  alta('Alta', 'alta'),
  critica('Crítica', 'critica');

  const IncidentSeverity(this.displayName, this.code);
  final String displayName;
  final String code;

  static IncidentSeverity fromString(String severity) {
    switch (severity.toLowerCase()) {
      case 'baja':
        return IncidentSeverity.baja;
      case 'media':
        return IncidentSeverity.media;
      case 'alta':
        return IncidentSeverity.alta;
      case 'critica':
        return IncidentSeverity.critica;
      default:
        return IncidentSeverity.media;
    }
  }
}

class VideoFragment {
  final String id;
  final String videoUrl;
  final String thumbnailUrl;
  final DateTime timestamp;
  final Duration duration;
  final String description;

  const VideoFragment({
    required this.id,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.timestamp,
    required this.duration,
    required this.description,
  });

  factory VideoFragment.fromJson(Map<String, dynamic> json) {
    return VideoFragment(
      id: json['id'],
      videoUrl: json['video_url'],
      thumbnailUrl: json['thumbnail_url'],
      timestamp: DateTime.parse(json['timestamp']),
      duration: Duration(seconds: json['duration_seconds']),
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'timestamp': timestamp.toIso8601String(),
      'duration_seconds': duration.inSeconds,
      'description': description,
    };
  }
}

class EvidenceModel {
  final String id;
  final String title;
  final String description;
  final EvidenceType type;
  final EvidenceStatus status;
  final String cameraId;
  final String cameraName;
  final DateTime detectedAt;
  final List<VideoFragment> videoFragments;
  final Map<String, dynamic>? metadata;
  // Nuevos campos de la API
  final IncidentSeverity? severity;
  final double? confidence;
  final bool? isAcknowledged;
  final String? videoUrl;
  final String? imageUrl;

  const EvidenceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.cameraId,
    required this.cameraName,
    required this.detectedAt,
    required this.videoFragments,
    this.metadata,
    this.severity,
    this.confidence,
    this.isAcknowledged,
    this.videoUrl,
    this.imageUrl,
  });

  // Factory para mapear desde la API (/api/detection/incidents)
  factory EvidenceModel.fromJson(Map<String, dynamic> json) {
    // Determinar el tipo basado en behavior_type (de la API) o type (local)
    EvidenceType type;
    if (json.containsKey('behavior_type')) {
      type = EvidenceType.fromBehaviorType(json['behavior_type']);
    } else if (json.containsKey('incident_type')) {
      type = EvidenceType.fromBehaviorType(json['incident_type']);
    } else {
      type = EvidenceType.values.firstWhere(
        (t) => t.code == json['type'],
        orElse: () => EvidenceType.suspiciousPose,
      );
    }

    // Determinar status basado en is_acknowledged
    EvidenceStatus status;
    if (json.containsKey('is_acknowledged')) {
      status = json['is_acknowledged'] == true || json['is_acknowledged'] == 1
          ? EvidenceStatus.reviewed
          : EvidenceStatus.pending;
    } else if (json.containsKey('status')) {
      status = EvidenceStatus.values.firstWhere(
        (s) => s.displayName == json['status'],
        orElse: () => EvidenceStatus.pending,
      );
    } else {
      status = EvidenceStatus.pending;
    }

    // Parsear timestamp
    DateTime detectedAt;
    try {
      detectedAt = DateTime.parse(json['timestamp'] ?? json['detected_at']);
    } catch (e) {
      detectedAt = DateTime.now();
    }

    // Severidad
    IncidentSeverity? severity;
    if (json.containsKey('severity') && json['severity'] != null) {
      severity = IncidentSeverity.fromString(json['severity']);
    }

    // Generar título basado en lo que venga del backend
    String title;
    if (json.containsKey('title') && json['title'] != null && json['title'].toString().isNotEmpty) {
      title = json['title'];
    } else {
      // Si no hay título, usar el tipo de evidencia o generar uno de la descripción
      title = type.displayName;
    }

    return EvidenceModel(
      id: json['id'].toString(),
      title: title,
      description: json['description'] ?? 'Incidente detectado',
      type: type,
      status: status,
      cameraId: json['camera_id'].toString(),
      cameraName: json['camera_alias'] ?? json['camera_name'] ?? 'Cámara ${json['camera_id']}',
      detectedAt: detectedAt,
      videoFragments: (json['video_fragments'] as List<dynamic>?)
          ?.map((fragment) => VideoFragment.fromJson(fragment))
          .toList() ?? [],
      metadata: json['metadata'],
      severity: severity,
      confidence: json['confidence']?.toDouble(),
      isAcknowledged: json['is_acknowledged'] == true || json['is_acknowledged'] == 1,
      videoUrl: json['s3_video_url'] ?? json['video_url'],
      imageUrl: json['s3_image_url'] ?? json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.code,
      'status': status.displayName,
      'camera_id': cameraId,
      'camera_name': cameraName,
      'detected_at': detectedAt.toIso8601String(),
      'video_fragments': videoFragments.map((fragment) => fragment.toJson()).toList(),
      'metadata': metadata,
    };
  }

  EvidenceModel copyWith({
    String? id,
    String? title,
    String? description,
    EvidenceType? type,
    EvidenceStatus? status,
    String? cameraId,
    String? cameraName,
    DateTime? detectedAt,
    List<VideoFragment>? videoFragments,
    Map<String, dynamic>? metadata,
  }) {
    return EvidenceModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      cameraId: cameraId ?? this.cameraId,
      cameraName: cameraName ?? this.cameraName,
      detectedAt: detectedAt ?? this.detectedAt,
      videoFragments: videoFragments ?? this.videoFragments,
      metadata: metadata ?? this.metadata,
    );
  }
}

class EvidenceStats {
  final int totalEvidences;
  final int pendingEvidences;
  final int reviewedEvidences;
  final List<EvidenceModel> recentEvidences;

  const EvidenceStats({
    required this.totalEvidences,
    required this.pendingEvidences,
    required this.reviewedEvidences,
    required this.recentEvidences,
  });
}