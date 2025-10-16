// lib/models/user_group.dart
import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'user_group.g.dart';

@JsonSerializable()
class UserGroup {
  final String id;
  final String adminId;
  final String groupName; // "Familia Pérez", "Casa Principal", etc.
  final List<String> memberIds; // IDs de usuarios comunes en el grupo
  final List<String> cameraIds; // IDs de cámaras del grupo
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const UserGroup({
    required this.id,
    required this.adminId,
    required this.groupName,
    this.memberIds = const [],
    this.cameraIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory UserGroup.fromJson(Map<String, dynamic> json) => _$UserGroupFromJson(json);
  Map<String, dynamic> toJson() => _$UserGroupToJson(this);

  // Getters de conveniencia
  int get memberCount => memberIds.length;
  int get cameraCount => cameraIds.length;

  // Verificar si un usuario es miembro del grupo
  bool isMember(String userId) {
    return memberIds.contains(userId);
  }

  // Verificar si una cámara pertenece al grupo
  bool hasCamera(String cameraId) {
    return cameraIds.contains(cameraId);
  }

  // Agregar miembro al grupo
  UserGroup addMember(String userId) {
    if (memberIds.contains(userId)) return this;
    
    return copyWith(
      memberIds: [...memberIds, userId],
      updatedAt: DateTime.now(),
    );
  }

  // Remover miembro del grupo
  UserGroup removeMember(String userId) {
    return copyWith(
      memberIds: memberIds.where((id) => id != userId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  // Agregar cámara al grupo
  UserGroup addCamera(String cameraId) {
    if (cameraIds.contains(cameraId)) return this;
    
    return copyWith(
      cameraIds: [...cameraIds, cameraId],
      updatedAt: DateTime.now(),
    );
  }

  // Remover cámara del grupo
  UserGroup removeCamera(String cameraId) {
    return copyWith(
      cameraIds: cameraIds.where((id) => id != cameraId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  UserGroup copyWith({
    String? id,
    String? adminId,
    String? groupName,
    List<String>? memberIds,
    List<String>? cameraIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return UserGroup(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      groupName: groupName ?? this.groupName,
      memberIds: memberIds ?? this.memberIds,
      cameraIds: cameraIds ?? this.cameraIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}