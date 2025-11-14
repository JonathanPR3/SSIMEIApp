import 'package:curso/models/evidence_model.dart';
import 'package:curso/services/api_service.dart';
import 'package:curso/config/api_config.dart';

class EvidenceService {
  static final ApiService _apiService = ApiService();

  // ==========================================
  // TOGGLE PARA MODO MOCK
  // ==========================================
  static const bool useMockMode = false; // FALSE = usar API real

  // Datos demo - Solo se usan si useMockMode = true
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
  static Future<List<EvidenceModel>> getEvidences({
    int? cameraId,
    String? behaviorType,
    String? severity,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    if (useMockMode) {
      print('⚠️ MODO MOCK: Usando datos de prueba');
      await Future.delayed(const Duration(milliseconds: 400));
      return List.from(_evidences)..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    }

    try {
      print('📥 Obteniendo incidentes desde API...');

      // Construir query params
      final Map<String, dynamic> queryParams = {};
      if (cameraId != null) queryParams['camera_id'] = cameraId;
      if (behaviorType != null) queryParams['behavior_type'] = behaviorType;
      if (severity != null) queryParams['severity'] = severity;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      queryParams['limit'] = limit;

      // Construir URL con query params
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.incidents}');
      final uriWithQuery = uri.replace(queryParameters: queryParams.map((key, value) => MapEntry(key, value.toString())));

      // Cambiar el tipo genérico a Map<String, dynamic> en lugar de List<dynamic>
      final response = await _apiService.get<Map<String, dynamic>>(
        uriWithQuery.toString().replaceAll(ApiConfig.baseUrl, ''),
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        // El backend ahora devuelve: {"incidents": [...], "total": 0, ...}
        // Extraer el array de incidentes
        final jsonData = response.data!;
        final List<dynamic> incidentsData = jsonData is List
            ? jsonData
            : (jsonData['incidents'] ?? []);

        final incidents = incidentsData
            .map((json) => EvidenceModel.fromJson(json as Map<String, dynamic>))
            .toList();

        print('✅ ${incidents.length} incidentes obtenidos');
        return incidents;
      } else {
        print('❌ Error obteniendo incidentes: ${response.message}');
        return [];
      }
    } catch (e) {
      print('❌ Excepción obteniendo incidentes: $e');
      return [];
    }
  }

  // Obtener evidencias por estado
  static Future<List<EvidenceModel>> getEvidencesByStatus(EvidenceStatus status) async {
    if (useMockMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      return _evidences.where((evidence) => evidence.status == status).toList()
        ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    }

    // Para API: filtrar por is_acknowledged
    // pending = false, reviewed/resolved = true
    final isAcknowledged = status != EvidenceStatus.pending;

    try {
      final allIncidents = await getEvidences();
      return allIncidents.where((evidence) => evidence.status == status).toList()
        ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    } catch (e) {
      print('❌ Error obteniendo incidentes por estado: $e');
      return [];
    }
  }

  // Obtener evidencia por ID
  static Future<EvidenceModel?> getEvidenceById(String id) async {
    if (useMockMode) {
      await Future.delayed(const Duration(milliseconds: 200));
      try {
        return _evidences.firstWhere((evidence) => evidence.id == id);
      } catch (e) {
        return null;
      }
    }

    try {
      print('🔍 Obteniendo incidente ID: $id');

      final incidentId = int.tryParse(id);
      if (incidentId == null) {
        print('❌ ID inválido');
        return null;
      }

      final response = await _apiService.get<Map<String, dynamic>>(
        ApiConfig.incidentById(incidentId),
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        print('✅ Incidente obtenido');
        return EvidenceModel.fromJson(response.data!);
      } else {
        print('❌ Error obteniendo incidente: ${response.message}');
        return null;
      }
    } catch (e) {
      print('❌ Excepción: $e');
      return null;
    }
  }

