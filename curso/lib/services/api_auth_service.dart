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

    // MODO TEST: Usar registro simulado
    if (ApiConfig.useMockMode) {
      print('⚠️ MODO MOCK ACTIVO - Usando registro simulado');
      return await _mockRegisterAdmin(email, nombre, apellidoPaterno, apellidoMaterno);
    }

    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConfig.register,
        body: {
          'email': email,
          'password': password,
          'name': nombre,
          'last_name': apellidoPaterno,
          'mother_last_name': apellidoMaterno,
        },
      );

      if (response.isSuccess && response.data != null) {
        print('✅ Admin registrado exitosamente');
        // La API crea automáticamente al usuario como ADMIN de su propia organización
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

    // MODO TEST: Usar registro simulado
    if (ApiConfig.useMockMode) {
      print('⚠️ MODO MOCK ACTIVO - Usando registro simulado');
      return await _mockRegisterCommon(email, nombre, apellidoPaterno, apellidoMaterno);
    }

    try {
      // NOTA: En la nueva API, los usuarios comunes se unen mediante invitaciones
      // Este endpoint crea un nuevo admin con su propia organización
      // Para usuarios comunes, deben usar el sistema de invitaciones
      print('⚠️ NOTA: Usuario común debe registrarse via invitación');

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConfig.register,
        body: {
          'email': email,
          'password': password,
          'name': nombre,
          'last_name': apellidoPaterno,
          'mother_last_name': apellidoMaterno,
        },
      );

      if (response.isSuccess && response.data != null) {
        print('✅ Usuario registrado exitosamente');
        // En la nueva API, todos los registros crean admins con su organización
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

    // MODO TEST: Usar autenticación simulada
    if (ApiConfig.useMockMode) {
      print('⚠️ MODO MOCK ACTIVO - Usando autenticación simulada');
      return await _mockLogin(email, password);
    }

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
        // La API actual no devuelve refresh_token, usar access_token como fallback
        final refreshToken = response.data!['refresh_token'] as String? ?? accessToken;

        // Guardar tokens
        await _apiService.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        // Extraer datos del usuario
        final userData = response.data!['user'] as Map<String, dynamic>;

        // Convertir respuesta de API a modelo User de Flutter
        final user = _buildUserFromApiResponse(userData);

        // Guardar usuario en SharedPreferences (preservando datos del backend)
        await _saveUserData(user, backendData: userData);

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

      // MODO TEST: Asumir sesión válida si existe
      if (ApiConfig.useMockMode) {
        print('⚠️ MODO MOCK - Sesión asumida como válida');
        return SessionStatus.active;
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
  /// TODO: Implementar cuando el backend tenga endpoint /auth/refresh
  Future<bool> refreshToken() async {
    print('🔄 Refrescando token...');
    print('⚠️ Refresh token no implementado aún en la API');

    // TODO: Descomentar cuando el backend implemente /auth/refresh
    /*
    try {
      final refreshToken = await _apiService.getRefreshToken();

      if (refreshToken == null) {
        print('❌ No hay refresh token');
        return false;
      }

      final response = await _apiService.post<Map<String, dynamic>>(
        '/auth/refresh',  // Endpoint cuando esté disponible
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
    */

    return false;
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
      // Convertir userId de String a int
      final userIdInt = int.parse(userId);

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConfig.changePassword(userIdInt),
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
// RECUPERACIÓN DE CONTRASEÑA
// ==========================================
// NOTA: La nueva API no implementa confirmación de email ni recuperación de contraseña
// Estos métodos están aquí por compatibilidad con la UI existente
// TODO: Implementar cuando el backend agregue estos endpoints

/// Confirmar email con código (NO IMPLEMENTADO EN NUEVA API)
Future<AuthResult> confirmRegistration({
  required String email,
  required String confirmationCode,
}) async {
  print('⚠️ confirmRegistration no está implementado en la nueva API');
  return AuthResult.success(
    message: 'No se requiere confirmación de email en esta versión',
  );
}

/// Reenviar código de confirmación (NO IMPLEMENTADO EN NUEVA API)
Future<AuthResult> resendConfirmationCode(String email) async {
  print('⚠️ resendConfirmationCode no está implementado en la nueva API');
  return AuthResult.success(
    message: 'No se requiere confirmación de email en esta versión',
  );
}

/// Recuperar contraseña (NO IMPLEMENTADO EN NUEVA API)
Future<AuthResult> forgotPassword(String email) async {
  print('⚠️ forgotPassword no está implementado en la nueva API');
  return AuthResult.error(
    'La recuperación de contraseña aún no está disponible. Contacta al administrador.',
  );
}

/// Confirmar nueva contraseña con código (NO IMPLEMENTADO EN NUEVA API)
Future<AuthResult> confirmPassword({
  required String email,
  required String confirmationCode,
  required String newPassword,
}) async {
  print('⚠️ confirmPassword no está implementado en la nueva API');
  return AuthResult.error(
    'La recuperación de contraseña aún no está disponible. Contacta al administrador.',
  );
}
  
  // ==========================================
  // MÉTODOS AUXILIARES
  // ==========================================
  
  /// Convertir respuesta de API a modelo User de Flutter
  User _buildUserFromApiResponse(Map<String, dynamic> apiData) {
    print('🔨 Construyendo User desde respuesta de API');
    print('   Datos recibidos: $apiData');

    // Mapeo de campos de la API FastAPI a tu modelo User
    // API devuelve: id, email, name, last_name, mother_last_name, role, organization_id, created_at
    // Tu modelo espera: id, email, nombre, apellidoPaterno, apellidoMaterno, userType, adminId, createdAt

    final userId = apiData['id'].toString(); // Convertir int a String
    final email = apiData['email'] as String;
    final firstName = apiData['name'] as String;
    final lastName = apiData['last_name'] as String?;
    final motherLastName = apiData['mother_last_name'] as String?;
    final role = apiData['role'] as String;
    final organizationId = apiData['organization_id']?.toString(); // Convertir int a String

    // Convertir role de API a UserType de Flutter
    // API usa: "ADMIN" o "USER"
    final userType = role == 'ADMIN' ? UserType.administrator : UserType.common;

    // Convertir fecha si existe
    DateTime createdAt = DateTime.now();
    if (apiData['created_at'] != null) {
      try {
        createdAt = DateTime.parse(apiData['created_at'] as String);
      } catch (e) {
        print('⚠️ No se pudo parsear created_at: $e');
      }
    }

    // Crear usuario
    final user = User(
      id: userId,
      email: email,
      nombre: firstName,
      apellidoPaterno: lastName ?? '',
      apellidoMaterno: motherLastName ?? '',
      userType: userType,
      adminId: organizationId, // Usar organization_id como adminId
      createdAt: createdAt,
      isEmailVerified: true, // La API no requiere confirmación de email
      isActive: true,
      accessibleCameraIds: [], // TODO: Implementar si la API devuelve esto
    );

    print('✅ Usuario construido: ${user.nombreCompleto}');
    return user;
  }
  
  /// Guardar datos del usuario en SharedPreferences
  Future<void> _saveUserData(User user, {Map<String, dynamic>? backendData}) async {
    final prefs = await SharedPreferences.getInstance();

    // Si tenemos datos del backend, guardarlos también para preservar campos como 'role'
    if (backendData != null) {
      await prefs.setString(
        AppConstants.userDataKey,
        json.encode(backendData),
      );
      print('💾 Datos de usuario guardados (con datos del backend)');
    } else {
      await prefs.setString(
        AppConstants.userDataKey,
        json.encode(user.toJson()),
      );
      print('💾 Datos de usuario guardados');
    }
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

  // ==========================================
  // MÉTODOS MOCK PARA TESTING
  // ==========================================

  /// Login simulado para testing
  Future<AuthResult<User>> _mockLogin(String email, String password) async {
    print('🎭 Simulando login...');
    await Future.delayed(const Duration(milliseconds: 800)); // Simular latencia de red

    User? user;

    // Verificar credenciales mock
    if (email == AppConstants.testAdminEmail && password == AppConstants.testPassword) {
      user = User.testAdmin();
      print('✅ Login mock exitoso - Admin');
    } else if (email == AppConstants.testCommonEmail && password == AppConstants.testPassword) {
      user = User.testCommon(adminId: 'admin-test-id');
      print('✅ Login mock exitoso - Usuario común');
    }

    if (user != null) {
      // Simular guardado de tokens
      await _apiService.saveTokens(
        accessToken: 'mock-access-token-${DateTime.now().millisecondsSinceEpoch}',
        refreshToken: 'mock-refresh-token-${DateTime.now().millisecondsSinceEpoch}',
      );

      // Guardar datos del usuario
      await _saveUserData(user);

      return AuthResult.success(
        message: 'Inicio de sesión exitoso (MOCK)',
        data: user,
      );
    }

    print('❌ Credenciales incorrectas en modo mock');
    return AuthResult.error('Email o contraseña incorrectos');
  }

  /// Registro mock de administrador
  Future<AuthResult> _mockRegisterAdmin(
    String email,
    String nombre,
    String apellidoPaterno,
    String apellidoMaterno,
  ) async {
    print('🎭 Simulando registro de admin...');
    await Future.delayed(const Duration(milliseconds: 800));

    print('✅ Admin registrado (MOCK)');
    return AuthResult.success(
      message: 'Administrador registrado exitosamente (MOCK)',
      data: {'needsConfirmation': false}, // API no requiere confirmación
    );
  }

  /// Registro mock de usuario común
  Future<AuthResult> _mockRegisterCommon(
    String email,
    String nombre,
    String apellidoPaterno,
    String apellidoMaterno,
  ) async {
    print('🎭 Simulando registro de usuario común...');
    await Future.delayed(const Duration(milliseconds: 800));

    print('✅ Usuario registrado (MOCK)');
    return AuthResult.success(
      message: 'Usuario registrado exitosamente (MOCK)',
      data: {'needsConfirmation': false},
    );
  }
}

