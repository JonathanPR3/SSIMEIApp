enum FaceStatus {
  active('Activo'),
  inactive('Inactivo'),
  processing('Procesando');

  const FaceStatus(this.displayName);
  final String displayName;
}

class FaceKeypoints {
  final List<Map<String, double>> landmarks;
  final String encoding;
  final double confidence;

  const FaceKeypoints({
    required this.landmarks,
    required this.encoding,
    required this.confidence,
  });

  factory FaceKeypoints.fromJson(Map<String, dynamic> json) {
    return FaceKeypoints(
      landmarks: (json['landmarks'] as List<dynamic>)
          .map((landmark) => Map<String, double>.from(landmark))
          .toList(),
      encoding: json['encoding'],
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'landmarks': landmarks,
      'encoding': encoding,
      'confidence': confidence,
    };
  }
}

class RegisteredFace {
  final String id;
  final String name;
  final String relationship;
  final String imageUrl;
  final FaceKeypoints keypoints;
  final FaceStatus status;
  final DateTime registeredAt;
  final DateTime? lastSeen;

  const RegisteredFace({
    required this.id,
    required this.name,
    required this.relationship,
    required this.imageUrl,
    required this.keypoints,
    required this.status,
    required this.registeredAt,
    this.lastSeen,
  });

  factory RegisteredFace.fromJson(Map<String, dynamic> json) {
    return RegisteredFace(
      id: json['id'],
      name: json['name'],
      relationship: json['relationship'],
      imageUrl: json['image_url'],
      keypoints: FaceKeypoints.fromJson(json['keypoints']),
      status: FaceStatus.values.firstWhere(
        (status) => status.displayName == json['status'],
        orElse: () => FaceStatus.active,
      ),
      registeredAt: DateTime.parse(json['registered_at']),
      lastSeen: json['last_seen'] != null 
          ? DateTime.parse(json['last_seen']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'image_url': imageUrl,
      'keypoints': keypoints.toJson(),
      'status': status.displayName,
      'registered_at': registeredAt.toIso8601String(),
      'last_seen': lastSeen?.toIso8601String(),
    };
  }

  RegisteredFace copyWith({
    String? id,
    String? name,
    String? relationship,
    String? imageUrl,
    FaceKeypoints? keypoints,
    FaceStatus? status,
    DateTime? registeredAt,
    DateTime? lastSeen,
  }) {
    return RegisteredFace(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      imageUrl: imageUrl ?? this.imageUrl,
      keypoints: keypoints ?? this.keypoints,
      status: status ?? this.status,
      registeredAt: registeredAt ?? this.registeredAt,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}