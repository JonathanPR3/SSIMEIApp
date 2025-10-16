// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as String,
      email: json['email'] as String,
      nombre: json['nombre'] as String,
      apellidoPaterno: json['apellidoPaterno'] as String,
      apellidoMaterno: json['apellidoMaterno'] as String,
      userType: $enumDecode(_$UserTypeEnumMap, json['userType']),
      adminId: json['adminId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      accessibleCameraIds: (json['accessibleCameraIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'nombre': instance.nombre,
      'apellidoPaterno': instance.apellidoPaterno,
      'apellidoMaterno': instance.apellidoMaterno,
      'userType': _$UserTypeEnumMap[instance.userType]!,
      'adminId': instance.adminId,
      'createdAt': instance.createdAt.toIso8601String(),
      'isEmailVerified': instance.isEmailVerified,
      'isActive': instance.isActive,
      'accessibleCameraIds': instance.accessibleCameraIds,
    };

const _$UserTypeEnumMap = {
  UserType.administrator: 'administrator',
  UserType.common: 'common',
};
