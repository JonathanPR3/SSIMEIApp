// lib/models/invitation_model.dart

/// Modelo de Invitación
class Invitation {
  final int id;
  final int? organizationId;  // Nullable - no siempre viene en las respuestas
  final String? token;  // Nullable - solo viene al crear
  final String status; // "PENDING", "ACCEPTED", "EXPIRED", "REVOKED"
  final DateTime createdAt;
  final DateTime expiresAt;
  final int createdByUserId;
  final String? createdByUserName;
  final String? invitationLink;

  Invitation({
    required this.id,
    this.organizationId,  // Ahora opcional
    this.token,  // Ahora opcional
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.createdByUserId,
    this.createdByUserName,
    this.invitationLink,
  });

  bool get isActive => status == 'PENDING' && DateTime.now().isBefore(expiresAt);
  bool get isExpired => status == 'EXPIRED' || DateTime.now().isAfter(expiresAt);

  String get statusDisplay {
    if (isExpired) return 'Expirada';
    switch (status) {
      case 'PENDING':
        return 'Activa';
      case 'ACCEPTED':
        return 'Aceptada';
      case 'REVOKED':
        return 'Revocada';
      default:
        return status;
    }
  }

  Duration get timeUntilExpiration {
    return expiresAt.difference(DateTime.now());
  }

  String get timeUntilExpirationDisplay {
    if (isExpired) return 'Expirada';

    final duration = timeUntilExpiration;
    if (duration.inMinutes < 1) return 'Menos de 1 minuto';
    if (duration.inHours < 1) return '${duration.inMinutes}m';
    return '${duration.inHours}h ${duration.inMinutes % 60}m';
  }

  factory Invitation.fromJson(Map<String, dynamic> json) {
    // Parsear invited_by (puede ser un objeto o null)
    int? userId;
    String? userName;

    if (json['invited_by'] != null && json['invited_by'] is Map) {
      final invitedBy = json['invited_by'] as Map<String, dynamic>;
      userId = invitedBy['user_id'] as int?;
      userName = invitedBy['name'] as String?;
    }

    return Invitation(
      id: json['id'] ?? json['invitation_id'],
      organizationId: json['organization_id'],
      token: json['token'] ?? '',
      status: (json['status'] as String?)?.toUpperCase() ?? 'PENDING',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : DateTime.now().add(const Duration(minutes: 10)),
      createdByUserId: userId ?? json['created_by_user_id'] ?? 0,
      createdByUserName: userName ?? json['created_by_user_name'],
      invitationLink: json['invitation_link'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'token': token,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'created_by_user_id': createdByUserId,
      'created_by_user_name': createdByUserName,
      'invitation_link': invitationLink,
    };
  }
}

/// Modelo para verificar una invitación
class InvitationVerification {
  final bool valid;
  final String? organizationName;
  final int? organizationId;
  final String? message;

  InvitationVerification({
    required this.valid,
    this.organizationName,
    this.organizationId,
    this.message,
  });

  factory InvitationVerification.fromJson(Map<String, dynamic> json) {
    return InvitationVerification(
      valid: json['valid'] ?? false,
      organizationName: json['organization_name'],
      organizationId: json['organization_id'],
      message: json['message'],
    );
  }
}
