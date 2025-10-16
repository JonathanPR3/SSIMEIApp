// lib/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_auth_service.dart';
import '../models/auth_models.dart'; 


part 'auth_provider.g.dart';

// ==========================================
// CONFIGURACIÓN: Elige qué backend usar
// ==========================================
enum AuthBackend {
  cognito,  // Usar Cognito directamente (tu código actual)
  api,      // Usar la API de FastAPI
}

// 🔧 CAMBIAR ESTO PARA ALTERNAR ENTRE COGNITO Y API
const AuthBackend currentAuthBackend = AuthBackend.api;  // ← CAMBIAR AQUÍ

// ==========================================
// ESTADO DE AUTENTICACIÓN
// ==========================================

class AuthState {
  final User? user;
  final bool isLoading;
  final String? errorMessage;
  final bool isInitialized;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.isInitialized = false,
  });

  // Getters de conveniencia
  bool get isLoggedIn => user != null;
  bool get isAdmin => user?.isAdmin ?? false;
  bool get isCommonUser => user?.isCommonUser ?? false;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? errorMessage,
    bool? isInitialized,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  String toString() {
    return 'AuthState{user: ${user?.nombreCompleto}, isLoading: $isLoading, isLoggedIn: $isLoggedIn}';
  }
}

// ==========================================
// PROVIDERS DE SERVICIOS
// ==========================================

// Provider del servicio de Cognito (existente)
@Riverpod(keepAlive: true)
AuthService cognitoAuthService(CognitoAuthServiceRef ref) {
  return AuthService();
}

// Provider del servicio de API (nuevo)
@Riverpod(keepAlive: true)
ApiAuthService apiAuthService(ApiAuthServiceRef ref) {
  return ApiAuthService();
}

// ==========================================
// NOTIFIER PRINCIPAL
// ==========================================

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    print('🏗️ AuthNotifier build() - Backend: $currentAuthBackend');
    return const AuthState(isInitialized: false);
  }

  // Obtener el servicio correcto según la configuración
  dynamic get _activeAuthService {
    if (currentAuthBackend == AuthBackend.api) {
      return ref.read(apiAuthServiceProvider);
    } else {
      return ref.read(cognitoAuthServiceProvider);
    }
  }

  /// Inicializar y verificar sesión guardada
  Future<void> initialize() async {
    if (state.isInitialized) return;

    print('🔄 Inicializando AuthProvider con backend: $currentAuthBackend');
    state = state.copyWith(isLoading: true);
    
    try {
      final sessionStatus = await _activeAuthService.checkSavedSession();
      
      print('📱 Estado de sesión: $sessionStatus');
      
      if (sessionStatus == SessionStatus.active || sessionStatus == SessionStatus.refreshed) {
        final user = await _activeAuthService.getCurrentUser();
        
        if (user != null) {
          print('✅ Usuario restaurado: ${user.nombreCompleto}');
          state = state.copyWith(
            user: user,
            isLoading: false,
            isInitialized: true,
            clearError: true,
          );
        } else {
          print('❌ Sesión activa pero sin datos de usuario');
          state = state.copyWith(
            isLoading: false,
            isInitialized: true,
            clearError: true,
          );
        }
      } else {
        print('❌ No hay sesión activa');
        state = state.copyWith(
          isLoading: false,
          isInitialized: true,
          clearError: true,
        );
      }
    } catch (e) {
      print('❌ Error al verificar sesión: $e');
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: 'Error al verificar sesión: $e',
      );
    }
  }

  /// Registro de administrador
  Future<bool> registerAdmin({
    required String email,
    required String password,
    required String nombre,
    required String apellidoPaterno,
    required String apellidoMaterno,
  }) async {
    print('📝 Registrando admin con backend: $currentAuthBackend');
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _activeAuthService.registerAdmin(
        email: email,
        password: password,
        nombre: nombre,
        apellidoPaterno: apellidoPaterno,
        apellidoMaterno: apellidoMaterno,
      );

      if (result.isSuccess) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error durante el registro: $e',
      );
      return false;
    }
  }

  /// Registro de usuario común
  Future<bool> registerCommonUser({
    required String email,
    required String password,
    required String nombre,
    required String apellidoPaterno,
    required String apellidoMaterno,
    required String adminId,
    String? invitationCode,
  }) async {
    print('📝 Registrando usuario común con backend: $currentAuthBackend');
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _activeAuthService.registerCommonUser(
        email: email,
        password: password,
        nombre: nombre,
        apellidoPaterno: apellidoPaterno,
        apellidoMaterno: apellidoMaterno,
        adminId: adminId,
        invitationCode: invitationCode,
      );

      if (result.isSuccess) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error durante el registro: $e',
      );
      return false;
    }
  }

