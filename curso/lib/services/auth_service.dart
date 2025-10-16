// lib/services/auth_service.dart
import 'dart:convert';
import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/aws_config.dart';
import '../constants/app_constants.dart';
import '../models/user.dart';
import '../models/auth_models.dart'; 

class AuthService {
  late CognitoUserPool _userPool;
  CognitoUser? _currentCognitoUser;
  CognitoUserSession? _currentSession; // NUEVO: Para manejo de sesiones
  
  // NUEVO: Keys para SharedPreferences
  static const String _accessTokenKey = 'access_token';
  static const String _idTokenKey = 'id_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _sessionExpiryKey = 'session_expiry';
  
  AuthService() {
    _initializeCognito();
  }

  void _initializeCognito() {
    print('Inicializando Cognito...');
    print('AWS Configurado: ${AWSConfig.isConfigured}');
    print('Modo Test: ${AWSConfig.useTestMode}');
    print('User Pool ID: ${AWSConfig.userPoolId}');
    print('Client ID: ${AWSConfig.clientId}');
    
    if (AWSConfig.isConfigured) {
      try {
        _userPool = CognitoUserPool(AWSConfig.userPoolId, AWSConfig.clientId);
        print('User Pool inicializado correctamente');
      } catch (e) {
        print('Error inicializando User Pool: $e');
      }
    } else {
      print('AWS no configurado, usando modo test');
    }
  }

  // NUEVO: Verificar y restaurar sesión guardada
  Future<SessionStatus> checkSavedSession() async {
    print('Verificando sesión guardada...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Obtener tokens guardados
      final accessToken = prefs.getString(_accessTokenKey);
      final refreshToken = prefs.getString(_refreshTokenKey);
      final userData = prefs.getString(AppConstants.userDataKey);
      
      if (accessToken == null || refreshToken == null || userData == null) {
        print('No hay sesión guardada');
        return SessionStatus.notFound;
      }
      
      // En modo test, simular verificación
      if (AWSConfig.useTestMode) {
        final expiryStr = prefs.getString(_sessionExpiryKey);
        if (expiryStr != null) {
          final expiry = DateTime.parse(expiryStr);
          if (DateTime.now().isBefore(expiry)) {
            print('Sesión test válida');
            return SessionStatus.active;
          } else {
            print('Sesión test expirada');
            return SessionStatus.expired;
          }
        }
        return SessionStatus.active; // Por defecto en test
      }
      
      // TODO: Verificar tokens reales de Cognito cuando no sea modo test
      // Por ahora, asumir que están válidos si existen
      print('Sesión encontrada, restaurando...');
      await _restoreSession(accessToken, refreshToken);
      return SessionStatus.active;
      
    } catch (e) {
      print('Error verificando sesión: $e');
      await _clearStoredSession();
      return SessionStatus.invalid;
    }
  }

  // NUEVO: Restaurar sesión desde tokens guardados
  Future<void> _restoreSession(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    final userDataStr = prefs.getString(AppConstants.userDataKey);
    
    if (userDataStr != null) {
      final userData = json.decode(userDataStr);
      final email = userData['email'] as String;
      
      // Recrear usuario Cognito
      _currentCognitoUser = CognitoUser(email, _userPool);
      print('Sesión restaurada para: $email');
    }
  }

  // NUEVO: Verificar si el usuario está logueado
  Future<bool> isLoggedIn() async {
    final sessionStatus = await checkSavedSession();
    return sessionStatus == SessionStatus.active || sessionStatus == SessionStatus.refreshed;
  }

  // MEJORADO: Login con guardado de sesión completa
  Future<AuthResult<User>> login({
    required String email,
    required String password,
  }) async {
    print('Iniciando login: $email');
    
    try {
      // Modo test
      if (AWSConfig.useTestMode) {
        print('Login en modo test');
        return _simulateLoginWithSession(email, password);
      }

      print('Autenticando en AWS Cognito...');
      
      final cognitoUser = CognitoUser(email, _userPool);
      final authDetails = AuthenticationDetails(
        username: email,
        password: password,
      );

      final session = await cognitoUser.authenticateUser(authDetails);
      
      if (session != null) {
        print('Sesión obtenida de Cognito');
        _currentCognitoUser = cognitoUser;
        _currentSession = session; // NUEVO: Guardar sesión
        
        // Obtener atributos del usuario
        final attributes = await cognitoUser.getUserAttributes();
        final user = _buildUserFromAttributes(attributes!, email);
        
        // MEJORADO: Guardar sesión completa
        await _saveCompleteSession(session, user);

        print('Login exitoso: ${user.nombreCompleto}');
        return AuthResult.success(
          message: 'Inicio de sesión exitoso',
          data: user,
        );
      }

      print('No se pudo obtener sesión de Cognito');
      return AuthResult.error('Error en la autenticación');
    } catch (e) {
      print('Error en login: $e');
      return AuthResult.error(_parseError(e.toString()));
    }
  }

