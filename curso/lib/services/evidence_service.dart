import 'package:curso/models/evidence_model.dart';

class EvidenceService {
  // Datos demo - En futuro será reemplazado por API calls
  static List<EvidenceModel> _evidences = [
    EvidenceModel(
      id: '1',
      title: 'Pose sospechosa detectada en entrada',
      description: 'Se detectó una pose inusual en la entrada principal que podría indicar actividad sospechosa de merodeador',
      type: EvidenceType.suspiciousPose,
      status: EvidenceStatus.pending,
      cameraId: '1',
      cameraName: 'Cámara Entrada Principal',
      detectedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      videoFragments: [
        VideoFragment(
          id: 'v1',
          videoUrl: 'https://demo-videos.com/fragment1.mp4',
          thumbnailUrl: 'https://demo-images.com/thumb1.jpg',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          duration: const Duration(seconds: 15),
          description: 'Momento de detección de pose sospechosa',
        ),
        VideoFragment(
          id: 'v2',
          videoUrl: 'https://demo-videos.com/fragment2.mp4',
          thumbnailUrl: 'https://demo-images.com/thumb2.jpg',
          timestamp: DateTime.now().subtract(const Duration(minutes: 4, seconds: 45)),
          duration: const Duration(seconds: 10),
          description: 'Continuación del comportamiento sospechoso',
        ),
      ],
      metadata: {
        'confidence': 0.87,
        'pose_detection_algorithm': 'pose_detection_v2.1',
        'coordinates': {'x': 245, 'y': 180, 'width': 120, 'height': 200}
      },
    ),
    EvidenceModel(
      id: '2',
      title: 'Persona no autorizada detectada',
      description: 'Rostro no reconocido detectado en el perímetro de la casa durante horario nocturno',
      type: EvidenceType.unauthorizedPerson,
      status: EvidenceStatus.reviewed,
      cameraId: '2',
      cameraName: 'Cámara Jardín Trasero',
      detectedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      videoFragments: [
        VideoFragment(
          id: 'v3',
          videoUrl: 'https://demo-videos.com/fragment3.mp4',
          thumbnailUrl: 'https://demo-images.com/thumb3.jpg',
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
          duration: const Duration(seconds: 20),
          description: 'Detección de persona no autorizada',
        ),
      ],
      metadata: {
        'face_recognition_confidence': 0.95,
        'person_count': 1,
        'unknown_face': true
      },
    ),
    EvidenceModel(
      id: '3',
      title: 'Comportamiento sospechoso en ventana',
      description: 'Pose detectada cerca de ventana lateral, posible intento de reconocimiento del interior',
      type: EvidenceType.suspiciousPose,
      status: EvidenceStatus.resolved,
      cameraId: '3',
      cameraName: 'Cámara Lateral Derecha',
      detectedAt: DateTime.now().subtract(const Duration(hours: 1)),
      videoFragments: [
        VideoFragment(
          id: 'v4',
          videoUrl: 'https://demo-videos.com/fragment4.mp4',
          thumbnailUrl: 'https://demo-images.com/thumb4.jpg',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          duration: const Duration(seconds: 18),
          description: 'Persona inspeccionando ventana',
        ),
      ],
      metadata: {
        'confidence': 0.82,
        'near_window': true,
        'duration_seconds': 45
      },
    ),
    EvidenceModel(
      id: '4',
      title: 'Rostro desconocido en perímetro',
      description: 'Persona no autorizada detectada merodeando cerca de la entrada del garaje',
      type: EvidenceType.unauthorizedPerson,
      status: EvidenceStatus.pending,
      cameraId: '4',
      cameraName: 'Cámara Garaje',
      detectedAt: DateTime.now().subtract(const Duration(minutes: 32)),
      videoFragments: [
        VideoFragment(
          id: 'v5',
          videoUrl: 'https://demo-videos.com/fragment5.mp4',
          thumbnailUrl: 'https://demo-images.com/thumb5.jpg',
          timestamp: DateTime.now().subtract(const Duration(minutes: 32)),
          duration: const Duration(seconds: 25),
          description: 'Persona no autorizada cerca del garaje',
        ),
      ],
      metadata: {
        'face_recognition_confidence': 0.91,
        'person_count': 1,
        'unknown_face': true,
        'near_garage': true
      },
    ),
    EvidenceModel(
      id: '5',
      title: 'Pose sospechosa en jardín frontal',
      description: 'Comportamiento anómalo detectado en el jardín frontal, persona agachándose cerca de arbustos',
      type: EvidenceType.suspiciousPose,
      status: EvidenceStatus.pending,
      cameraId: '1',
      cameraName: 'Cámara Entrada Principal',
      detectedAt: DateTime.now().subtract(const Duration(hours: 2)),
      videoFragments: [
        VideoFragment(
          id: 'v6',
          videoUrl: 'https://demo-videos.com/fragment6.mp4',
          thumbnailUrl: 'https://demo-images.com/thumb6.jpg',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          duration: const Duration(seconds: 12),
          description: 'Pose sospechosa en jardín frontal',
        ),
      ],
      metadata: {
        'confidence': 0.78,
        'pose_type': 'crouching',
        'near_bushes': true
      },
    ),
  ];

