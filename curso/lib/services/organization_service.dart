// lib/services/organization_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curso/config/api_config.dart';
import 'package:curso/models/organization_model.dart';

class OrganizationService {
  // Key para obtener el token (debe coincidir con api_service.dart)
  static const String _accessTokenKey = 'api_access_token';

  /// Obtener información de mi organización
  static Future<Organization> getMyOrganization() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessTokenKey);

      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/organizations/my-organization');

      print('🏢 Obteniendo mi organización...');
      print('   URL: $url');

      final response = await http.get(
        url,
        headers: ApiConfig.authHeaders(token),
      );

      print('   Status: ${response.statusCode}');
      print('   Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final organization = Organization.fromJson(data);
        print('✅ Organización obtenida: ${organization.name}');
        return organization;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Error al obtener organización');
      }
    } catch (e) {
      print('❌ Error obteniendo organización: $e');
      rethrow;
    }
  }

  /// Remover un usuario de la organización (solo Admin)
  static Future<Map<String, dynamic>> removeUser(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessTokenKey);

      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/organizations/users/$userId');

      print('🗑️ Removiendo usuario $userId...');
      print('   URL: $url');

      final response = await http.delete(
        url,
        headers: ApiConfig.authHeaders(token),
      );

      print('   Status: ${response.statusCode}');
      print('   Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Usuario removido exitosamente');
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Error al remover usuario');
      }
    } catch (e) {
      print('❌ Error removiendo usuario: $e');
      rethrow;
    }
  }

  /// Transferir administración de la organización
  static Future<Map<String, dynamic>> transferOwnership(int newAdminUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessTokenKey);

      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/organizations/transfer-ownership');

      print('👑 Transfiriendo administración a usuario $newAdminUserId...');

      final response = await http.post(
        url,
        headers: ApiConfig.authHeaders(token),
        body: json.encode({
          'new_admin_user_id': newAdminUserId,
        }),
      );

      print('   Status: ${response.statusCode}');
      print('   Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Administración transferida exitosamente');
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Error al transferir administración');
      }
    } catch (e) {
      print('❌ Error transfiriendo administración: $e');
      rethrow;
    }
  }

  /// Salir de la organización actual
  static Future<Map<String, dynamic>> leaveOrganization() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessTokenKey);

      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/organizations/leave');

      print('🚪 Saliendo de la organización...');

      final response = await http.post(
        url,
        headers: ApiConfig.authHeaders(token),
      );

      print('   Status: ${response.statusCode}');
      print('   Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Has salido de la organización');
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Error al salir de la organización');
      }
    } catch (e) {
      print('❌ Error saliendo de organización: $e');
      rethrow;
    }
  }
}
