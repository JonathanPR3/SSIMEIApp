// lib/models/user.dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String email;
  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final UserType userType;
  final String? adminId; // ID del administrador al que pertenece (null si es admin)
  final DateTime createdAt;
  final bool isEmailVerified;
  final bool isActive;
  final List<String> accessibleCameraIds; // IDs de cámaras a las que tiene acceso

  const User({
    required this.id,
    required this.email,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.userType,
    this.adminId,
    required this.createdAt,
    this.isEmailVerified = false,
    this.isActive = true,
    this.accessibleCameraIds = const [],
  });

  // Factory constructor para JSON
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  
  // Método para convertir a JSON
  Map<String, dynamic> toJson() => _$UserToJson(this);

  // Getters de conveniencia
  String get nombreCompleto => '$nombre $apellidoPaterno $apellidoMaterno';
  String get nombreCorto => '$nombre $apellidoPaterno';
  bool get isAdmin => userType == UserType.administrator;
  bool get isCommonUser => userType == UserType.common;

  // Constructor para administrador de prueba
  factory User.testAdmin() {
    return User(
      id: 'admin-test-id',
      email: 'admin@ssimei.com',
      nombre: 'Juan',
      apellidoPaterno: 'Pérez',
      apellidoMaterno: 'García',
      userType: UserType.administrator,
      adminId: null, // Los admins no tienen adminId
      createdAt: DateTime.now(),
      isEmailVerified: true,
      isActive: true,
      accessibleCameraIds: [], // Los admins tienen acceso a todas sus cámaras
    );
  }

  // Constructor para usuario común de prueba
  factory User.testCommon({required String adminId}) {
    return User(
      id: 'common-test-id',
      email: 'usuario@ssimei.com',
      nombre: 'María',
      apellidoPaterno: 'López',
      apellidoMaterno: 'Martínez',
      userType: UserType.common,
      adminId: adminId,
      createdAt: DateTime.now(),
      isEmailVerified: true,
      isActive: true,
      accessibleCameraIds: ['camera-1', 'camera-2'], // Acceso limitado
    );
  }

  // Método copyWith para modificaciones inmutables
  User copyWith({
    String? id,
    String? email,
    String? nombre,
    String? apellidoPaterno,
    String? apellidoMaterno,
    UserType? userType,
    String? adminId,
    DateTime? createdAt,
    bool? isEmailVerified,
    bool? isActive,
    List<String>? accessibleCameraIds,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      apellidoPaterno: apellidoPaterno ?? this.apellidoPaterno,
      apellidoMaterno: apellidoMaterno ?? this.apellidoMaterno,
      userType: userType ?? this.userType,
      adminId: adminId ?? this.adminId,
      createdAt: createdAt ?? this.createdAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isActive: isActive ?? this.isActive,
      accessibleCameraIds: accessibleCameraIds ?? this.accessibleCameraIds,
    );
  }

  // Método para agregar acceso a una cámara
  User grantCameraAccess(String cameraId) {
    if (accessibleCameraIds.contains(cameraId)) return this;
    
    return copyWith(
      accessibleCameraIds: [...accessibleCameraIds, cameraId],
    );
  }

  // Método para remover acceso a una cámara
  User revokeCameraAccess(String cameraId) {
    return copyWith(
      accessibleCameraIds: accessibleCameraIds
          .where((id) => id != cameraId)
          .toList(),
    );
  }

  // Verificar si tiene acceso a una cámara
  bool hasAccessToCamera(String cameraId) {
    return isAdmin || accessibleCameraIds.contains(cameraId);
  }

  @override
  String toString() {
    return 'User{id: $id, email: $email, nombreCompleto: $nombreCompleto, type: $userType, isEmailVerified: $isEmailVerified}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}

// Enum para tipos de usuario
@JsonEnum(valueField: 'value')
enum UserType {
  administrator('administrator'),
  common('common');

  const UserType(this.value);
  final String value;

  String get displayName {
    switch (this) {
      case UserType.administrator:
        return 'Administrador';
      case UserType.common:
        return 'Usuario';
    }
  }

  String get description {
    switch (this) {
      case UserType.administrator:
        return 'Puede gestionar cámaras y usuarios';
      case UserType.common:
        return 'Acceso limitado según permisos';
    }
  }
}