  // NUEVO: Guardar sesión completa con tokens
  Future<void> _saveCompleteSession(CognitoUserSession session, User user) async {
    print('Guardando sesión completa...');
    
    final prefs = await SharedPreferences.getInstance();
    
    if (AWSConfig.useTestMode) {
      // En modo test, simular tokens
      await prefs.setString(_accessTokenKey, 'fake-access-token-${DateTime.now().millisecondsSinceEpoch}');
      await prefs.setString(_refreshTokenKey, 'fake-refresh-token-${DateTime.now().millisecondsSinceEpoch}');
      
      // Simular expiración de 1 hora
      final expirationTime = DateTime.now().add(Duration(hours: 1));
      await prefs.setString(_sessionExpiryKey, expirationTime.toIso8601String());
    } else {
      // Guardar tokens reales de Cognito
      await prefs.setString(_accessTokenKey, session.getAccessToken().getJwtToken()!);
      await prefs.setString(_idTokenKey, session.getIdToken().getJwtToken()!);
      await prefs.setString(_refreshTokenKey, session.getRefreshToken()!.getToken()!);
      
      // Calcular expiración (Access token dura 1 hora)
      final expirationTime = DateTime.now().add(Duration(hours: 1));
      await prefs.setString(_sessionExpiryKey, expirationTime.toIso8601String());
    }
    
    // Guardar datos del usuario
    await prefs.setString(AppConstants.userDataKey, json.encode(user.toJson()));
    
    print('Sesión completa guardada exitosamente');
  }

  // MEJORADO: Logout con limpieza completa
  Future<void> logout() async {
    print('Cerrando sesión...');
    
    try {
      // Logout de Cognito
      await _currentCognitoUser?.signOut();
      
      // Limpiar variables locales
      _currentCognitoUser = null;
      _currentSession = null;
      
      // Limpiar almacenamiento completo
      await _clearStoredSession();
      
      print('Sesión cerrada exitosamente');
    } catch (e) {
      print('Error durante logout: $e');
    }
  }

