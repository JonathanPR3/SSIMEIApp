// lib/config/api_config.dart
class ApiConfig {
  // ==========================================
  // CONFIGURACIÓN DE LA API
  // ==========================================
  
  // 🔧 CAMBIAR SEGÚN TU ENTORNO
  static const String _baseUrlDevelopment = 'http://localhost:8000';
  static const String _baseUrlProduction = 'https://tu-api.com';
  
  // Modo actual (cambiar a false para producción)
  static const bool isDevelopment = true;
  
  // URL base según el entorno
  static String get baseUrl => isDevelopment ? _baseUrlDevelopment : _baseUrlProduction;
  
  // ==========================================
  // ENDPOINTS
  // ==========================================
  
  // Authentication
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';
  
  // Users
  static const String users = '/users';
  static String userById(String userId) => '/users/$userId';
  static String changePassword(String userId) => '/users/$userId/change-password';
  static String searchUserByEmail(String email) => '/users/search/$email';
  
  // Organizations
  static const String organizations = '/organizations';
  static const String myOrganization = '/organizations/me';
  static String organizationById(String orgId) => '/organizations/$orgId';
  
  // Cameras
  static const String cameras = '/cameras';
  static String cameraById(String cameraId) => '/cameras/$cameraId';
  
  // ==========================================
  // CONFIGURACIÓN DE TIMEOUTS
  // ==========================================
  
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // ==========================================
  // HEADERS
  // ==========================================
  
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static Map<String, String> authHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
  
  // ==========================================
  // CONFIGURACIÓN PARA DIFERENTES PLATAFORMAS
  // ==========================================
  
  // Para Android Emulator, usar 10.0.2.2 en lugar de localhost
  static String get baseUrlForPlatform {
    if (isDevelopment) {
      // Si estás en Android Emulator, descomentar la siguiente línea:
      // return 'http://10.0.2.2:8000';
      
      // Para dispositivos físicos en la misma red:
      // return 'http://TU_IP_LOCAL:8000'; // Ejemplo: http://192.168.1.100:8000
      
      return _baseUrlDevelopment;
    }
    return _baseUrlProduction;
  }
  
  // ==========================================
  // UTILIDADES
  // ==========================================
  
  static String fullUrl(String endpoint) {
    return '$baseUrlForPlatform$endpoint';
  }
  
  static void printConfig() {
    print('🌐 API Configuration:');
    print('   Environment: ${isDevelopment ? "Development" : "Production"}');
    print('   Base URL: $baseUrlForPlatform');
    print('   Timeout: ${connectTimeout.inSeconds}s');
  }
}