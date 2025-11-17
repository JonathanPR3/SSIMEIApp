import 'package:flutter/material.dart';
import 'package:curso/constants/app_constants.dart';
import 'package:curso/models/face_model.dart';
import 'package:curso/services/face_service.dart';
import 'package:curso/services/face_recognition_api_service.dart';
import 'package:curso/screens/face_capture_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManageFacesScreen extends StatefulWidget {
  final VoidCallback? onBack; // Agregar callback para regresar

  const ManageFacesScreen({
    super.key,
    this.onBack,
  });

  @override
  State<ManageFacesScreen> createState() => _ManageFacesScreenState();
}

class _ManageFacesScreenState extends State<ManageFacesScreen> {
  List<RegisteredFace> registeredFaces = []; // Rostros locales (legacy)
  List<Map<String, dynamic>> backendFaces = []; // Rostros del backend
  Map<String, dynamic> stats = {};
  bool isLoading = true;
  bool useBackend = true; // TRUE = usar backend, FALSE = usar local

  @override
  void initState() {
    super.initState();
    _loadFaces();
  }

  Future<void> _loadFaces() async {
    setState(() => isLoading = true);
    try {
      if (useBackend) {
        // Cargar desde backend
        print('🔍 Cargando rostros desde backend...');

        // DEBUG: Verificar token
        final prefs = await SharedPreferences.getInstance();
        final allKeys = prefs.getKeys();
        print('🔑 Todas las keys en SharedPreferences: $allKeys');

        final accessToken = prefs.getString('access_token');
        final authToken = prefs.getString('auth_token');
        final idToken = prefs.getString('id_token');
        final userData = prefs.getString('user_data');

        print('🔑 access_token: ${accessToken != null ? "✅ Existe" : "❌ No existe"}');
        print('🔑 auth_token: ${authToken != null ? "✅ Existe" : "❌ No existe"}');
        print('🔑 id_token: ${idToken != null ? "✅ Existe" : "❌ No existe"}');
        print('👤 user_data: ${userData != null ? "✅ Existe" : "❌ No existe"}');

        final result = await FaceRecognitionApiService.listFaces(
          type: 'all',
          page: 1,
          limit: 100,
        );

        if (result['success']) {
          print('✅ ${result['total']} rostros obtenidos del backend');
          setState(() {
            backendFaces = List<Map<String, dynamic>>.from(result['faces']);
            stats = {
              'total_registered': result['total'],
              'remaining_slots': 100 - result['total'], // Sin límite real
              'recently_seen': 0, // TODO: calcular desde backend
            };
            isLoading = false;
          });
        } else {
          throw Exception(result['message']);
        }
      } else {
        // Cargar desde local (legacy)
        final results = await Future.wait([
          FaceService.getRegisteredFaces(),
          FaceService.getFaceStats(),
        ]);

        setState(() {
          registeredFaces = results[0] as List<RegisteredFace>;
          stats = results[1] as Map<String, dynamic>;
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error al cargar rostros: $e');
      setState(() => isLoading = false);
      _showErrorSnackBar('Error al cargar los rostros: $e');
    }
  }

  Future<void> _addNewFace() async {
    // Si usa backend, no hay límite de rostros
    if (!useBackend && !FaceService.canAddNewFace()) {
      _showErrorSnackBar('Máximo de ${FaceService.maxFaces} rostros alcanzado');
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FaceCaptureScreen(),
      ),
    );

    if (result == true) {
      _loadFaces();
    }
  }

  Future<void> _deleteFace(dynamic face) async {
    // Obtener nombre según tipo de rostro
    String name;
    int backendFaceId; // Para backend (int)
    String localFaceId; // Para local (String)

    if (face is RegisteredFace) {
      // Rostro local
      name = face.name;
      localFaceId = face.id;
      backendFaceId = int.tryParse(face.id) ?? 0;
    } else if (face is Map<String, dynamic>) {
      // Rostro del backend
      name = face['display_name'] ?? 'este rostro';
      final id = face['id'];
      if (id is int) {
        backendFaceId = id;
        localFaceId = id.toString();
      } else if (id is String) {
        backendFaceId = int.tryParse(id) ?? 0;
        localFaceId = id;
      } else {
        backendFaceId = id as int;
        localFaceId = id.toString();
      }
    } else {
      _showErrorSnackBar('Error: tipo de rostro inválido');
      return;
    }

    final confirmed = await _showConfirmDialog(
      'Eliminar Rostro',
      '¿Estás seguro de que quieres eliminar el rostro de $name?',
    );

    if (confirmed) {
      try {
        if (useBackend) {
          // Backend espera int
          final result = await FaceRecognitionApiService.deleteFace(backendFaceId);
          if (result['success']) {
            _showSuccessSnackBar('Rostro eliminado correctamente del servidor');
            _loadFaces();
          } else {
            _showErrorSnackBar(result['message']);
          }
        } else {
          // Local espera String
          final success = await FaceService.deleteFace(localFaceId);
          if (success) {
            _showSuccessSnackBar('Rostro eliminado correctamente');
            _loadFaces();
          }
        }
      } catch (e) {
        _showErrorSnackBar('Error al eliminar el rostro: $e');
      }
    }
  }

  Future<void> _toggleFaceStatus(RegisteredFace face) async {
    final newStatus = face.status == FaceStatus.active 
        ? FaceStatus.inactive 
        : FaceStatus.active;

    try {
      final success = await FaceService.updateFaceStatus(face.id, newStatus);
      if (success) {
        _showSuccessSnackBar(
          'Rostro ${newStatus == FaceStatus.active ? 'activado' : 'desactivado'}'
        );
        _loadFaces();
      }
    } catch (e) {
      _showErrorSnackBar('Error al actualizar el estado');
    }
  }

  Color _getStatusColor(FaceStatus status) {
    switch (status) {
      case FaceStatus.active:
        return AppConstants.success;
      case FaceStatus.inactive:
        return Colors.grey;
      case FaceStatus.processing:
        return AppConstants.orange;
    }
  }

  IconData _getStatusIcon(FaceStatus status) {
    switch (status) {
      case FaceStatus.active:
        return Icons.check_circle;
      case FaceStatus.inactive:
        return Icons.pause_circle;
      case FaceStatus.processing:
        return Icons.hourglass_empty;
    }
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Nunca';
    
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 30) return 'Hace ${diff.inDays}d';
    return 'Hace más de 30 días';
  }

  Widget _buildStatsHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.face, color: AppConstants.primaryBlue, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Rostros Autorizados',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  label: 'Registrados',
                  value: '${stats['total_registered'] ?? 0}/${FaceService.maxFaces}',
                  color: AppConstants.primaryBlue,
                  icon: Icons.group,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  label: 'Disponibles',
                  value: '${stats['remaining_slots'] ?? 0}',
                  color: AppConstants.success,
                  icon: Icons.add_circle_outline,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  label: 'Vistos hoy',
                  value: '${stats['recently_seen'] ?? 0}',
                  color: AppConstants.orange,
                  icon: Icons.visibility,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFaceCard(RegisteredFace face) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(face.status).withAlpha(100),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppConstants.primaryBlue.withAlpha(200),
                    AppConstants.primaryBlue.withAlpha(150),
                  ],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Primera fila: Nombre
                  Text(
                    face.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  
                  // Segunda fila: Relación y estado
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          face.relationship,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(face.status).withAlpha(50),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(face.status),
                                color: _getStatusColor(face.status),
                                size: 12,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  face.status.displayName,
                                  style: TextStyle(
                                    color: _getStatusColor(face.status),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Tercera fila: Información adicional (más compacta)
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.grey[500], size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${_formatLastSeen(face.lastSeen)} • ${(face.keypoints.confidence * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
              color: const Color(0xFF1E1E2E),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        face.status == FaceStatus.active 
                            ? Icons.pause_circle 
                            : Icons.play_circle,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        face.status == FaceStatus.active ? 'Desactivar' : 'Activar',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: AppConstants.error, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        'Eliminar',
                        style: TextStyle(color: AppConstants.error),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'toggle':
                    _toggleFaceStatus(face);
                    break;
                  case 'delete':
                    _deleteFace(face);
                    break;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackendFaceCard(Map<String, dynamic> face) {
    // Adaptar datos del backend al formato de la UI
    final String displayName = face['display_name'] ?? 'Sin nombre';
    final String type = face['type'] ?? 'unknown';
    final String createdAt = face['created_at'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.primaryBlue.withAlpha(100),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppConstants.primaryBlue.withAlpha(200),
                    AppConstants.primaryBlue.withAlpha(150),
                  ],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        type == 'registered_user' ? Icons.verified_user : Icons.badge_outlined,
                        color: type == 'registered_user' ? Colors.green : Colors.orange,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        type == 'registered_user' ? 'Usuario' : 'Visitante',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, color: Colors.grey[500], size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatCreatedAt(createdAt),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
              color: const Color(0xFF1E1E2E),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: AppConstants.error, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        'Eliminar',
                        style: TextStyle(color: AppConstants.error),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteFace(face);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatCreatedAt(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return 'Fecha desconocida';

    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Ahora';
      if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
      if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
      if (diff.inDays < 30) return 'Hace ${diff.inDays}d';
      return 'Hace ${(diff.inDays / 30).floor()} meses';
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  Widget _buildAddFaceButton() {
    final canAdd = useBackend ? true : FaceService.canAddNewFace();

    return Container(
      margin: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: canAdd ? _addNewFace : null,
          icon: const Icon(Icons.add_a_photo),
          label: Text(
            canAdd
                ? 'Registrar Nuevo Rostro'
                : (useBackend
                    ? 'Registrar Nuevo Rostro'
                    : 'Máximo de ${FaceService.maxFaces} rostros alcanzado'),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: canAdd ? AppConstants.primaryBlue : Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E1E2E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E2E),
          foregroundColor: Colors.white,
          title: const Text('Gestionar Rostros'),
          elevation: 0,
          leading: widget.onBack != null 
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                )
              : null,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppConstants.primaryBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2E),
        foregroundColor: Colors.white,
        title: const Text('Gestionar Rostros'),
        elevation: 0,
        leading: widget.onBack != null 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFaces,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFaces,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildStatsHeader(),
              _buildAddFaceButton(),
              
              if (useBackend && backendFaces.isEmpty) ...[
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A3E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.face_retouching_off,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay rostros registrados',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Registra rostros autorizados para mejorar la seguridad',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (useBackend) ...[
                // Mostrar rostros del backend
                ...backendFaces.map((face) => _buildBackendFaceCard(face)),
              ] else if (registeredFaces.isEmpty) ...[
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A3E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.face_retouching_off,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay rostros registrados',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Registra rostros autorizados para mejorar la seguridad',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                ...registeredFaces.map((face) => _buildFaceCard(face)),
              ],
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}