  // NUEVO: Limpiar sesión almacenada
  Future<void> _clearStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_idTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_sessionExpiryKey);
    await prefs.remove(AppConstants.userDataKey);
    await prefs.remove(AppConstants.authTokenKey);
    print('Sesión almacenada limpiada completamente');
  }

  // MEJORADO: getCurrentUser con verificación de sesión
  Future<User?> getCurrentUser() async {
    print('Verificando usuario actual...');
    
    // Verificar sesión primero
    final sessionStatus = await checkSavedSession();
    
    if (sessionStatus == SessionStatus.notFound || sessionStatus == SessionStatus.invalid) {
      print('No hay sesión válida');
      return null;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(AppConstants.userDataKey);
      
      if (userData != null) {
        final userMap = json.decode(userData) as Map<String, dynamic>;
        final user = User.fromJson(userMap);
        print('Usuario encontrado: ${user.nombreCompleto}');
        return user;
      }
      
      print('No hay usuario guardado');
      return null;
    } catch (e) {
      print('Error obteniendo usuario actual: $e');
      return null;
    }
  }

  // NUEVO: Obtener access token válido
  Future<String?> getValidAccessToken() async {
    final sessionStatus = await checkSavedSession();
    
    if (sessionStatus == SessionStatus.active || sessionStatus == SessionStatus.refreshed) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKey);
    }
    
    return null;
  }

  // TUS MÉTODOS EXISTENTES (sin cambios)
  
  Future<AuthResult> registerAdmin({
    required String email,
    required String password,
    required String nombre,
    required String apellidoPaterno,
    required String apellidoMaterno,
  }) async {
    print('Iniciando registro de admin: $email');
    
    try {
      if (AWSConfig.useTestMode) {
        print('Usando modo test para registro');
        return _simulateRegisterAdmin(email, nombre, apellidoPaterno, apellidoMaterno);
      }

      print('Registrando en AWS Cognito...');
      
      final userAttributes = [
        AttributeArg(name: 'email', value: email),
        AttributeArg(name: 'name', value: nombre),
        AttributeArg(name: 'family_name', value: apellidoPaterno),
      ];

      print('Enviando petición a Cognito...');
      
      final result = await _userPool.signUp(
        email,
        password,
        userAttributes: userAttributes,
      );

      print('Registro exitoso en Cognito: ${result.userSub}');
      
      return AuthResult.success(
        message: 'Administrador registrado. Verifica tu email.',
        data: {'userSub': result.userSub, 'needsConfirmation': true},
      );
    } catch (e) {
      print('Error en registro: $e');
      print('Tipo de error: ${e.runtimeType}');
      return AuthResult.error(_parseError(e.toString()));
    }
  }

  Future<AuthResult> registerCommonUser({
    required String email,
    required String password,
    required String nombre,
    required String apellidoPaterno,
    required String apellidoMaterno,
    required String adminId,
    String? invitationCode,
  }) async {
    print('Iniciando registro de usuario común: $email');
    
    try {
      if (AWSConfig.useTestMode) {
        print('Usando modo test para registro común');
        return _simulateRegisterCommon(email, nombre, apellidoPaterno, apellidoMaterno, adminId);
      }

      print('Registrando usuario común en AWS Cognito...');

      final userAttributes = [
        AttributeArg(name: 'email', value: email),
        AttributeArg(name: 'name', value: nombre),
        AttributeArg(name: 'family_name', value: apellidoPaterno),
      ];

      final result = await _userPool.signUp(
        email,
        password,
        userAttributes: userAttributes,
      );

      print('Registro común exitoso: ${result.userSub}');

      return AuthResult.success(
        message: 'Usuario registrado. Verifica tu email.',
        data: {'userSub': result.userSub, 'needsConfirmation': true},
      );
    } catch (e) {
      print('Error en registro común: $e');
      return AuthResult.error(_parseError(e.toString()));
    }
  }

  Future<AuthResult> confirmRegistration({
    required String email,
    required String confirmationCode,
  }) async {
    print('Confirmando registro: $email con código: $confirmationCode');
    
    try {
      if (AWSConfig.useTestMode) {
        print('Confirmación en modo test');
        return AuthResult.success(message: 'Email verificado (modo test)');
      }

      final cognitoUser = CognitoUser(email, _userPool);
      await cognitoUser.confirmRegistration(confirmationCode);

      print('Email confirmado exitosamente');
      return AuthResult.success(message: 'Email verificado exitosamente');
    } catch (e) {
      print('Error confirmando registro: $e');
      return AuthResult.error(_parseError(e.toString()));
    }
  }

  Future<AuthResult> forgotPassword(String email) async {
    print('Iniciando recuperación de contraseña: $email');
    
    try {
      if (AWSConfig.useTestMode) {
        print('Recuperación en modo test');
        return AuthResult.success(
          message: 'Código enviado a $email (modo test)',
        );
      }

      final cognitoUser = CognitoUser(email, _userPool);
      await cognitoUser.forgotPassword();

      print('Código de recuperación enviado');
      return AuthResult.success(
        message: 'Código de recuperación enviado a tu email',
      );
    } catch (e) {
      print('Error en recuperación: $e');
      return AuthResult.error(_parseError(e.toString()));
    }
  }

  Future<AuthResult> confirmPassword({
    required String email,
    required String confirmationCode,
    required String newPassword,
  }) async {
    print('Confirmando nueva contraseña: $email');
    
    try {
      if (AWSConfig.useTestMode) {
        print('Confirmación de contraseña en modo test');
        return AuthResult.success(message: 'Contraseña actualizada (modo test)');
      }

      final cognitoUser = CognitoUser(email, _userPool);
      await cognitoUser.confirmPassword(confirmationCode, newPassword);

      print('Contraseña actualizada exitosamente');
      return AuthResult.success(message: 'Contraseña actualizada exitosamente');
    } catch (e) {
      print('Error confirmando contraseña: $e');
      return AuthResult.error(_parseError(e.toString()));
    }
  }

  // MÉTODOS PRIVADOS (algunos existentes, algunos nuevos)

  Future<void> _saveUserSession(User user) async {
    print('Guardando sesión de usuario...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userDataKey, json.encode(user.toJson()));
    print('Sesión guardada');
  }

  User _buildUserFromAttributes(List<CognitoUserAttribute> attributes, String email) {
    print('Construyendo usuario desde atributos de Cognito...');
    
    final attrMap = <String, String>{};
    for (var attr in attributes) {
      attrMap[attr.name!] = attr.value!;
      print('   ${attr.name}: ${attr.value}');
    }

    final user = User(
      id: attrMap['sub'] ?? '',
      email: email,
      nombre: attrMap['name'] ?? '',
      apellidoPaterno: attrMap['family_name'] ?? '',
      apellidoMaterno: '',
      userType: UserType.administrator,
      adminId: null,
      createdAt: DateTime.now(),
      isEmailVerified: attrMap['email_verified'] == 'true',
    );

    print('Usuario construido: ${user.nombreCompleto}');
    return user;
  }

  // Simulaciones para modo test (algunas existentes, algunas nuevas)
  
  Future<AuthResult> _simulateRegisterAdmin(String email, String nombre, String apellidoPaterno, String apellidoMaterno) async {
    print('Simulando registro de admin...');
    await Future.delayed(const Duration(seconds: 1));
    print('Simulación de registro exitosa');
    return AuthResult.success(
      message: 'Administrador registrado (modo test)',
      data: {'needsConfirmation': true},
    );
  }

  Future<AuthResult> _simulateRegisterCommon(String email, String nombre, String apellidoPaterno, String apellidoMaterno, String adminId) async {
    print('Simulando registro de usuario común...');
    await Future.delayed(const Duration(seconds: 1));
    print('Simulación de registro común exitosa');
    return AuthResult.success(
      message: 'Usuario común registrado (modo test)',
      data: {'needsConfirmation': true},
    );
  }

  // MEJORADO: Simulación de login con sesión
  Future<AuthResult<User>> _simulateLoginWithSession(String email, String password) async {
    print('Simulando login con sesión...');
    await Future.delayed(const Duration(seconds: 1));
    
    User? user;
    
    if (email == AppConstants.testAdminEmail && password == AppConstants.testPassword) {
      user = User.testAdmin();
      print('Login de admin test exitoso');
    } else if (email == AppConstants.testCommonEmail && password == AppConstants.testPassword) {
      user = User.testCommon(adminId: 'admin-test-id');
      print('Login de usuario test exitoso');
    }
    
    if (user != null) {
      // Simular guardado de sesión completa
      await _simulateSaveCompleteSession(user);
      return AuthResult.success(
        message: 'Login exitoso (modo test)',
        data: user,
      );
    }
    
    print('Credenciales incorrectas en modo test');
    return AuthResult.error('Credenciales incorrectas');
  }


  // Agregar este método a tu clase AuthService en lib/services/auth_service.dart

    Future<AuthResult> resendConfirmationCode(String email) async {
      print('Reenviando código de confirmación para: $email');
      
      try {
        if (AWSConfig.useTestMode) {
          print('Reenvío en modo test');
          return AuthResult.success(
            message: 'Código reenviado a $email (modo test)',
          );
        }

        final cognitoUser = CognitoUser(email, _userPool);
        await cognitoUser.resendConfirmationCode();

        print('Código reenviado exitosamente');
        return AuthResult.success(
          message: 'Código reenviado a tu email',
        );
      } catch (e) {
        print('Error reenviando código: $e');
        return AuthResult.error(_parseError(e.toString()));
      }
    }

  // NUEVO: Simular guardado de sesión completa
  Future<void> _simulateSaveCompleteSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Crear tokens simulados
    await prefs.setString(_accessTokenKey, 'fake-access-token-${DateTime.now().millisecondsSinceEpoch}');
    await prefs.setString(_refreshTokenKey, 'fake-refresh-token-${DateTime.now().millisecondsSinceEpoch}');
    await prefs.setString(AppConstants.userDataKey, json.encode(user.toJson()));
    
    // Simular expiración de 1 hora
    final expirationTime = DateTime.now().add(Duration(hours: 1));
    await prefs.setString(_sessionExpiryKey, expirationTime.toIso8601String());
    
    print('Sesión simulada completa guardada');
  }

  // EXISTENTE: Simulación de login simple (mantener para compatibilidad)
  Future<AuthResult<User>> _simulateLogin(String email, String password) async {
    return await _simulateLoginWithSession(email, password);
  }

  String _parseError(String error) {
    print('Parseando error: $error');
    
    // NUEVO: Manejar error de confirmación necesaria
    if (error.contains('User Confirmation Necessary') || 
        error.contains('CognitoUserException: User Confirmation Necessary')) {
      return 'Verifica tu email antes de iniciar sesión';
    }
    
    // Errores existentes
    if (error.contains('UserNotConfirmedException')) {
      return 'Verifica tu email antes de iniciar sesión';
    } else if (error.contains('NotAuthorizedException')) {
      return 'Email o contraseña incorrectos';
    } else if (error.contains('UserNotFoundException')) {
      return 'Usuario no encontrado';
    } else if (error.contains('CodeMismatchException')) {
      return 'Código de verificación incorrecto';
    } else if (error.contains('ExpiredCodeException')) {
      return 'El código ha expirado';
    } else if (error.contains('UsernameExistsException')) {
      return 'Ya existe un usuario con este email';
    } else if (error.contains('InvalidParameterException')) {
      return 'Parámetros inválidos en la solicitud';
    } else if (error.contains('NetworkException') || error.contains('SocketException')) {
      return 'Error de conexión. Verifica tu internet';
    }
    
    print('Error no reconocido, retornando mensaje genérico');
    return 'Error de conexión. Intenta nuevamente';
  }




}


