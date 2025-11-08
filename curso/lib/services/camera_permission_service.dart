import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curso/config/api_config.dart';
import 'package:curso/models/camera_model.dart';

/// Servicio para gestión de permisos de cámaras
///
/// Permite a los ADMIN:
/// - Otorgar permisos a usuarios USER para ver cámaras específicas
/// - Revocar permisos de cámaras
/// - Ver qué cámaras tiene asignadas cada usuario
class CameraPermissionService {
  static const String _accessTokenKey = 'api_access_token';

  /// Obtiene todas las cámaras a las que un usuario tiene acceso
  ///
  /// Endpoint: GET /permissions/user/{userId}/cameras
  /// Solo ADMIN puede consultar permisos de otros usuarios
  static Future<List<CameraModel>> getUserCameras(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessTokenKey);

      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/permissions/user/$userId/cameras');

      print('🔍 Obteniendo cámaras del usuario $userId...');

      final response = await http.get(
        url,
        headers: ApiConfig.authHeaders(token),
      );

      print('📦 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final cameras = data['cameras'] as List<dynamic>?;

        if (cameras == null || cameras.isEmpty) {
          print('ℹ️ Usuario no tiene cámaras asignadas');
          return [];
        }

        final cameraList = cameras.map((cameraJson) {
          final cameraMap = cameraJson as Map<String, dynamic>;

          // El endpoint de permisos devuelve 'camera_id' pero CameraModel espera 'id'
          // Transformar el JSON para que sea compatible
          final transformedJson = {
            'id': cameraMap['camera_id'], // ← Mapear camera_id a id
            'alias': cameraMap['alias'],
            'location': cameraMap['location'],
            'ip_address': cameraMap['ip_address'],
            'port': cameraMap['port'],
            'rtsp_url': cameraMap['rtsp_url'],
            'username': cameraMap['username'],
            'description': cameraMap['description'],
            'created_at': cameraMap['granted_at'], // Usar granted_at como fallback para created_at
          };

          return CameraModel.fromJson(transformedJson);
        }).toList();

        print('✅ ${cameraList.length} cámaras obtenidas para usuario $userId');
        return cameraList;
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permiso para ver las cámaras de este usuario');
      } else if (response.statusCode == 404) {
        throw Exception('Usuario no encontrado');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Error al obtener cámaras del usuario');
      }
    } catch (e) {
      print('❌ Error en getUserCameras: $e');
      rethrow;
    }
  }

  /// Otorga acceso a una cámara a un usuario
  ///
  /// Endpoint: POST /permissions/grant
  /// Solo ADMIN puede otorgar permisos
  static Future<bool> grantCameraAccess({
    required int userId,
    required int cameraId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessTokenKey);

      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/permissions/grant');

      print('➕ Otorgando permiso: usuario $userId, cámara $cameraId');

      final response = await http.post(
        url,
        headers: ApiConfig.authHeaders(token),
        body: json.encode({
          'user_id': userId,
          'camera_id': cameraId,
        }),
      );

      print('📦 Response status: ${response.statusCode}');

      if (response.statusCode == 201) {
        print('✅ Permiso otorgado exitosamente');
        return true;
      } else if (response.statusCode == 409) {
        print('ℹ️ El usuario ya tiene acceso a esta cámara');
        return true; // Ya tiene el permiso, consideramos éxito
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'No se puede otorgar permiso a un ADMIN');
      } else if (response.statusCode == 403) {
        throw Exception('Solo los administradores pueden otorgar permisos');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Error al otorgar permiso');
      }
    } catch (e) {
      print('❌ Error en grantCameraAccess: $e');
      rethrow;
    }
  }

  /// Otorga acceso a múltiples cámaras a un usuario en una sola operación
  ///
  /// Endpoint: POST /permissions/grant-batch
  /// Solo ADMIN puede otorgar permisos
  static Future<Map<String, dynamic>> grantBatchCameraAccess({
    required int userId,
    required List<int> cameraIds,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessTokenKey);

      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/permissions/grant-batch');

      print('➕ Otorgando permisos en batch: usuario $userId, ${cameraIds.length} cámaras');

      final response = await http.post(
        url,
        headers: ApiConfig.authHeaders(token),
        body: json.encode({
          'user_id': userId,
          'camera_ids': cameraIds,
        }),
      );

      print('📦 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        print('✅ Batch completado: ${data['total_granted']} permisos otorgados');
        return data;
      } else if (response.statusCode == 403) {
        throw Exception('Solo los administradores pueden otorgar permisos');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Error al otorgar permisos');
      }
    } catch (e) {
      print('❌ Error en grantBatchCameraAccess: $e');
      rethrow;
    }
  }

  /// Revoca el acceso a una cámara de un usuario
  ///
  /// Endpoint: DELETE /permissions/revoke?user_id=X&camera_id=Y
  /// Solo ADMIN puede revocar permisos
  static Future<bool> revokeCameraAccess({
    required int userId,
    required int cameraId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessTokenKey);

      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/permissions/revoke')
          .replace(queryParameters: {
        'user_id': userId.toString(),
        'camera_id': cameraId.toString(),
      });

      print('➖ Revocando permiso: usuario $userId, cámara $cameraId');

      final response = await http.delete(
        url,
        headers: ApiConfig.authHeaders(token),
      );

      print('📦 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Permiso revocado exitosamente');
        return true;
      } else if (response.statusCode == 404) {
        print('ℹ️ El permiso no existe o ya fue revocado');
        return true; // No existe, consideramos éxito
      } else if (response.statusCode == 403) {
        throw Exception('Solo los administradores pueden revocar permisos');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Error al revocar permiso');
      }
    } catch (e) {
      print('❌ Error en revokeCameraAccess: $e');
      rethrow;
    }
  }

  /// Revoca TODOS los permisos de cámaras de un usuario
  ///
  /// Endpoint: DELETE /permissions/revoke-all/{userId}
  /// Solo ADMIN puede revocar permisos
  static Future<int> revokeAllUserPermissions(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessTokenKey);

      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/permissions/revoke-all/$userId');

      print('🗑️ Revocando TODOS los permisos del usuario $userId');

      final response = await http.delete(
        url,
        headers: ApiConfig.authHeaders(token),
      );

      print('📦 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final revokedCount = data['revoked_count'] as int? ?? 0;
        print('✅ $revokedCount permisos revocados');
        return revokedCount;
      } else if (response.statusCode == 403) {
        throw Exception('Solo los administradores pueden revocar permisos');
      } else if (response.statusCode == 404) {
        throw Exception('Usuario no encontrado');
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Error al revocar permisos');
      }
    } catch (e) {
      print('❌ Error en revokeAllUserPermissions: $e');
      rethrow;
    }
  }

  /// Verifica si un usuario tiene acceso a una cámara específica
  ///
  /// Endpoint: GET /permissions/check-access?user_id=X&camera_id=Y
  /// ADMIN puede verificar cualquier usuario, USER solo puede verificar su propio acceso
  static Future<bool> checkCameraAccess({
    required int userId,
    required int cameraId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessTokenKey);

      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/permissions/check-access')
          .replace(queryParameters: {
        'user_id': userId.toString(),
        'camera_id': cameraId.toString(),
      });

      print('🔍 Verificando acceso: usuario $userId, cámara $cameraId');

      final response = await http.get(
        url,
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final hasAccess = data['has_access'] as bool? ?? false;
        print('✅ Acceso verificado: $hasAccess');
        return hasAccess;
      } else {
        print('⚠️ Error al verificar acceso');
        return false;
      }
    } catch (e) {
      print('❌ Error en checkCameraAccess: $e');
      return false;
    }
  }
}
