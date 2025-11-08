// lib/models/organization_model.dart

/// Modelo de Organización
class Organization {
  final int id;
  final String name;
  final int adminUserId;
  final String? description;
  final DateTime createdAt;
  final List<OrganizationMember>? members;
  final int? totalMembers;
  final int? totalCameras;

  Organization({
    required this.id,
    required this.name,
    required this.adminUserId,
    this.description,
    required this.createdAt,
    this.members,
    this.totalMembers,
    this.totalCameras,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] ?? json['organization_id'],
      name: json['name'] ?? json['organization_name'] ?? 'Mi Organización',
      adminUserId: json['admin_user_id'] ?? 0,
      description: json['description'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      members: json['members'] != null
          ? (json['members'] as List)
              .map((m) => OrganizationMember.fromJson(m))
              .toList()
          : null,
      totalMembers: json['total_members'],
      totalCameras: json['total_cameras'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'admin_user_id': adminUserId,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'members': members?.map((m) => m.toJson()).toList(),
      'total_members': totalMembers,
      'total_cameras': totalCameras,
    };
  }
}

/// Modelo de Miembro de Organización
class OrganizationMember {
  final int userId;
  final String name;
  final String? lastName;
  final String? motherLastName;
  final String email;
  final String role; // "ADMIN" o "USER"
  final DateTime joinedAt;
  final DateTime? lastActive;

  OrganizationMember({
    required this.userId,
    required this.name,
    this.lastName,
    this.motherLastName,
    required this.email,
    required this.role,
    required this.joinedAt,
    this.lastActive,
  });

  String get fullName {
    final parts = [name, lastName, motherLastName].where((s) => s != null && s.isNotEmpty).toList();
    return parts.join(' ');
  }

  bool get isAdmin => role == 'ADMIN';

  factory OrganizationMember.fromJson(Map<String, dynamic> json) {
    return OrganizationMember(
      userId: json['user_id'] ?? json['id'],
      name: json['name'] ?? '',
      lastName: json['last_name'],
      motherLastName: json['mother_last_name'],
      email: json['email'] ?? '',
      role: json['role'] ?? 'USER',
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'])
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      lastActive: json['last_active'] != null
          ? DateTime.parse(json['last_active'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'last_name': lastName,
      'mother_last_name': motherLastName,
      'email': email,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
      'last_active': lastActive?.toIso8601String(),
    };
  }
}
