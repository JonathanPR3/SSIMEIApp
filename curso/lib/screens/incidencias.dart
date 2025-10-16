import 'package:flutter/material.dart';
import 'package:curso/constants/app_constants.dart';
import 'package:curso/models/evidence_model.dart';
import 'package:curso/services/evidence_service.dart';
import 'package:curso/screens/evidencia_detail.dart';

class Incidencias extends StatefulWidget {
  const Incidencias({super.key});

  @override
  State<Incidencias> createState() => _IncidenciasState();
}

class _IncidenciasState extends State<Incidencias> {
  List<EvidenceModel> evidences = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvidences();
  }

  Future<void> _loadEvidences() async {
    setState(() => isLoading = true);
    try {
      final result = await EvidenceService.getEvidences();
      setState(() {
        evidences = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Error al cargar las evidencias');
    }
  }

  void _viewEvidenceDetail(EvidenceModel evidence) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EvidenciaDetail(evidence: evidence),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    return 'Hace ${diff.inDays}d';
  }

  Color _getStatusColor(EvidenceStatus status) {
    switch (status) {
      case EvidenceStatus.pending:
        return AppConstants.orange;
      case EvidenceStatus.reviewed:
        return AppConstants.primaryBlue;
      case EvidenceStatus.resolved:
        return AppConstants.success;
    }
  }

  Color _getTypeColor(EvidenceType type) {
    switch (type) {
      case EvidenceType.suspiciousPose:
        return AppConstants.orange;
      case EvidenceType.unauthorizedPerson:
        return Colors.red;
    }
  }

  IconData _getTypeIcon(EvidenceType type) {
    switch (type) {
      case EvidenceType.suspiciousPose:
        return Icons.person_search;
      case EvidenceType.unauthorizedPerson:
        return Icons.person_off;
    }
  }

  Widget _buildTimelineItem(EvidenceModel evidence, bool isLast) {
    return InkWell(
      onTap: () => _viewEvidenceDetail(evidence),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            // Timeline indicator
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getTypeColor(evidence.type),
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 60,
                    color: Colors.grey[600],
                    margin: const EdgeInsets.only(top: 4),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getTypeColor(evidence.type).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getTypeColor(evidence.type).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getTypeIcon(evidence.type),
                            color: _getTypeColor(evidence.type),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            evidence.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(evidence.status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            evidence.status.displayName,
                            style: TextStyle(
                              color: _getStatusColor(evidence.status),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Description
                    Text(
                      evidence.description,
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    // Footer
                    Row(
                      children: [
                        Icon(Icons.videocam, color: Colors.grey[500], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          evidence.cameraName,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.access_time, color: Colors.grey[500], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(evidence.detectedAt),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey[500],
                          size: 12,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final int totalEvidencias = evidences.length;
    final int recentEvidencias = evidences.where((e) => 
      DateTime.now().difference(e.detectedAt).inHours < 24
    ).length;
    final int poseSospechosa = evidences.where((e) => 
      e.type == EvidenceType.suspiciousPose
    ).length;
    final int personasNoAutorizadas = evidences.where((e) => 
      e.type == EvidenceType.unauthorizedPerson
    ).length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A3E),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Evidencias de Seguridad',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatChip(
                label: '$totalEvidencias Total',
                color: AppConstants.primaryBlue,
                icon: Icons.list_alt,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                label: '$recentEvidencias Últimas 24h',
                color: AppConstants.orange,
                icon: Icons.access_time,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatChip(
                label: '$poseSospechosa Poses',
                color: AppConstants.orange,
                icon: Icons.person_search,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                label: '$personasNoAutorizadas Rostros',
                color: Colors.red,
                icon: Icons.person_off,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
      return const Scaffold(
        backgroundColor: Color(0xFF1E1E2E),
        body: Center(
          child: CircularProgressIndicator(color: AppConstants.primaryBlue),
        ),
      );
    }

    if (evidences.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E1E2E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security,
                size: 64,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                'No hay evidencias registradas',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Las evidencias aparecerán cuando se detecten comportamientos sospechosos',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      body: RefreshIndicator(
        onRefresh: _loadEvidences,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: evidences.length,
                itemBuilder: (context, index) {
                  final evidence = evidences[index];
                  final isLast = index == evidences.length - 1;
                  return _buildTimelineItem(evidence, isLast);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}