// En lib/providers/auth_provider.dart

  /// Confirmar registro con código de email
  Future<bool> confirmRegistration({
    required String email,
    required String confirmationCode,
  }) async {
    print('📧 confirmRegistration llamado con: $email, código: $confirmationCode');
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // ✅ VERIFICAR: Debe llamar al servicio activo
      if (currentAuthBackend == AuthBackend.api) {
        print('🌐 Usando API para confirmar');
        
        // Llamar al método correcto de api_auth_service
        final result = await _activeAuthService.confirmRegistration(
          email: email,
          confirmationCode: confirmationCode,
        );

        if (result.isSuccess) {
          state = state.copyWith(isLoading: false);
          return true;
        } else {
          state = state.copyWith(
            isLoading: false,
            errorMessage: result.message,
          );
          return false;
        }
      } else {
        // Cognito
        print('🔐 Usando Cognito para confirmar');
        final result = await _activeAuthService.confirmRegistration(
          email: email,
          confirmationCode: confirmationCode,
        );

        if (result.isSuccess) {
          state = state.copyWith(isLoading: false);
          return true;
        } else {
          state = state.copyWith(
            isLoading: false,
            errorMessage: result.message,
          );
          return false;
        }
      }
    } catch (e) {
      print('❌ Error en confirmRegistration: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al confirmar registro: $e',
      );
      return false;
    }
  }

  /// Iniciar sesión
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    print('🔐 Login con backend: $currentAuthBackend');
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _activeAuthService.login(
        email: email,
        password: password,
      );

      if (result.isSuccess && result.data != null) {
        state = state.copyWith(
          user: result.data,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error durante el login: $e',
      );
      return false;
    }
  }

  /// Recuperar contraseña
  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _activeAuthService.forgotPassword(email);

      if (result.isSuccess) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al solicitar recuperación: $e',
      );
      return false;
    }
  }

  /// Confirmar nueva contraseña
  Future<bool> confirmPassword({
    required String email,
    required String confirmationCode,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _activeAuthService.confirmPassword(
        email: email,
        confirmationCode: confirmationCode,
        newPassword: newPassword,
      );

      if (result.isSuccess) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al confirmar contraseña: $e',
      );
      return false;
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    print('🚪 Logout con backend: $currentAuthBackend');
    state = state.copyWith(isLoading: true);

    try {
      await _activeAuthService.logout();
      state = state.copyWith(
        clearUser: true,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error durante logout: $e',
      );
    }
  }

  /// Reenviar código de confirmación (solo Cognito)
  Future<bool> resendConfirmationCode(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      if (currentAuthBackend == AuthBackend.cognito) {
        final result = await _activeAuthService.resendConfirmationCode(email);

        if (result.isSuccess) {
          state = state.copyWith(isLoading: false);
          return true;
        } else {
          state = state.copyWith(
            isLoading: false,
            errorMessage: result.message,
          );
          return false;
        }
      } else {
        // API no necesita confirmación
        state = state.copyWith(isLoading: false);
        return true;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al reenviar código: $e',
      );
      return false;
    }
  }

  /// Limpiar errores
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Refrescar usuario actual
  Future<void> refreshUser() async {
    final user = await _activeAuthService.getCurrentUser();
    if (user != null) {
      state = state.copyWith(user: user);
    }
  }
}

// ==========================================
// PROVIDERS DE CONVENIENCIA
// ==========================================

@riverpod
User? currentUser(CurrentUserRef ref) {
  return ref.watch(authNotifierProvider).user;
}

@riverpod
bool isLoggedIn(IsLoggedInRef ref) {
  return ref.watch(authNotifierProvider).isLoggedIn;
}

@riverpod
bool isAdmin(IsAdminRef ref) {
  return ref.watch(authNotifierProvider).isAdmin;
}

@riverpod
bool isCommonUser(IsCommonUserRef ref) {
  return ref.watch(authNotifierProvider).isCommonUser;
}