// lib/models/auth_models.dart
/// Modelos y enums compartidos para autenticación

// ==========================================
// ENUM: Estado de sesión
// ==========================================

enum SessionStatus {
  active,      // Sesión activa con tokens válidos
  refreshed,   // Sesión renovada exitosamente
  expired,     // Sesión expirada, necesita login
  invalid,     // Sesión inválida/corrupta
  notFound,    // No hay sesión guardada
}

// ==========================================
// CLASE: Resultado de operaciones de autenticación
// ==========================================

class AuthResult<T> {
  final bool isSuccess;
  final String message;
  final T? data;

  const AuthResult._({
    required this.isSuccess,
    this.message = '',
    this.data,
  });

  factory AuthResult.success({String message = '', T? data}) {
    return AuthResult._(
      isSuccess: true,
      message: message,
      data: data,
    );
  }

  factory AuthResult.error(String message) {
    return AuthResult._(
      isSuccess: false,
      message: message,
      data: null,
    );
  }

  @override
  String toString() {
    return 'AuthResult{isSuccess: $isSuccess, message: $message, data: $data}';
  }
}