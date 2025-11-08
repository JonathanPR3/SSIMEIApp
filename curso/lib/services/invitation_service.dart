// lib/services/invitation_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curso/config/api_config.dart';
import 'package:curso/models/invitation_model.dart';

class InvitationService {
  // Key para obtener el token (debe coincidir con api_service.dart)
  static const String _accessTokenKey = 'api_access_token';

  /// Crear una nueva invitación (solo Admin)
  static Future<Invitation> createInvitation({int? expiresInMinutes}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessTokenKey);

      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/invitations');

      print('🔗 Creando invitación...');
      print('   URL: $url');
      print('   Expira en: ${expiresInMinutes ?? 10} minutos');

      final body = expiresInMinutes != null
          ? json.encode({'expires_in_minutes': expiresInMinutes})
          : json.encode({});

      final response = await http.post(
        url,
        headers: ApiConfig.authHeaders(token),
        body: body,
      );

      print('   Status: ${response.statusCode}');
      print('   Response: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final invitation = Invitation.fromJson(data);
        print('✅ Invitación creada: ${invitation.token}');
        return invitation;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Error al crear invitación');
      }
    } catch (e) {
      print('❌ Error creando invitación: $e');
      rethrow;
    }
  }

  /// Verificar una invitación (público, no requiere auth)
  static Future<InvitationVerification> verifyInvitation(String token) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/invitations/verify/$token');

      print('🔍 Verificando invitación...');
      print('   URL: $url');

      final response = await http.get(
        url,
        headers: ApiConfig.defaultHeaders,
      );

      print('   Status: ${response.statusCode}');
      print('   Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final verification = InvitationVerification.fromJson(data);
        print('✅ Invitación verificada: ${verification.valid}');
        return verification;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Error al verificar invitación');
      }
    } catch (e) {
      print('❌ Error verificando invitación: $e');
      rethrow;
    }
  }

  /// Listar todas las invitaciones de mi organización (solo Admin)
  static Future<List<Invitation>> listInvitations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessTokenKey);

      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/invitations');

      print('📋 Obteniendo lista de invitaciones...');
      print('   URL: $url');

      final response = await http.get(
        url,
        headers: ApiConfig.authHeaders(token),
      );

      print('   Status: ${response.statusCode}');
      print('   Response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final invitations = data.map((json) => Invitation.fromJson(json)).toList();
        print('✅ ${invitations.length} invitaciones obtenidas');
        return invitations;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Error al obtener invitaciones');
      }
    } catch (e) {
      print('❌ Error obteniendo invitaciones: $e');
      rethrow;
    }
  }

  /// Revocar una invitación (solo Admin)
  static Future<void> revokeInvitation(int invitationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessTokenKey);

      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/invitations/$invitationId');

      print('🚫 Revocando invitación $invitationId...');
      print('   URL: $url');

      final response = await http.delete(
        url,
        headers: ApiConfig.authHeaders(token),
      );

      print('   Status: ${response.statusCode}');

      if (response.statusCode == 204 || response.statusCode == 200) {
        print('✅ Invitación revocada exitosamente');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Error al revocar invitación');
      }
    } catch (e) {
      print('❌ Error revocando invitación: $e');
      rethrow;
    }
  }

  /// Obtener invitaciones activas (solo las que están PENDING y no expiradas)
  static Future<List<Invitation>> getActiveInvitations() async {
    try {
      final allInvitations = await listInvitations();
      final activeInvitations = allInvitations.where((inv) => inv.isActive).toList();
      print('📊 ${activeInvitations.length} invitaciones activas de ${allInvitations.length} totales');
      return activeInvitations;
    } catch (e) {
      print('❌ Error obteniendo invitaciones activas: $e');
      rethrow;
    }
  }

  /// Aceptar una invitación (requiere estar autenticado)
  static Future<Map<String, dynamic>> acceptInvitation(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString(_accessTokenKey);

      if (authToken == null) {
        throw Exception('Debes iniciar sesión primero para aceptar la invitación');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/invitations/accept');

      print('✅ Aceptando invitación...');
      print('   URL: $url');

      final response = await http.post(
        url,
        headers: ApiConfig.authHeaders(authToken),
        body: json.encode({'token': token}),
      );

      print('   Status: ${response.statusCode}');
      print('   Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Invitación aceptada exitosamente');
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Error al aceptar invitación');
      }
    } catch (e) {
      print('❌ Error aceptando invitación: $e');
      rethrow;
    }
  }
}
