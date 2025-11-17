// lib/config/api_config.dart
class ApiConfig {
  // ==========================================
  // CONFIGURACIÓN DE LA API
  // ==========================================

  // 🔧 CAMBIAR SEGÚN TU ENTORNO
  static const String _baseUrlDevelopment = 'http://localhost:8000';
  static const String _baseUrlProduction = 'https://mathilda-conventually-esta.ngrok-free.dev';

  // Modo actual (cambiar a false para producción)
  static const bool isDevelopment = false;

  // 🔧 TOGGLE PARA MODO TEST (sin llamadas reales a la API)
  // Cambia esto a FALSE cuando quieras conectarte a la API real
  static const bool useMockMode = false;

  // URL base según el entorno
  static String get baseUrl => isDevelopment ? _baseUrlDevelopment : _baseUrlProduction;

  // ==========================================
  // ENDPOINTS - ACTUALIZADOS PARA FASTAPI
  // ==========================================

  // Authentication
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';

  // Email Verification - NUEVO 2025-11-13
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerification = '/auth/resend-verification';

  // Password Recovery - NUEVO 2025-11-13
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyResetCode = '/auth/verify-reset-code';
  static const String resetPassword = '/auth/reset-password';

  // Users
  static const String users = '/users';
  static String userById(int userId) => '/users/$userId';
  static String changePassword(int userId) => '/users/$userId/change-password';
  static String searchUserByEmail(String email) => '/users/search/$email';

  // Organizations
  static const String organizations = '/organizations';
  static const String myOrganization = '/organizations/me';
  static String organizationById(int orgId) => '/organizations/$orgId';

  // Cameras
  static const String cameras = '/cameras';
  static String cameraById(int cameraId) => '/cameras/$cameraId';

  // Invitations
  static const String invitations = '/invitations';
  static String acceptInvitation = '/invitations/accept';

  // Join Requests
  static const String joinRequests = '/join-requests';
  static String reviewJoinRequest(int requestId) => '/join-requests/$requestId/review';

  // Detections/Incidents
  static const String incidents = '/api/detection/incidents';
  static String incidentById(int incidentId) => '/api/detection/incidents/$incidentId';
  static String acknowledgeIncident(int incidentId) => '/api/detection/incidents/$incidentId/acknowledge';
  static const String incidentsStats = '/api/detection/incidents/stats/summary';
  static const String simulationStart = '/api/detection/simulation/start';
  static const String simulationStop = '/api/detection/simulation/stop';
  static const String simulationStatus = '/api/detection/simulation/status';

  // WebSocket
  static String webSocketUrl(String token) => '${baseUrl.replaceAll('http', 'ws')}/ws/notifications?token=$token';

  // Faces - Reconocimiento Facial
  static const String faces = '/api/v1/faces';
  static String faceById(int faceId) => '/api/v1/faces/$faceId';
  static const String recognizeFace = '/api/v1/faces/recognize';
  static String userFace(int userId) => '/api/v1/faces/users/$userId/face';

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
    'ngrok-skip-browser-warning': 'true', // Necesario para ngrok free tier
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