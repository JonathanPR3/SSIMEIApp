import 'package:flutter/material.dart';
import 'package:curso/constants/app_constants.dart';
import 'package:curso/models/evidence_model.dart';

class EvidenceStatsCard extends StatelessWidget {
  final EvidenceStats stats;

  const EvidenceStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard(
                value: '${stats.pendingEvidences}',
                label: 'Pendientes',
                color: AppConstants.orange,
                icon: Icons.pending_actions,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(
                value: '${stats.reviewedEvidences}',
                label: 'Revisadas',
                color: AppConstants.primaryBlue,
                icon: Icons.check_circle,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard(
                value: '${stats.totalEvidences}',
                label: 'Total',
                color: AppConstants.success,
                icon: Icons.analytics,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(
                value: '${stats.recentEvidences.length}',
                label: 'Recientes',
                color: Colors.purple,
                icon: Icons.access_time,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class EvidenceCard extends StatelessWidget {
  final EvidenceModel evidence;
  final VoidCallback onTap;
  final VoidCallback onMenuTap;

  const EvidenceCard({
    super.key,
    required this.evidence,
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
          color: _getTypeColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildContent(),
              const SizedBox(height: 16),
              _buildFooter(),
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getTypeColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getTypeIcon(),
            color: _getTypeColor(),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                evidence.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                evidence.cameraName,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getTypeColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                evidence.type.displayName,
                style: TextStyle(
                  color: _getTypeColor(),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                evidence.status.displayName,
                style: TextStyle(
                  color: _getStatusColor(),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white54),
          onPressed: onMenuTap,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Text(
      evidence.description,
      style: TextStyle(
        color: Colors.grey[300],
        fontSize: 14,
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Icon(Icons.access_time, color: Colors.grey[500], size: 16),
        const SizedBox(width: 6),
        Text(
          _formatTime(evidence.detectedAt),
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 13,
          ),
        ),
        const Spacer(),
        if (evidence.videoFragments.isNotEmpty) ...[
          Icon(Icons.videocam, color: Colors.grey[500], size: 16),
          const SizedBox(width: 4),
          Text(
            '${evidence.videoFragments.length} video${evidence.videoFragments.length != 1 ? 's' : ''}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }

  Color _getTypeColor() {
    switch (evidence.type) {
      case EvidenceType.suspiciousPose:
        return AppConstants.orange;
      case EvidenceType.unauthorizedPerson:
        return Colors.red;
      case EvidenceType.forzadoCerradura:
        return Colors.red[700]!;
      case EvidenceType.agresionPuerta:
        return Colors.red[900]!;
      case EvidenceType.escaladoVentana:
        return Colors.orange[700]!;
      case EvidenceType.arrojamientoObjetos:
        return Colors.deepOrange;
      case EvidenceType.vistaProlongada:
        return Colors.amber[700]!;
    }
  }

  IconData _getTypeIcon() {
    switch (evidence.type) {
      case EvidenceType.suspiciousPose:
        return Icons.person_search;
      case EvidenceType.unauthorizedPerson:
        return Icons.person_off;
      case EvidenceType.forzadoCerradura:
        return Icons.lock_open;
      case EvidenceType.agresionPuerta:
        return Icons.door_front_door;
      case EvidenceType.escaladoVentana:
        return Icons.window;
      case EvidenceType.arrojamientoObjetos:
        return Icons.warning;
      case EvidenceType.vistaProlongada:
        return Icons.visibility;
    }
  }

  Color _getStatusColor() {
    switch (evidence.status) {
      case EvidenceStatus.pending:
        return AppConstants.orange;
      case EvidenceStatus.reviewed:
        return AppConstants.primaryBlue;
      case EvidenceStatus.resolved:
        return AppConstants.success;
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

class EvidenceFilterChips extends StatelessWidget {
  final EvidenceStatus? selectedStatus;
  final Function(EvidenceStatus?) onStatusChanged;

  const EvidenceFilterChips({
    super.key,
    this.selectedStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filtrar por estado:',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                label: 'Todos',
                isSelected: selectedStatus == null,
                onTap: () => onStatusChanged(null),
              ),
              const SizedBox(width: 8),
              ...EvidenceStatus.values.map((status) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(
                  label: status.displayName,
                  isSelected: selectedStatus == status,
                  onTap: () => onStatusChanged(status),
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppConstants.primaryBlue 
              : const Color(0xFF2A2A3E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? AppConstants.primaryBlue 
                : Colors.grey[600]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[300],
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}