  // Obtener estadísticas
  static Future<EvidenceStats> getStats() async {
    if (useMockMode) {
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

    try {
      print('📊 Obteniendo estadísticas...');

      final response = await _apiService.get<Map<String, dynamic>>(
        ApiConfig.incidentsStats,
        requiresAuth: true,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;

        // Obtener incidentes recientes
        final recentIncidents = await getEvidences(limit: 5);

        return EvidenceStats(
          totalEvidences: data['total_incidents'] ?? 0,
          pendingEvidences: data['pending'] ?? 0,
          reviewedEvidences: data['acknowledged'] ?? 0,
          recentEvidences: recentIncidents,
        );
      } else {
        print('❌ Error obteniendo estadísticas: ${response.message}');
        return const EvidenceStats(
          totalEvidences: 0,
          pendingEvidences: 0,
          reviewedEvidences: 0,
          recentEvidences: [],
        );
      }
    } catch (e) {
      print('❌ Error: $e');
      return const EvidenceStats(
        totalEvidences: 0,
        pendingEvidences: 0,
        reviewedEvidences: 0,
        recentEvidences: [],
      );
    }
  }

  // Actualizar estado de evidencia (reconocer incidente)
  static Future<bool> updateEvidenceStatus(
    String id,
    EvidenceStatus newStatus, {
    String? notes,
  }) async {
    if (useMockMode) {
      await Future.delayed(const Duration(milliseconds: 500));
      final int index = _evidences.indexWhere((evidence) => evidence.id == id);
      if (index != -1) {
        _evidences[index] = _evidences[index].copyWith(status: newStatus);
        return true;
      }
      return false;
    }

    try {
      print('✏️ Reconociendo incidente ID: $id');

      final incidentId = int.tryParse(id);
      if (incidentId == null) {
        print('❌ ID inválido');
        return false;
      }

      final body = {
        'notes': notes ?? 'Incidente revisado desde la app',
        'status': newStatus == EvidenceStatus.resolved ? 'CONFIRMADO' : 'EN_PROCESO',
      };

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConfig.acknowledgeIncident(incidentId),
        body: body,
        requiresAuth: true,
      );

      if (response.isSuccess) {
        print('✅ Incidente reconocido');
        return true;
      } else {
        print('❌ Error: ${response.message}');
        return false;
      }
    } catch (e) {
      print('❌ Excepción: $e');
      return false;
    }
  }

  // Eliminar evidencia (solo en modo mock, API no tiene delete)
  static Future<bool> deleteEvidence(String id) async {
    if (useMockMode) {
      await Future.delayed(const Duration(milliseconds: 400));
      _evidences.removeWhere((evidence) => evidence.id == id);
      return true;
    }

    // La API no tiene endpoint de delete para incidentes
    // Solo se pueden reconocer/actualizar
    print('⚠️ La API no permite eliminar incidentes');
    return false;
  }

  // Buscar evidencias
  static Future<List<EvidenceModel>> searchEvidences(String query) async {
    if (useMockMode) {
      await Future.delayed(const Duration(milliseconds: 600));

      final String lowercaseQuery = query.toLowerCase();
      return _evidences.where((evidence) =>
        evidence.title.toLowerCase().contains(lowercaseQuery) ||
        evidence.description.toLowerCase().contains(lowercaseQuery) ||
        evidence.cameraName.toLowerCase().contains(lowercaseQuery) ||
        evidence.type.displayName.toLowerCase().contains(lowercaseQuery)
      ).toList()..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    }

    // Para API: obtener todos y filtrar localmente
    try {
      final allIncidents = await getEvidences();
      final String lowercaseQuery = query.toLowerCase();
      return allIncidents.where((evidence) =>
        evidence.title.toLowerCase().contains(lowercaseQuery) ||
        evidence.description.toLowerCase().contains(lowercaseQuery) ||
        evidence.cameraName.toLowerCase().contains(lowercaseQuery) ||
        evidence.type.displayName.toLowerCase().contains(lowercaseQuery)
      ).toList()..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    } catch (e) {
      print('❌ Error buscando incidentes: $e');
      return [];
    }
  }

  // Obtener evidencias por cámara
  static Future<List<EvidenceModel>> getEvidencesByCamera(String cameraId) async {
    if (useMockMode) {
      await Future.delayed(const Duration(milliseconds: 350));
      return _evidences.where((evidence) => evidence.cameraId == cameraId).toList()
        ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    }

    try {
      final cameraIdInt = int.tryParse(cameraId);
      if (cameraIdInt == null) {
        print('❌ ID de cámara inválido');
        return [];
      }

      return await getEvidences(cameraId: cameraIdInt);
    } catch (e) {
      print('❌ Error obteniendo incidentes por cámara: $e');
      return [];
    }
  }
}