  // Obtener todas las evidencias
  static Future<List<EvidenceModel>> getEvidences() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_evidences)..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
  }

  // Obtener evidencias por estado
  static Future<List<EvidenceModel>> getEvidencesByStatus(EvidenceStatus status) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _evidences.where((evidence) => evidence.status == status).toList()
      ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
  }

  // Obtener evidencia por ID
  static Future<EvidenceModel?> getEvidenceById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _evidences.firstWhere((evidence) => evidence.id == id);
    } catch (e) {
      return null;
    }
  }

  // Obtener estadísticas
  static Future<EvidenceStats> getStats() async {
    await Future.delayed(const Duration(milliseconds: 250));
    
    final int pending = _evidences.where((e) => e.status == EvidenceStatus.pending).length;
    final int reviewed = _evidences.where((e) => e.status == EvidenceStatus.reviewed).length;
    final List<EvidenceModel> recent = _evidences
      .where((e) => DateTime.now().difference(e.detectedAt).inHours < 24)
      .toList()
      ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));

    return EvidenceStats(
      totalEvidences: _evidences.length,
      pendingEvidences: pending,
      reviewedEvidences: reviewed,
      recentEvidences: recent.take(5).toList(),
    );
  }

  // Actualizar estado de evidencia
  static Future<bool> updateEvidenceStatus(String id, EvidenceStatus newStatus) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final int index = _evidences.indexWhere((evidence) => evidence.id == id);
    if (index != -1) {
      _evidences[index] = _evidences[index].copyWith(status: newStatus);
      return true;
    }
    return false;
  }

  // Eliminar evidencia
  static Future<bool> deleteEvidence(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _evidences.removeWhere((evidence) => evidence.id == id);
    return true;
  }

  // Buscar evidencias
  static Future<List<EvidenceModel>> searchEvidences(String query) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    final String lowercaseQuery = query.toLowerCase();
    return _evidences.where((evidence) =>
      evidence.title.toLowerCase().contains(lowercaseQuery) ||
      evidence.description.toLowerCase().contains(lowercaseQuery) ||
      evidence.cameraName.toLowerCase().contains(lowercaseQuery) ||
      evidence.type.displayName.toLowerCase().contains(lowercaseQuery)
    ).toList()..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
  }

  // Obtener evidencias por cámara
  static Future<List<EvidenceModel>> getEvidencesByCamera(String cameraId) async {
    await Future.delayed(const Duration(milliseconds: 350));
    return _evidences.where((evidence) => evidence.cameraId == cameraId).toList()
      ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
  }
}