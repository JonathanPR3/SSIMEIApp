import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:curso/services/face_storage_service.dart';

/// Servicio para comunicación con la API de reconocimiento facial
/// Este servicio está listo para cuando implementes tu backend
class FaceApiService {
  // TODO: Reemplazar con la URL de tu API real
  static const String _baseUrl = 'https://tu-api.com/api';
  static const String _facesEndpoint = '/faces';
  static const String _embeddingsEndpoint = '/embeddings';

  /// Envía las imágenes de un rostro al backend para procesamiento
  /// Retorna los embeddings generados por el modelo de IA
  ///
  /// Uso:
  /// ```dart
  /// final embeddings = await FaceApiService.uploadFaceImages(
  ///   faceId: 'face_123',
  ///   name: 'Juan Pérez',
  ///   relationship: 'Familiar',
  ///   imagePaths: ['/path/img1.jpg', '/path/img2.jpg'],
  ///   authToken: 'tu_token_jwt',
  /// );
  /// ```
  static Future<Map<String, dynamic>> uploadFaceImages({
    required String faceId,
    required String name,
    required String relationship,
    required List<String> imagePaths,
    String? authToken,
  }) async {
    try {
      // Crear request multipart para enviar archivos
      final uri = Uri.parse('$_baseUrl$_facesEndpoint');
      final request = http.MultipartRequest('POST', uri);

      // Agregar headers
      if (authToken != null) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }
      request.headers['Content-Type'] = 'multipart/form-data';

      // Agregar campos de texto
      request.fields['face_id'] = faceId;
      request.fields['name'] = name;
      request.fields['relationship'] = relationship;
      request.fields['images_count'] = imagePaths.length.toString();
      request.fields['captured_at'] = DateTime.now().toIso8601String();

      // Agregar archivos de imagen
      for (int i = 0; i < imagePaths.length; i++) {
        final file = File(imagePaths[i]);
        if (await file.exists()) {
          final stream = http.ByteStream(file.openRead());
          final length = await file.length();
          final multipartFile = http.MultipartFile(
            'images', // nombre del campo en el backend
            stream,
            length,
            filename: 'step_${i + 1}.jpg',
          );
          request.files.add(multipartFile);
        }
      }

      // Enviar request
      print('📤 Enviando ${request.files.length} imágenes al servidor...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Rostro procesado exitosamente');
        print('   - Embeddings generados: ${data['embeddings'] != null}');

        return {
          'success': true,
          'face_id': data['face_id'] ?? faceId,
          'embeddings': data['embeddings'], // Vector de características faciales
          'confidence': data['confidence'] ?? 0.0,
          'message': data['message'] ?? 'Rostro registrado correctamente',
        };
      } else {
        throw Exception('Error del servidor: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error al enviar imágenes: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'No se pudo conectar con el servidor',
      };
    }
  }

  /// Verifica un rostro capturado contra los embeddings registrados
  /// Retorna la identidad reconocida o null si no se reconoce
  ///
  /// Uso:
  /// ```dart
  /// final result = await FaceApiService.verifyFace(
  ///   imageBytes: capturedImageBytes,
  ///   authToken: 'tu_token_jwt',
  /// );
  /// if (result['recognized']) {
  ///   print('Persona reconocida: ${result['name']}');
  /// }
  /// ```
  static Future<Map<String, dynamic>> verifyFace({
    required List<int> imageBytes,
    String? authToken,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$_facesEndpoint/verify');
      final request = http.MultipartRequest('POST', uri);

      if (authToken != null) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }

      // Agregar imagen capturada
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'capture.jpg',
      );
      request.files.add(multipartFile);

      print('🔍 Verificando rostro...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Verificación completada');

        return {
          'recognized': data['recognized'] ?? false,
          'face_id': data['face_id'],
          'name': data['name'],
          'relationship': data['relationship'],
          'confidence': data['confidence'] ?? 0.0,
          'similarity_score': data['similarity_score'] ?? 0.0,
        };
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en verificación: $e');
      return {
        'recognized': false,
        'error': e.toString(),
      };
    }
  }

  /// Obtiene los embeddings de un rostro registrado
  static Future<Map<String, dynamic>> getFaceEmbeddings({
    required String faceId,
    String? authToken,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$_embeddingsEndpoint/$faceId');
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Actualiza los embeddings de un rostro existente
  static Future<bool> updateFaceEmbeddings({
    required String faceId,
    required List<String> newImagePaths,
    String? authToken,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$_facesEndpoint/$faceId/update');
      final request = http.MultipartRequest('PUT', uri);

      if (authToken != null) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }

      // Agregar nuevas imágenes
      for (final path in newImagePaths) {
        final file = File(path);
        if (await file.exists()) {
          final multipartFile = await http.MultipartFile.fromPath('images', path);
          request.files.add(multipartFile);
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error al actualizar embeddings: $e');
      return false;
    }
  }

  /// Elimina un rostro y sus embeddings del servidor
  static Future<bool> deleteFaceFromServer({
    required String faceId,
    String? authToken,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$_facesEndpoint/$faceId');
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.delete(uri, headers: headers);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ Error al eliminar rostro: $e');
      return false;
    }
  }

  /// Verifica la conexión con el servidor
  static Future<bool> checkServerHealth() async {
    try {
      final uri = Uri.parse('$_baseUrl/health');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ============================================
  // MÉTODOS AUXILIARES PARA PROCESAMIENTO LOCAL
  // (Útiles mientras implementas el backend)
  // ============================================

  /// Simula el procesamiento de embeddings localmente
  /// TODO: Reemplazar con llamada real a la API cuando esté lista
  static Future<Map<String, dynamic>> processLocalEmbeddings({
    required List<String> imagePaths,
  }) async {
    // Simulación - En producción esto se haría en el backend
    await Future.delayed(const Duration(seconds: 2));

    print('🧠 Procesando embeddings localmente (SIMULADO)...');
    print('   - Imágenes a procesar: ${imagePaths.length}');

    // Simular embeddings (en realidad serían vectores de 128 o 512 dimensiones)
    final mockEmbeddings = List.generate(128, (i) => (i * 0.01));

    return {
      'success': true,
      'embeddings': mockEmbeddings,
      'confidence': 0.92,
      'processing_time_ms': 2000,
      'note': 'SIMULADO - Reemplazar con API real',
    };
  }

  /// Prepara batch de imágenes para envío optimizado
  /// Útil cuando necesites enviar múltiples rostros
  static Future<List<Map<String, dynamic>>> prepareBatchUpload({
    required List<Map<String, dynamic>> facesData,
  }) async {
    final prepared = <Map<String, dynamic>>[];

    for (final faceData in facesData) {
      final apiData = FaceStorageService.prepareFaceDataForAPI(
        faceId: faceData['face_id'],
        name: faceData['name'],
        relationship: faceData['relationship'],
        imagePaths: faceData['image_paths'],
      );
      prepared.add(apiData);
    }

    return prepared;
  }
}

// ============================================
// EJEMPLO DE ESTRUCTURA DE RESPUESTA DE LA API
// ============================================
/*

POST /api/faces
Request:
{
  "face_id": "1234567890",
  "name": "Juan Pérez",
  "relationship": "Familiar",
  "images": [archivo1.jpg, archivo2.jpg, ...],
  "captured_at": "2025-01-15T10:30:00Z"
}

Response (200 OK):
{
  "success": true,
  "face_id": "1234567890",
  "embeddings": [0.123, 0.456, ..., 0.789], // Vector de 128-512 dimensiones
  "confidence": 0.95,
  "message": "Rostro procesado correctamente"
}

---

POST /api/faces/verify
Request:
{
  "image": archivo_captura.jpg
}

Response (200 OK):
{
  "recognized": true,
  "face_id": "1234567890",
  "name": "Juan Pérez",
  "relationship": "Familiar",
  "confidence": 0.92,
  "similarity_score": 0.88
}

*/
