// lib/services/api_auth_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../constants/app_constants.dart';
import '../models/user.dart';
import '../models/auth_models.dart'; 
import 'api_service.dart';

class ApiAuthService {
  final ApiService _apiService = ApiService();
  
  // ==========================================
  // REGISTRO
  // ==========================================
  
  /// Registrar administrador
  Future<AuthResult> registerAdmin({
    required String email,
    required String password,
    required String nombre,
    required String apellidoPaterno,
    required String apellidoMaterno,
  }) async {
    print('📝 Registrando admin via API: $email');
    
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConfig.register,
        body: {
          'email': email,
          'password': password,
          'first_name': nombre,
          'last_name': apellidoPaterno,
          'role': 'admin',
        },
      );
      
      if (response.isSuccess && response.data != null) {
        print('✅ Admin registrado exitosamente');
        return AuthResult.success(
          message: 'Administrador registrado exitosamente',
          data: response.data,
        );
      } else {
        return AuthResult.error(response.message);
      }
    } catch (e) {
      print('❌ Error registrando admin: $e');
      return AuthResult.error('Error durante el registro: $e');
    }
  }
  
  /// Registrar usuario común
  Future<AuthResult> registerCommonUser({
    required String email,
    required String password,
    required String nombre,
    required String apellidoPaterno,
    required String apellidoMaterno,
    required String adminId,
    String? invitationCode,
  }) async {
    print('📝 Registrando usuario común via API: $email');
    
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConfig.register,
        body: {
          'email': email,
          'password': password,
          'first_name': nombre,
          'last_name': apellidoPaterno,
          'role': 'user',
          // TODO: Agregar organization_id si tu API lo requiere
        },
      );
      
      if (response.isSuccess && response.data != null) {
        print('✅ Usuario común registrado exitosamente');
        return AuthResult.success(
          message: 'Usuario registrado exitosamente',
          data: response.data,
        );
      } else {
        return AuthResult.error(response.message);
      }
    } catch (e) {
      print('❌ Error registrando usuario: $e');
      return AuthResult.error('Error durante el registro: $e');
    }
  }
  
  // ==========================================
  // LOGIN
  // ==========================================
  
  /// Iniciar sesión
  Future<AuthResult<User>> login({
    required String email,
    required String password,
  }) async {
    print('🔐 Iniciando login via API: $email');
    
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConfig.login,
        body: {
          'email': email,
          'password': password,
        },
      );
      
      if (response.isSuccess && response.data != null) {
        print('📦 Respuesta de login recibida');
        
        // Extraer tokens
        final accessToken = response.data!['access_token'] as String;
        final refreshToken = response.data!['refresh_token'] as String;
        
        // Guardar tokens
        await _apiService.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        
        // Extraer datos del usuario
        final userData = response.data!['user'] as Map<String, dynamic>;
        
        // Convertir respuesta de API a modelo User de Flutter
        final user = _buildUserFromApiResponse(userData);
        
        // Guardar usuario en SharedPreferences
        await _saveUserData(user);
        
        print('✅ Login exitoso: ${user.nombreCompleto}');
        
        return AuthResult.success(
          message: 'Inicio de sesión exitoso',
          data: user,
        );
      } else {
        return AuthResult.error(response.message);
      }
    } catch (e) {
      print('❌ Error en login: $e');
      return AuthResult.error('Error durante el login: $e');
    }
  }
  
  // ==========================================
  // SESIÓN
  // ==========================================
  
  /// Verificar sesión guardada
  Future<SessionStatus> checkSavedSession() async {
    print('🔍 Verificando sesión guardada...');
    
    try {
      final accessToken = await _apiService.getAccessToken();
      final userData = await _getUserData();
      
      if (accessToken == null || userData == null) {
        print('❌ No hay sesión guardada');
        return SessionStatus.notFound;
      }
      
      // Verificar que el token sea válido llamando a /auth/me
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiConfig.me,
        requiresAuth: true,
      );
      
      if (response.isSuccess) {
        print('✅ Sesión válida');
        return SessionStatus.active;
      } else {
        print('❌ Sesión inválida o expirada');
        return SessionStatus.expired;
      }
    } catch (e) {
      print('❌ Error verificando sesión: $e');
      return SessionStatus.invalid;
    }
  }
  
  /// Verificar si está logueado
  Future<bool> isLoggedIn() async {
    final status = await checkSavedSession();
    return status == SessionStatus.active || status == SessionStatus.refreshed;
  }
  
  /// Obtener usuario actual
  Future<User?> getCurrentUser() async {
    print('👤 Obteniendo usuario actual...');
    
    // Primero intentar desde SharedPreferences (más rápido)
    final cachedUser = await _getUserData();
    if (cachedUser != null) {
      print('✅ Usuario en caché: ${cachedUser.nombreCompleto}');
      return cachedUser;
    }
    
    // Si no hay caché, obtener desde la API
    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiConfig.me,
        requiresAuth: true,
      );
      
      if (response.isSuccess && response.data != null) {
        final user = _buildUserFromApiResponse(response.data!);
        await _saveUserData(user);
        print('✅ Usuario obtenido de API: ${user.nombreCompleto}');
        return user;
      }
      
      return null;
    } catch (e) {
      print('❌ Error obteniendo usuario: $e');
      return null;
    }
  }
  
  /// Refrescar token
  Future<bool> refreshToken() async {
    print('🔄 Refrescando token...');
    
    try {
      final refreshToken = await _apiService.getRefreshToken();
      
      if (refreshToken == null) {
        print('❌ No hay refresh token');
        return false;
      }
      
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConfig.refresh,
        body: {'refresh_token': refreshToken},
      );
      
      if (response.isSuccess && response.data != null) {
        final newAccessToken = response.data!['access_token'] as String;
        final newRefreshToken = response.data!['refresh_token'] as String?;
        
        await _apiService.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken ?? refreshToken,
        );
        
        print('✅ Token refrescado exitosamente');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Error refrescando token: $e');
      return false;
    }
  }
  
  /// Cerrar sesión
  Future<void> logout() async {
    print('🚪 Cerrando sesión...');
    
    try {
      // Limpiar tokens de la API
      await _apiService.clearTokens();
      
      // Limpiar datos del usuario
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userDataKey);
      
      print('✅ Sesión cerrada exitosamente');
    } catch (e) {
      print('❌ Error durante logout: $e');
    }
  }
  
  // ==========================================
  // CAMBIO DE CONTRASEÑA
  // ==========================================
  
  /// Cambiar contraseña
  Future<AuthResult> changePassword({
    required String userId,
    required String newPassword,
  }) async {
    print('🔑 Cambiando contraseña para usuario: $userId');
    
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConfig.changePassword(userId),
        body: {'new_password': newPassword},
        requiresAuth: true,
      );
      
      if (response.isSuccess) {
        return AuthResult.success(message: response.message);
      } else {
        return AuthResult.error(response.message);
      }
    } catch (e) {
      print('❌ Error cambiando contraseña: $e');
      return AuthResult.error('Error al cambiar contraseña: $e');
    }
  }

