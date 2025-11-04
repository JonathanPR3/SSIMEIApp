import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:camera/camera.dart';

/// Servicio para almacenar imágenes faciales localmente
/// y prepararlas para envío posterior a la API
class FaceStorageService {
  // Directorio base para almacenar rostros
  static const String _facesFolderName = 'registered_faces';

  /// Obtiene el directorio donde se almacenarán las imágenes de rostros
  static Future<Directory> _getFacesDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final facesDir = Directory('${appDocDir.path}/$_facesFolderName');

    if (!await facesDir.exists()) {
      await facesDir.create(recursive: true);
    }

    return facesDir;
  }

  /// Guarda una imagen capturada localmente
  /// Retorna la ruta del archivo guardado
  static Future<String> saveCapturedImage({
    required XFile imageFile,
    required String faceId,
    required int stepNumber,
  }) async {
    try {
      final facesDir = await _getFacesDirectory();
      final faceFolder = Directory('${facesDir.path}/$faceId');

      if (!await faceFolder.exists()) {
        await faceFolder.create(recursive: true);
      }

      // Nombre del archivo: face_id_step_timestamp.jpg
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${faceId}_step${stepNumber}_$timestamp.jpg';
      final filePath = '${faceFolder.path}/$fileName';

      // Copiar archivo a la ubicación permanente
      final bytes = await imageFile.readAsBytes();
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      return filePath;
    } catch (e) {
      throw Exception('Error al guardar imagen: $e');
    }
  }

  /// Guarda múltiples imágenes de un proceso de captura completo
  /// Retorna lista de rutas de archivos guardados
  static Future<List<String>> saveMultipleCaptureImages({
    required List<XFile> imageFiles,
    required String faceId,
  }) async {
    final savedPaths = <String>[];

    for (int i = 0; i < imageFiles.length; i++) {
      final path = await saveCapturedImage(
        imageFile: imageFiles[i],
        faceId: faceId,
        stepNumber: i + 1,
      );
      savedPaths.add(path);
    }

    return savedPaths;
  }

  /// Guarda imagen desde bytes directamente
  static Future<String> saveImageFromBytes({
    required Uint8List bytes,
    required String faceId,
    required int stepNumber,
  }) async {
    try {
      final facesDir = await _getFacesDirectory();
      final faceFolder = Directory('${facesDir.path}/$faceId');

      if (!await faceFolder.exists()) {
        await faceFolder.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${faceId}_step${stepNumber}_$timestamp.jpg';
      final filePath = '${faceFolder.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      return filePath;
    } catch (e) {
      throw Exception('Error al guardar imagen desde bytes: $e');
    }
  }

  /// Obtiene todas las imágenes guardadas de un rostro específico
  static Future<List<File>> getFaceImages(String faceId) async {
    try {
      final facesDir = await _getFacesDirectory();
      final faceFolder = Directory('${facesDir.path}/$faceId');

      if (!await faceFolder.exists()) {
        return [];
      }

      final files = await faceFolder.list().toList();
      return files
          .whereType<File>()
          .where((file) => file.path.endsWith('.jpg') || file.path.endsWith('.png'))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener imágenes: $e');
    }
  }

  /// Elimina todas las imágenes de un rostro específico
  static Future<bool> deleteFaceImages(String faceId) async {
    try {
      final facesDir = await _getFacesDirectory();
      final faceFolder = Directory('${facesDir.path}/$faceId');

      if (await faceFolder.exists()) {
        await faceFolder.delete(recursive: true);
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Error al eliminar imágenes: $e');
    }
  }

  /// Obtiene el tamaño total de almacenamiento usado por rostros
  static Future<int> getTotalStorageSize() async {
    try {
      final facesDir = await _getFacesDirectory();
      int totalSize = 0;

      await for (final entity in facesDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Formatea el tamaño en bytes a formato legible (KB, MB)
  static String formatStorageSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Prepara los datos para envío a API (estructura lista para backend)
  /// NOTA: Este método está preparado para cuando implementes la API
  static Map<String, dynamic> prepareFaceDataForAPI({
    required String faceId,
    required String name,
    required String relationship,
    required List<String> imagePaths,
  }) {
    return {
      'face_id': faceId,
      'name': name,
      'relationship': relationship,
      'images_count': imagePaths.length,
      'image_paths': imagePaths,
      'captured_at': DateTime.now().toIso8601String(),
      'device_info': {
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
      },
      // Aquí irían los embeddings cuando los proceses
      'embeddings': null, // Se llenará después del procesamiento
    };
  }

  /// Limpia todas las imágenes temporales o antiguas
  static Future<void> cleanupOldImages({int daysOld = 30}) async {
    try {
      final facesDir = await _getFacesDirectory();
      final now = DateTime.now();

      await for (final entity in facesDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = now.difference(stat.modified).inDays;

          if (age > daysOld) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      throw Exception('Error al limpiar imágenes antiguas: $e');
    }
  }

  /// Verifica si hay espacio suficiente en el dispositivo
  /// (aproximado - Flutter no tiene API nativa para esto)
  static Future<bool> hasEnoughSpace({int requiredMB = 10}) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      // Esta es una verificación básica, podrías implementar algo más robusto
      return true; // Por defecto asumimos que hay espacio
    } catch (e) {
      return false;
    }
  }
}
