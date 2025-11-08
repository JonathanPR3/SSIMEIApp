// lib/models/join_request_model.dart

/// Modelo de Solicitud de Unión
class JoinRequest {
  final int id;
  final int userId;
  final int organizationId;
  final String status; // "PENDING", "APPROVED", "REJECTED"
  final String? message;
  final DateTime createdAt;
  final int? reviewedByUserId;
  final String? reviewedByUserName;
  final DateTime? reviewedAt;
  final String? adminNotes;

  // Información del usuario que solicita
  final String userName;
  final String? userLastName;
  final String userEmail;

  // Información de la organización
  final String? organizationName;

  JoinRequest({
    required this.id,
    required this.userId,
    required this.organizationId,
    required this.status,
    this.message,
    required this.createdAt,
    this.reviewedByUserId,
    this.reviewedByUserName,
    this.reviewedAt,
    this.adminNotes,
    required this.userName,
    this.userLastName,
    required this.userEmail,
    this.organizationName,
  });

  String get userFullName => userLastName != null ? '$userName $userLastName' : userName;

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';

  String get statusDisplay {
    switch (status) {
      case 'PENDING':
        return 'Pendiente';
      case 'APPROVED':
        return 'Aprobada';
      case 'REJECTED':
        return 'Rechazada';
      default:
        return status;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) return 'Hace un momento';
    if (difference.inMinutes < 60) return 'Hace ${difference.inMinutes}m';
    if (difference.inHours < 24) return 'Hace ${difference.inHours}h';
    if (difference.inDays < 7) return 'Hace ${difference.inDays}d';
    if (difference.inDays < 30) return 'Hace ${(difference.inDays / 7).floor()} semanas';
    return 'Hace ${(difference.inDays / 30).floor()} meses';
  }

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    return JoinRequest(
      id: json['id'] ?? json['request_id'],
      userId: json['user_id'],
      organizationId: json['organization_id'],
      status: json['status'] ?? 'PENDING',
      message: json['message'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      reviewedByUserId: json['reviewed_by_user_id'] ?? json['reviewed_by'],
      reviewedByUserName: json['reviewed_by_user_name'],
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'])
          : null,
      adminNotes: json['admin_notes'],
      userName: json['user_name'] ?? json['name'] ?? '',
      userLastName: json['user_last_name'] ?? json['last_name'],
      userEmail: json['user_email'] ?? json['email'] ?? '',
      organizationName: json['organization_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'organization_id': organizationId,
      'status': status,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'reviewed_by_user_id': reviewedByUserId,
      'reviewed_by_user_name': reviewedByUserName,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'admin_notes': adminNotes,
      'user_name': userName,
      'user_last_name': userLastName,
      'user_email': userEmail,
      'organization_name': organizationName,
    };
  }
}
