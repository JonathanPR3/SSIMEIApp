import 'package:flutter/material.dart';
import 'package:curso/constants/app_constants.dart';
import 'package:curso/models/face_model.dart';
import 'package:curso/services/face_service.dart';
import 'package:curso/screens/face_capture_screen.dart';

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
  List<RegisteredFace> registeredFaces = [];
  Map<String, dynamic> stats = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFaces();
  }

  Future<void> _loadFaces() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        FaceService.getRegisteredFaces(),
        FaceService.getFaceStats(),
      ]);
      
      setState(() {
        registeredFaces = results[0] as List<RegisteredFace>;
        stats = results[1] as Map<String, dynamic>;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Error al cargar los rostros registrados');
    }
  }

  Future<void> _addNewFace() async {
    if (!FaceService.canAddNewFace()) {
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

  Future<void> _deleteFace(RegisteredFace face) async {
    final confirmed = await _showConfirmDialog(
      'Eliminar Rostro',
      '¿Estás seguro de que quieres eliminar el rostro de ${face.name}?',
    );

    if (confirmed) {
      try {
        final success = await FaceService.deleteFace(face.id);
        if (success) {
          _showSuccessSnackBar('Rostro eliminado correctamente');
          _loadFaces();
        }
      } catch (e) {
        _showErrorSnackBar('Error al eliminar el rostro');
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

  Widget _buildAddFaceButton() {
    final canAdd = FaceService.canAddNewFace();
    
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
                : 'Máximo de ${FaceService.maxFaces} rostros alcanzado',
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
              
              if (registeredFaces.isEmpty) ...[
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