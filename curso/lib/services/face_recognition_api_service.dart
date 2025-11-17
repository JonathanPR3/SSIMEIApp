import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:curso/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio REAL de API para reconocimiento facial
/// Conectado al backend FastAPI
class FaceRecognitionApiService {
  /// Obtener token de autenticación
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    // Usar 'api_access_token' que es como realmente se guarda
    return prefs.getString('api_access_token');
  }

  /// Obtener user_id actual
  static Future<int?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    // Obtener de userData que es donde AuthService lo guarda
    final userDataStr = prefs.getString('user_data');
    if (userDataStr != null) {
      final userData = json.decode(userDataStr);
      return userData['id'] as int?;
    }
    return null;
  }

  /// Registrar rostro con una sola imagen
  ///
  /// Parámetros:
  /// - imagePath: Ruta de la imagen capturada
  /// - userId: (Opcional) ID del usuario si es un usuario registrado
  /// - fullName: (Requerido si userId es null) Nombre completo de la persona
  ///
  /// Retorna:
  /// - Map con success, face_id, message, etc.
  static Future<Map<String, dynamic>> registerFace({
    required String imagePath,
    int? userId,
    String? fullName,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No hay sesión activa. Inicia sesión primero.',
        };
      }

      // Validar que fullName esté presente si userId es null
      if (userId == null && (fullName == null || fullName.isEmpty)) {
        return {
          'success': false,
          'message': 'Se requiere fullName cuando no se especifica userId',
        };
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.faces}');
      final request = http.MultipartRequest('POST', uri);

      // Headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['ngrok-skip-browser-warning'] = 'true';

      // Campos de texto
      if (userId != null) {
        request.fields['user_id'] = userId.toString();
      }
      if (fullName != null && fullName.isNotEmpty) {
        request.fields['full_name'] = fullName;
      }

      // Archivo de imagen
      final file = File(imagePath);
      if (!await file.exists()) {
        return {
          'success': false,
          'message': 'Archivo de imagen no encontrado: $imagePath',
        };
      }

      final stream = http.ByteStream(file.openRead());
      final length = await file.length();

      // Determinar content type basado en la extensión
      String contentType = 'image/jpeg';
      if (imagePath.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      } else if (imagePath.toLowerCase().endsWith('.jpg') || imagePath.toLowerCase().endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      }

      final multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: 'face.jpg',
        contentType: MediaType.parse(contentType),
      );
      request.files.add(multipartFile);

      print('📷 Archivo: $imagePath');
      print('📏 Tamaño: ${length} bytes');
      print('🎨 Content-Type: $contentType');

      print('📤 Enviando rostro al backend...');
      print('   URL: $uri');
      print('   User ID: $userId');
      print('   Full Name: $fullName');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 Respuesta: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Rostro registrado exitosamente');
        print('   Face ID: ${data['id']}');
        print('   Type: ${data['type']}');

        return {
          'success': true,
          'face_id': data['id'],
          'organization_id': data['organization_id'],
          'user_id': data['user_id'],
          'type': data['type'],
          'created_at': data['created_at'],
          'message': 'Rostro registrado correctamente',
        };
      } else if (response.statusCode == 409) {
        // Rostro duplicado
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['detail'] ?? 'Ya existe un rostro muy similar registrado',
          'is_duplicate': true,
        };
      } else if (response.statusCode == 400) {
        // Error de validación
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['detail'] ?? 'Error en la imagen o datos inválidos',
        };
      } else {
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
          'status_code': response.statusCode,
          'body': response.body,
        };
      }
    } catch (e) {
      print('❌ Error al registrar rostro: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
        'error': e.toString(),
      };
    }
  }

  /// Reconocer rostro desde una imagen
  ///
  /// Parámetros:
  /// - imagePath: Ruta de la imagen a reconocer
  /// - threshold: Umbral de similitud (0.0 - 1.0, default: 0.4)
  /// - topN: Número de mejores matches (default: 1)
  ///
  /// Retorna:
  /// - Map con match_found, confidence, face (con info del usuario o metadata)
  static Future<Map<String, dynamic>> recognizeFace({
    required String imagePath,
    double threshold = 0.4,
    int topN = 1,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No hay sesión activa',
        };
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.recognizeFace}');
      final request = http.MultipartRequest('POST', uri);

      // Headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['ngrok-skip-browser-warning'] = 'true';

      // Parámetros
      request.fields['threshold'] = threshold.toString();
      request.fields['top_n'] = topN.toString();

      // Imagen
      final file = File(imagePath);
      if (!await file.exists()) {
        return {
          'success': false,
          'message': 'Archivo no encontrado',
        };
      }

      final stream = http.ByteStream(file.openRead());
      final length = await file.length();

      // Determinar content type basado en la extensión
      String contentType = 'image/jpeg';
      if (imagePath.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      } else if (imagePath.toLowerCase().endsWith('.jpg') || imagePath.toLowerCase().endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      }

      final multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: 'recognize.jpg',
        contentType: MediaType.parse(contentType),
      );
      request.files.add(multipartFile);

      print('🔍 Reconociendo rostro...');
      print('   Archivo: $imagePath');
      print('   Tamaño: ${length} bytes');
      print('   Content-Type: $contentType');
      print('   Threshold: $threshold');
      print('   Top N: $topN');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 Respuesta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['match_found'] == true) {
          print('✅ Rostro reconocido!');
          print('   Confidence: ${data['confidence']}');
          print('   Type: ${data['face']['type']}');
        } else {
          print('❌ Rostro no reconocido');
        }

        return {
          'success': true,
          ...data,
        };
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['detail'] ?? 'Error en la imagen',
        };
      } else {
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error al reconocer rostro: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Listar todos los rostros de la organización
  ///
  /// Parámetros:
  /// - type: "all", "users", "non_users"
  /// - search: Término de búsqueda
  /// - page: Número de página
  /// - limit: Elementos por página
  static Future<Map<String, dynamic>> listFaces({
    String type = 'all',
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No hay sesión activa',
        };
      }

      final queryParams = {
        'type': type,
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.faces}')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ ${data['total']} rostros encontrados');
        return {
          'success': true,
          'total': data['total'],
          'page': data['page'],
          'limit': data['limit'],
          'faces': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Error al obtener rostros: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error al listar rostros: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Eliminar rostro
  static Future<Map<String, dynamic>> deleteFace(int faceId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No hay sesión activa',
        };
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.faceById(faceId)}');

      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 204) {
        print('✅ Rostro eliminado correctamente');
        return {
          'success': true,
          'message': 'Rostro eliminado',
        };
      } else {
        return {
          'success': false,
          'message': 'Error al eliminar rostro: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error al eliminar rostro: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Obtener rostro del usuario actual
  static Future<Map<String, dynamic>> getMyFace() async {
    try {
      final token = await _getAuthToken();
      final userId = await _getCurrentUserId();

      if (token == null || userId == null) {
        return {
          'success': false,
          'message': 'No hay sesión activa',
        };
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.userFace(userId)}');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'face': data,
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'No tienes rostro registrado',
          'not_found': true,
        };
      } else {
        return {
          'success': false,
          'message': 'Error al obtener rostro: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error al obtener rostro: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
}
