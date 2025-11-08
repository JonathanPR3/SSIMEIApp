import 'package:flutter/material.dart';
import 'package:curso/constants/app_constants.dart';
import 'package:curso/models/camera_model.dart';
import 'package:curso/models/camera_permission_model.dart';
import 'package:curso/services/camera_service.dart';
import 'package:curso/services/camera_permission_service.dart';

/// Pantalla para gestionar qué cámaras puede ver un usuario específico
///
/// Solo accesible para ADMIN
/// Muestra todas las cámaras de la organización con checkboxes
/// para otorgar/revocar permisos
class ManageUserCamerasScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final String userEmail;

  const ManageUserCamerasScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<ManageUserCamerasScreen> createState() => _ManageUserCamerasScreenState();
}

class _ManageUserCamerasScreenState extends State<ManageUserCamerasScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  List<CameraWithPermission> _cameras = [];
  int _initialPermissionCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Cargar en paralelo: todas las cámaras y las cámaras del usuario
      final results = await Future.wait([
        CameraService.getCameras(), // Todas las cámaras de la org
        CameraPermissionService.getUserCameras(widget.userId), // Cámaras con permiso
      ]);

      final allCameras = results[0] as List<CameraModel>;
      final userCameras = results[1] as List<CameraModel>;

      // Crear Set de IDs de cámaras con permiso para búsqueda rápida
      final userCameraIds = userCameras.map((c) => int.parse(c.id)).toSet();

      // Crear lista combinada
      final camerasWithPermission = allCameras.map((camera) {
        final cameraId = int.parse(camera.id);
        return CameraWithPermission.fromCameraModel(
          camera,
          hasPermission: userCameraIds.contains(cameraId),
        );
      }).toList();

      setState(() {
        _cameras = camerasWithPermission;
        _initialPermissionCount = userCameraIds.length;
        _isLoading = false;
      });

      print('✅ ${_cameras.length} cámaras cargadas, ${_initialPermissionCount} con permiso');
    } catch (e) {
      print('❌ Error cargando datos: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error al cargar las cámaras: ${e.toString()}');
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      // Obtener IDs de cámaras seleccionadas
      final selectedCameraIds = _cameras
          .where((c) => c.hasPermission)
          .map((c) => c.cameraId)
          .toList();

      // Primero revocar todos los permisos actuales
      final revokedCount = await CameraPermissionService.revokeAllUserPermissions(widget.userId);
      print('🗑️ $revokedCount permisos anteriores revocados');

      // Luego otorgar los nuevos permisos seleccionados
      if (selectedCameraIds.isNotEmpty) {
        final result = await CameraPermissionService.grantBatchCameraAccess(
          userId: widget.userId,
          cameraIds: selectedCameraIds,
        );

        final granted = result['total_granted'] as int? ?? 0;
        print('✅ $granted permisos otorgados');

        _showSuccessSnackBar('Permisos actualizados: $granted cámaras asignadas');
      } else {
        _showSuccessSnackBar('Todos los permisos han sido revocados');
      }

      setState(() {
        _isSaving = false;
        _initialPermissionCount = selectedCameraIds.length;
      });

      // Pequeño delay para que se vea el snackbar antes de volver
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.pop(context, true); // true indica que hubo cambios
      }
    } catch (e) {
      print('❌ Error guardando cambios: $e');
      setState(() => _isSaving = false);
      _showErrorSnackBar('Error al guardar cambios: ${e.toString()}');
    }
  }

  void _toggleCamera(int index) {
    setState(() {
      _cameras[index].hasPermission = !_cameras[index].hasPermission;
    });
  }

  bool _hasChanges() {
    final currentCount = _cameras.where((c) => c.hasPermission).length;
    return currentCount != _initialPermissionCount;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _cameras.where((c) => c.hasPermission).length;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A3E),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestionar Cámaras',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.userName,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppConstants.primaryBlue,
              ),
            )
          : Column(
              children: [
                // Header con stats
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A3E),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total Cámaras',
                              '${_cameras.length}',
                              Icons.videocam,
                              Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Con Acceso',
                              '$selectedCount',
                              Icons.check_circle,
                              AppConstants.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Sin Acceso',
                              '${_cameras.length - selectedCount}',
                              Icons.cancel,
                              AppConstants.error.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Lista de cámaras
                Expanded(
                  child: _cameras.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _cameras.length,
                          itemBuilder: (context, index) {
                            return _buildCameraCard(_cameras[index], index);
                          },
                        ),
                ),

                // Botón guardar (sticky en la parte inferior)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A3E),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving || !_hasChanges()
                            ? null
                            : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryBlue,
                          disabledBackgroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _hasChanges()
                                    ? 'Guardar Cambios'
                                    : 'Sin Cambios',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCameraCard(CameraWithPermission camera, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: camera.hasPermission
              ? AppConstants.success.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: CheckboxListTile(
        value: camera.hasPermission,
        onChanged: (value) => _toggleCamera(index),
        activeColor: AppConstants.success,
        checkColor: Colors.white,
        title: Text(
          camera.cameraName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (camera.cameraLocation != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.white54),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      camera.cameraLocation!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (camera.ipAddress != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.router, size: 14, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(
                    camera.ipAddress!,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: camera.hasPermission
                ? AppConstants.success.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.videocam,
            color: camera.hasPermission
                ? AppConstants.success
                : Colors.white54,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay cámaras disponibles',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea cámaras primero en "Gestión de Cámaras"',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