// ==========================================
// CONFIRMACIÓN DE EMAIL
// ==========================================

/// Confirmar email con código
Future<AuthResult> confirmRegistration({
  required String email,
  required String confirmationCode,
}) async {
  print('📧 API: Confirmando email $email');
  
  try {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/auth/confirm-email?email=$email&confirmation_code=$confirmationCode',
    );
    
    if (response.isSuccess) {
      print('✅ Email confirmado en API');
      return AuthResult.success(message: response.message);
    } else {
      print('❌ Error confirmando: ${response.message}');
      return AuthResult.error(response.message);
    }
  } catch (e) {
    print('❌ Error en confirmRegistration: $e');
    return AuthResult.error('Error al confirmar email: $e');
  }
}

/// Reenviar código de confirmación
Future<AuthResult> resendConfirmationCode(String email) async {
  print('🔄 API: Reenviando código a $email');
  
  try {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/auth/resend-code?email=$email',
    );
    
    if (response.isSuccess) {
      print('✅ Código reenviado');
      return AuthResult.success(message: response.message);
    } else {
      print('❌ Error reenviando: ${response.message}');
      return AuthResult.error(response.message);
    }
  } catch (e) {
    print('❌ Error en resendConfirmationCode: $e');
    return AuthResult.error('Error al reenviar código: $e');
  }
}

