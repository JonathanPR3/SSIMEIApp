enum EvidenceType {
  suspiciousPose('Pose Sospechosa', 'pose_sospechosa'),
  unauthorizedPerson('Persona No Autorizada', 'persona_no_autorizada');

  const EvidenceType(this.displayName, this.code);
  final String displayName;
  final String code;
}

enum EvidenceStatus {
  pending('Pendiente'),
  reviewed('Revisada'),
  resolved('Resuelta');

  const EvidenceStatus(this.displayName);
  final String displayName;
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
  });

  factory EvidenceModel.fromJson(Map<String, dynamic> json) {
    return EvidenceModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: EvidenceType.values.firstWhere(
        (type) => type.code == json['type'],
        orElse: () => EvidenceType.suspiciousPose,
      ),
      status: EvidenceStatus.values.firstWhere(
        (status) => status.displayName == json['status'],
        orElse: () => EvidenceStatus.pending,
      ),
      cameraId: json['camera_id'],
      cameraName: json['camera_name'],
      detectedAt: DateTime.parse(json['detected_at']),
      videoFragments: (json['video_fragments'] as List<dynamic>?)
          ?.map((fragment) => VideoFragment.fromJson(fragment))
          .toList() ?? [],
      metadata: json['metadata'],
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