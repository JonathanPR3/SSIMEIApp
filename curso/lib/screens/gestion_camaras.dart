import 'package:flutter/material.dart';
import 'package:curso/screens/VistaCamara.dart';
import 'package:curso/constants/app_constants.dart';
import 'package:curso/models/camera_model.dart';
import 'package:curso/services/camera_service.dart';
import 'package:curso/widgets/cameras/camera_widgets.dart';

class GestionCamaras extends StatefulWidget {
  const GestionCamaras({super.key});

  @override
  State<GestionCamaras> createState() => _GestionCamarasState();
}

class _GestionCamarasState extends State<GestionCamaras> {
  List<CameraModel> cameras = [];
  CameraStats? stats;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        CameraService.getCameras(),
        CameraService.getStats(),
      ]);
      setState(() {
        cameras = results[0] as List<CameraModel>;
        stats = results[1] as CameraStats;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Error al cargar las cámaras');
    }
  }

  Future<void> _addCamera(String name, String location, String url) async {
    try {
      final success = await CameraService.addCamera(
        name: name,
        location: location,
        rtspUrl: url,
      );
      if (success) {
        _showSuccessSnackBar('Cámara agregada exitosamente');
        _loadData();
        // Navegar a ver la cámara
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VistaCamara(rtspUrl: url),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error al agregar la cámara');
    }
  }

  Future<void> _deleteCamera(CameraModel camera) async {
    final confirmed = await _showConfirmDialog(
      'Eliminar Cámara',
      '¿Estás seguro de que quieres eliminar "${camera.name}"?',
    );
    
    if (confirmed) {
      try {
        final success = await CameraService.deleteCamera(camera.id);
        if (success) {
          _showSuccessSnackBar('Cámara eliminada');
          _loadData();
        }
      } catch (e) {
        _showErrorSnackBar('Error al eliminar la cámara');
      }
    }
  }

  Future<void> _reconnectCamera(CameraModel camera) async {
    try {
      final success = await CameraService.reconnectCamera(camera.id);
      if (success) {
        _showSuccessSnackBar('Cámara reconectada');
        _loadData();
      }
    } catch (e) {
      _showErrorSnackBar('Error al reconectar la cámara');
    }
  }

  void _viewCamera(CameraModel camera) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VistaCamara(rtspUrl: camera.rtspUrl),
      ),
    );
  }

  void _showAddCameraDialog() {
    showDialog(
      context: context,
      builder: (context) => AddCameraDialog(onAdd: _addCamera),
    );
  }

  void _showCameraMenu(CameraModel camera) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A3E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildCameraMenu(camera),
    );
  }

  Widget _buildCameraMenu(CameraModel camera) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            camera.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          _buildMenuOption(
            icon: Icons.edit,
            title: 'Editar',
            onTap: () {
              Navigator.pop(context);
              // TODO: Implementar edición
              _showInfoSnackBar('Función de edición próximamente');
            },
          ),
          _buildMenuOption(
            icon: Icons.refresh,
            title: 'Reconectar',
            onTap: () {
              Navigator.pop(context);
              _reconnectCamera(camera);
            },
          ),
          _buildMenuOption(
            icon: Icons.delete,
            title: 'Eliminar',
            isDestructive: true,
            onTap: () {
              Navigator.pop(context);
              _deleteCamera(camera);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppConstants.error : Colors.white,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppConstants.error : Colors.white,
        ),
      ),
      onTap: onTap,
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

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.primaryBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E1E2E),
        body: Center(
          child: CircularProgressIndicator(color: AppConstants.primaryBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            if (stats != null) CameraStatsCard(stats: stats!),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: cameras.length,
                itemBuilder: (context, index) {
                  final camera = cameras[index];
                  return CameraCard(
                    camera: camera,
                    onTap: () => _viewCamera(camera),
                    onMenuTap: () => _showCameraMenu(camera),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.primaryBlue,
        foregroundColor: Colors.white,
        onPressed: _showAddCameraDialog,
        icon: const Icon(Icons.add),
        label: const Text(
          'Nueva Cámara',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}