/// Recuperar contraseña (placeholder - no implementado en backend)
Future<AuthResult> forgotPassword(String email) async {
  print('🔑 API: Enviando código de recuperación a $email');
  
  try {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/auth/forgot-password?email=$email',
    );
    
    if (response.isSuccess) {
      print('✅ Código de recuperación enviado');
      return AuthResult.success(
        message: response.data?['message'] ?? 'Código enviado a tu email',
      );
    } else {
      print('❌ Error enviando código: ${response.message}');
      return AuthResult.error(response.message);
    }
  } catch (e) {
    print('❌ Error en forgotPassword: $e');
    return AuthResult.error('Error al enviar código de recuperación: $e');
  }
}



/// Confirmar nueva contraseña con código
Future<AuthResult> confirmPassword({
  required String email,
  required String confirmationCode,
  required String newPassword,
}) async {
  print('🔐 API: Confirmando nueva contraseña para $email');
  
  try {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/auth/confirm-forgot-password',
      body: {
        'email': email,
        'confirmation_code': confirmationCode,
        'new_password': newPassword,
      },
    );
    
    if (response.isSuccess) {
      print('✅ Contraseña cambiada exitosamente');
      return AuthResult.success(
        message: response.data?['message'] ?? 'Contraseña restablecida exitosamente',
      );
    } else {
      print('❌ Error cambiando contraseña: ${response.message}');
      return AuthResult.error(response.message);
    }
  } catch (e) {
    print('❌ Error en confirmPassword: $e');
    return AuthResult.error('Error al cambiar contraseña: $e');
  }
}
  
  // ==========================================
  // MÉTODOS AUXILIARES
  // ==========================================
  
  /// Convertir respuesta de API a modelo User de Flutter
  User _buildUserFromApiResponse(Map<String, dynamic> apiData) {
    print('🔨 Construyendo User desde respuesta de API');
    print('   Datos recibidos: $apiData');
    
    // Mapeo de campos de la API a tu modelo User
    // API devuelve: user_id, email, first_name, last_name, role, organization_id, status, created_at
    // Tu modelo espera: id, email, nombre, apellidoPaterno, apellidoMaterno, userType, adminId, createdAt
    
    final userId = apiData['user_id'] as String;
    final email = apiData['email'] as String;
    final firstName = apiData['first_name'] as String;
    final lastName = apiData['last_name'] as String;
    final role = apiData['role'] as String;
    final organizationId = apiData['organization_id'] as String?;
    final status = apiData['status'] as String;
    final createdAtStr = apiData['created_at'] as String;
    
    // Convertir role de API a UserType de Flutter
    final userType = role == 'admin' ? UserType.administrator : UserType.common;
    
    // Convertir fecha
    final createdAt = DateTime.parse(createdAtStr);
    
    // Crear usuario
    final user = User(
      id: userId,
      email: email,
      nombre: firstName,
      apellidoPaterno: lastName,
      apellidoMaterno: '', // La API no tiene apellido materno
      userType: userType,
      adminId: organizationId, // Usar organization_id como adminId por ahora
      createdAt: createdAt,
      isEmailVerified: true, // La API confirma automáticamente
      isActive: status == 'active',
      accessibleCameraIds: [], // TODO: Implementar si la API devuelve esto
    );
    
    print('✅ Usuario construido: ${user.nombreCompleto}');
    return user;
  }
  
  /// Guardar datos del usuario en SharedPreferences
  Future<void> _saveUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.userDataKey,
      json.encode(user.toJson()),
    );
    print('💾 Datos de usuario guardados');
  }
  
  /// Obtener datos del usuario de SharedPreferences
  Future<User?> _getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString(AppConstants.userDataKey);
      
      if (userDataStr != null) {
        final userMap = json.decode(userDataStr) as Map<String, dynamic>;
        return User.fromJson(userMap);
      }
      
      return null;
    } catch (e) {
      print('❌ Error obteniendo datos de usuario: $e');
      return null;
    }
  }
}

