// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  // Keys para SharedPreferences
  static const String _accessTokenKey = 'api_access_token';
  static const String _refreshTokenKey = 'api_refresh_token';
  
  // Cliente HTTP
  final http.Client _client = http.Client();
  
  // ==========================================
  // GESTIÓN DE TOKENS
  // ==========================================
  
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }
  
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }
  
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    print('✅ Tokens guardados');
  }
  
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    print('🗑️ Tokens eliminados');
  }
  
  // ==========================================
  // MÉTODOS HTTP
  // ==========================================
  
  /// GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParameters,
    bool requiresAuth = false,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.fullUrl(endpoint)).replace(
        queryParameters: queryParameters,
      );
      
      print('🌐 GET $uri');
      
      final headers = requiresAuth
          ? ApiConfig.authHeaders(await getAccessToken() ?? '')
          : ApiConfig.defaultHeaders;
      
      final response = await _client
          .get(uri, headers: headers)
          .timeout(ApiConfig.receiveTimeout);
      
      return _handleResponse<T>(response, fromJson);
      
    } on SocketException {
      return ApiResponse.error('Sin conexión a internet');
    } on HttpException {
      return ApiResponse.error('Error de conexión');
    } on FormatException {
      return ApiResponse.error('Respuesta inválida del servidor');
    } catch (e) {
      print('❌ Error en GET $endpoint: $e');
      return ApiResponse.error('Error: $e');
    }
  }
  
  /// POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.fullUrl(endpoint));
      
      print('🌐 POST $uri');
      if (body != null) print('📤 Body: ${json.encode(body)}');
      
      final headers = requiresAuth
          ? ApiConfig.authHeaders(await getAccessToken() ?? '')
          : ApiConfig.defaultHeaders;
      
      final response = await _client
          .post(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(ApiConfig.receiveTimeout);
      
      return _handleResponse<T>(response, fromJson);
      
    } on SocketException {
      return ApiResponse.error('Sin conexión a internet');
    } on HttpException {
      return ApiResponse.error('Error de conexión');
    } on FormatException {
      return ApiResponse.error('Respuesta inválida del servidor');
    } catch (e) {
      print('❌ Error en POST $endpoint: $e');
      return ApiResponse.error('Error: $e');
    }
  }
  
  /// PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.fullUrl(endpoint));
      
      print('🌐 PUT $uri');
      
      final headers = requiresAuth
          ? ApiConfig.authHeaders(await getAccessToken() ?? '')
          : ApiConfig.defaultHeaders;
      
      final response = await _client
          .put(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(ApiConfig.receiveTimeout);
      
      return _handleResponse<T>(response, fromJson);
      
    } catch (e) {
      print('❌ Error en PUT $endpoint: $e');
      return ApiResponse.error('Error: $e');
    }
  }
  
  /// DELETE request
  Future<ApiResponse<void>> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.fullUrl(endpoint));
      
      print('🌐 DELETE $uri');
      
      final headers = requiresAuth
          ? ApiConfig.authHeaders(await getAccessToken() ?? '')
          : ApiConfig.defaultHeaders;
      
      final response = await _client
          .delete(uri, headers: headers)
          .timeout(ApiConfig.receiveTimeout);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(null, 'Eliminado exitosamente');
      } else {
        final error = _parseError(response);
        return ApiResponse.error(error);
      }
      
    } catch (e) {
      print('❌ Error en DELETE $endpoint: $e');
      return ApiResponse.error('Error: $e');
    }
  }
  
  // ==========================================
  // MANEJO DE RESPUESTAS
  // ==========================================
  
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return ApiResponse.success(null as T, 'Operación exitosa');
      }
      
      try {
        final jsonData = json.decode(response.body);
        
        if (fromJson != null && jsonData is Map<String, dynamic>) {
          final data = fromJson(jsonData);
          return ApiResponse.success(data, 'Operación exitosa');
        } else {
          return ApiResponse.success(jsonData as T, 'Operación exitosa');
        }
      } catch (e) {
        print('❌ Error parseando JSON: $e');
        return ApiResponse.error('Error procesando respuesta');
      }
    } else {
      final error = _parseError(response);
      return ApiResponse.error(error);
    }
  }
  
  String _parseError(http.Response response) {
    try {
      final jsonData = json.decode(response.body);
      
      // Tu API FastAPI devuelve errores así: {"detail": "mensaje"}
      if (jsonData is Map<String, dynamic>) {
        if (jsonData.containsKey('detail')) {
          return jsonData['detail'] as String;
        }
        if (jsonData.containsKey('message')) {
          return jsonData['message'] as String;
        }
      }
      
      // Fallback a mensajes genéricos por código de estado
      switch (response.statusCode) {
        case 400:
          return 'Solicitud inválida';
        case 401:
          return 'No autorizado. Inicia sesión nuevamente';
        case 403:
          return 'Acceso denegado';
        case 404:
          return 'No encontrado';
        case 409:
          return 'El recurso ya existe';
        case 500:
          return 'Error del servidor';
        default:
          return 'Error ${response.statusCode}';
      }
    } catch (e) {
      return 'Error ${response.statusCode}';
    }
  }
  
  // ==========================================
  // UTILIDADES
  // ==========================================
  
  void dispose() {
    _client.close();
  }
}

// ==========================================
// CLASE DE RESPUESTA
// ==========================================

class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String message;
  
  const ApiResponse._({
    required this.isSuccess,
    this.data,
    required this.message,
  });
  
  factory ApiResponse.success(T? data, String message) {
    return ApiResponse._(
      isSuccess: true,
      data: data,
      message: message,
    );
  }
  
  factory ApiResponse.error(String message) {
    return ApiResponse._(
      isSuccess: false,
      data: null,
      message: message,
    );
  }
  
  @override
  String toString() {
    return 'ApiResponse{isSuccess: $isSuccess, message: $message, data: $data}';
  }
}