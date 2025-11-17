import 'package:flutter/material.dart';
import 'package:curso/constants/app_constants.dart';
import 'package:curso/models/camera_model.dart';

class CameraStatsCard extends StatelessWidget {
  final CameraStats stats;

  const CameraStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              value: '${stats.activeCameras}/${stats.totalCameras}',
              label: 'Cámaras Activas',
              color: AppConstants.primaryBlue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              value: stats.systemOnline ? 'Online' : 'Offline',
              label: 'Estado Sistema',
              color: stats.systemOnline ? AppConstants.success : AppConstants.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class CameraCard extends StatelessWidget {
  final CameraModel camera;
  final VoidCallback onTap;
  final VoidCallback onMenuTap;

  const CameraCard({
    super.key,
    required this.camera,
    required this.onTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildDetails(),
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.videocam,
            color: _getStatusColor(),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                camera.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                camera.location,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getStatusIcon(),
                color: _getStatusColor(),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                camera.status.displayName,
                style: TextStyle(
                  color: _getStatusColor(),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetails() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.link, color: Colors.grey[400], size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  camera.rtspUrl,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.grey[400], size: 16),
              const SizedBox(width: 8),
              Text(
                'Última conexión: ${_formatTime(camera.lastConnection)}',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Ver Stream'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppConstants.primaryBlue,
              side: BorderSide(color: AppConstants.primaryBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: camera.status == CameraStatus.active ? onTap : null,
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.more_vert),
          color: Colors.grey[400],
          onPressed: onMenuTap,
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (camera.status) {
      case CameraStatus.active:
        return AppConstants.success;
      case CameraStatus.inactive:
        return AppConstants.error;
      case CameraStatus.maintenance:
        return AppConstants.orange;
    }
  }

  IconData _getStatusIcon() {
    switch (camera.status) {
      case CameraStatus.active:
        return Icons.radio_button_checked;
      case CameraStatus.inactive:
        return Icons.radio_button_off;
      case CameraStatus.maintenance:
        return Icons.settings;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    return 'Hace ${diff.inDays}d';
  }
}

class AddCameraDialog extends StatefulWidget {
  final Function(String name, String location, String url) onAdd;

  const AddCameraDialog({super.key, required this.onAdd});

  @override
  State<AddCameraDialog> createState() => _AddCameraDialogState();
}

class _AddCameraDialogState extends State<AddCameraDialog> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _urlController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2A2A3E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildTextField('Nombre de la cámara', 'Ej: Cámara Recepción', _nameController),
              const SizedBox(height: 16),
              _buildTextField('Ubicación', 'Ej: Entrada principal', _locationController),
              const SizedBox(height: 16),
              _buildTextField('URL RTSP', 'rtsp://192.168.X.X:554/stream', _urlController),
              const SizedBox(height: 24),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.primaryBlue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.videocam_outlined, color: AppConstants.primaryBlue, size: 24),
        ),
        const SizedBox(width: 12),
        const Text(
          "Nueva Cámara",
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: const Color(0xFF1E1E2E),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppConstants.primaryBlue)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancelar", style: TextStyle(color: Colors.grey[400])),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryBlue,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            if (_urlController.text.isNotEmpty) {
              widget.onAdd(_nameController.text, _locationController.text, _urlController.text);
              Navigator.pop(context);
            }
          },
          child: const Text("Agregar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}