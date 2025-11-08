// lib/services/join_request_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curso/config/api_config.dart';
import 'package:curso/models/join_request_model.dart';

class JoinRequestService {
  // Key para obtener el token (debe coincidir con api_service.dart)
  static const String _accessTokenKey = 'api_access_token';

  /// Crear una solicitud de unión (requiere token de invitación)
  static Future<JoinRequest> createJoinRequest({
    required String invitationToken,
    String? message,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessTokenKey);

      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/join-requests');

      print('📝 Creando solicitud de unión...');
      print('   URL: $url');
      print('   Token invitación: $invitationToken');

      final response = await http.post(
        url,
        headers: ApiConfig.authHeaders(token),
        body: json.encode({
          'invitation_token': invitationToken,
          'message': message,
        }),
      );

      print('   Status: ${response.statusCode}');
      print('   Response: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final joinRequest = JoinRequest.fromJson(data);
        print('✅ Solicitud creada: ${joinRequest.id}');
        return joinRequest;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Error al crear solicitud');
      }
    } catch (e) {
      print('❌ Error creando solicitud: $e');
      rethrow;
    }
  }

  /// Obtener mis solicitudes de unión
  static Future<List<JoinRequest>> getMyRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessTokenKey);

      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/join-requests/my-requests');

      print('📋 Obteniendo mis solicitudes...');
      print('   URL: $url');

      final response = await http.get(
        url,
        headers: ApiConfig.authHeaders(token),
      );

      print('   Status: ${response.statusCode}');
      print('   Response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final requests = data.map((json) => JoinRequest.fromJson(json)).toList();
        print('✅ ${requests.length} solicitudes obtenidas');
        return requests;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Error al obtener solicitudes');
      }
    } catch (e) {
      print('❌ Error obteniendo mis solicitudes: $e');
      rethrow;
    }
  }

  /// Listar solicitudes pendientes de mi organización (solo Admin)
  static Future<List<JoinRequest>> getPendingRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessTokenKey);

      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/join-requests/pending');

      print('📬 Obteniendo solicitudes pendientes...');
      print('   URL: $url');

      final response = await http.get(
        url,
        headers: ApiConfig.authHeaders(token),
      );

      print('   Status: ${response.statusCode}');
      print('   Response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final requests = data.map((json) => JoinRequest.fromJson(json)).toList();
        print('✅ ${requests.length} solicitudes pendientes');
        return requests;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Error al obtener solicitudes pendientes');
      }
    } catch (e) {
      print('❌ Error obteniendo solicitudes pendientes: $e');
      rethrow;
    }
  }

  /// Listar TODAS las solicitudes de mi organización (solo Admin)
  static Future<List<JoinRequest>> getAllRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessTokenKey);

      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/join-requests/all');

      print('📋 Obteniendo todas las solicitudes...');
      print('   URL: $url');

      final response = await http.get(
        url,
        headers: ApiConfig.authHeaders(token),
      );

      print('   Status: ${response.statusCode}');
      print('   Response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final requests = data.map((json) => JoinRequest.fromJson(json)).toList();
        print('✅ ${requests.length} solicitudes totales');
        return requests;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Error al obtener solicitudes');
      }
    } catch (e) {
      print('❌ Error obteniendo todas las solicitudes: $e');
      rethrow;
    }
  }

  /// Revisar una solicitud: aprobar o rechazar (solo Admin)
  static Future<JoinRequest> reviewRequest({
    required int requestId,
    required bool approved,
    String? adminNotes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessTokenKey);

      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/join-requests/$requestId/review');

      print('${approved ? '✅' : '❌'} Revisando solicitud $requestId...');
      print('   URL: $url');
      print('   Aprobada: $approved');

      final response = await http.post(
        url,
        headers: ApiConfig.authHeaders(token),
        body: json.encode({
          'approved': approved,
          'admin_notes': adminNotes,
        }),
      );

      print('   Status: ${response.statusCode}');
      print('   Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final joinRequest = JoinRequest.fromJson(data);
        print('✅ Solicitud revisada exitosamente');
        return joinRequest;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Error al revisar solicitud');
      }
    } catch (e) {
      print('❌ Error revisando solicitud: $e');
      rethrow;
    }
  }

  /// Aprobar solicitud (helper)
  static Future<JoinRequest> approveRequest(int requestId, {String? notes}) async {
    return reviewRequest(
      requestId: requestId,
      approved: true,
      adminNotes: notes,
    );
  }

  /// Rechazar solicitud (helper)
  static Future<JoinRequest> rejectRequest(int requestId, {String? notes}) async {
    return reviewRequest(
      requestId: requestId,
      approved: false,
      adminNotes: notes,
    );
  }
}
