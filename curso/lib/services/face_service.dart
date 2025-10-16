import 'package:curso/models/face_model.dart';
import 'dart:math';

class FaceService {
  static const int maxFaces = 5;
  
  // Datos demo - En futuro será reemplazado por API calls
  static List<RegisteredFace> _registeredFaces = [
    RegisteredFace(
      id: '1',
      name: 'María González',
      relationship: 'Propietaria',
      imageUrl: 'https://demo-faces.com/face1.jpg',
      keypoints: FaceKeypoints(
        landmarks: [
          {'x': 125.4, 'y': 89.2},
          {'x': 134.1, 'y': 92.8},
          {'x': 142.7, 'y': 98.5},
        ],
        encoding: 'encoded_face_data_1',
        confidence: 0.95,
      ),
      status: FaceStatus.active,
      registeredAt: DateTime.now().subtract(const Duration(days: 30)),
      lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    RegisteredFace(
      id: '2',
      name: 'Juan Carlos',
      relationship: 'Familiar',
      imageUrl: 'https://demo-faces.com/face2.jpg',
      keypoints: FaceKeypoints(
        landmarks: [
          {'x': 128.9, 'y': 91.3},
          {'x': 137.2, 'y': 94.7},
          {'x': 145.8, 'y': 99.1},
        ],
        encoding: 'encoded_face_data_2',
        confidence: 0.92,
      ),
      status: FaceStatus.active,
      registeredAt: DateTime.now().subtract(const Duration(days: 15)),
      lastSeen: DateTime.now().subtract(const Duration(days: 1)),
    ),
    RegisteredFace(
      id: '3',
      name: 'Ana Martínez',
      relationship: 'Empleada doméstica',
      imageUrl: 'https://demo-faces.com/face3.jpg',
      keypoints: FaceKeypoints(
        landmarks: [
          {'x': 122.7, 'y': 87.9},
          {'x': 131.5, 'y': 91.2},
          {'x': 140.3, 'y': 96.8},
        ],
        encoding: 'encoded_face_data_3',
        confidence: 0.89,
      ),
      status: FaceStatus.active,
      registeredAt: DateTime.now().subtract(const Duration(days: 7)),
      lastSeen: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  ];

  // Obtener todos los rostros registrados
  static Future<List<RegisteredFace>> getRegisteredFaces() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_registeredFaces)
      ..sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
  }

  // Obtener rostro por ID
  static Future<RegisteredFace?> getFaceById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _registeredFaces.firstWhere((face) => face.id == id);
    } catch (e) {
      return null;
    }
  }

  // Verificar si se puede agregar un nuevo rostro
  static bool canAddNewFace() {
    return _registeredFaces.length < maxFaces;
  }

  // Obtener cuántos rostros quedan por agregar
  static int getRemainingSlots() {
    return maxFaces - _registeredFaces.length;
  }

  // Registrar nuevo rostro
  static Future<RegisteredFace> registerFace({
    required String name,
    required String relationship,
    required String imageUrl,
    required Map<String, dynamic> processingResult,
  }) async {
    // Simular procesamiento de IA
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!canAddNewFace()) {
      throw Exception('Máximo de $maxFaces rostros alcanzado');
    }

    // Generar keypoints simulados basados en el "processingResult"
    final keypoints = _generateMockKeypoints(processingResult);
    
    final newFace = RegisteredFace(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      relationship: relationship,
      imageUrl: imageUrl,
      keypoints: keypoints,
      status: FaceStatus.active,
      registeredAt: DateTime.now(),
    );

    _registeredFaces.add(newFace);
    return newFace;
  }

  // Generar keypoints simulados (para demostración)
  static FaceKeypoints _generateMockKeypoints(Map<String, dynamic> processingResult) {
    final random = Random();
    
    // Simular landmarks faciales (68 puntos estándar)
    final landmarks = List.generate(68, (index) => {
      'x': 100 + random.nextDouble() * 100,
      'y': 80 + random.nextDouble() * 120,
    });

    return FaceKeypoints(
      landmarks: landmarks,
      encoding: 'mock_encoding_${DateTime.now().millisecondsSinceEpoch}',
      confidence: 0.85 + random.nextDouble() * 0.15, // 0.85 - 1.0
    );
  }

  // Actualizar estado de un rostro
  static Future<bool> updateFaceStatus(String id, FaceStatus newStatus) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    final index = _registeredFaces.indexWhere((face) => face.id == id);
    if (index != -1) {
      _registeredFaces[index] = _registeredFaces[index].copyWith(status: newStatus);
      return true;
    }
    return false;
  }

  // Eliminar rostro
  static Future<bool> deleteFace(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final initialLength = _registeredFaces.length;
    _registeredFaces.removeWhere((face) => face.id == id);
    
    return _registeredFaces.length < initialLength;
  }

  // Actualizar información de un rostro
  static Future<bool> updateFace(String id, {
    String? name,
    String? relationship,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    final index = _registeredFaces.indexWhere((face) => face.id == id);
    if (index != -1) {
      _registeredFaces[index] = _registeredFaces[index].copyWith(
        name: name ?? _registeredFaces[index].name,
        relationship: relationship ?? _registeredFaces[index].relationship,
      );
      return true;
    }
    return false;
  }

  // Simular proceso de verificación facial (para captura)
  static Future<Map<String, dynamic>> processFaceCapture({
    required String imageData,
    required int stepNumber,
  }) async {
    // Simular tiempo de procesamiento de IA
    await Future.delayed(Duration(milliseconds: 800 + stepNumber * 200));
    
    final random = Random();
    final confidence = 0.7 + random.nextDouble() * 0.3;
    
    return {
      'step': stepNumber,
      'confidence': confidence,
      'face_detected': confidence > 0.75,
      'quality_score': confidence,
      'landmarks_count': 68,
      'processing_time': 800 + stepNumber * 200,
      'next_instruction': _getNextInstruction(stepNumber),
    };
  }

  // Obtener instrucciones para cada paso
  static String _getNextInstruction(int step) {
    switch (step) {
      case 1:
        return 'Mantén tu rostro centrado y mira directamente a la cámara';
      case 2:
        return 'Gira ligeramente la cabeza hacia la izquierda';
      case 3:
        return 'Gira ligeramente la cabeza hacia la derecha';
      case 4:
        return 'Sonríe naturalmente';
      case 5:
        return 'Mantén una expresión neutral';
      default:
        return 'Procesando...';
    }
  }

  // Obtener estadísticas
  static Future<Map<String, dynamic>> getFaceStats() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final activeFaces = _registeredFaces.where((f) => f.status == FaceStatus.active).length;
    final recentlySeenFaces = _registeredFaces.where((f) => 
      f.lastSeen != null && 
      DateTime.now().difference(f.lastSeen!).inHours < 24
    ).length;
    
    return {
      'total_registered': _registeredFaces.length,
      'active_faces': activeFaces,
      'remaining_slots': getRemainingSlots(),
      'recently_seen': recentlySeenFaces,
    };
  }
}