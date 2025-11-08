import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:curso/constants/app_constants.dart';

/// PROTOTIPO - Opción C: Gestión de Miembros Híbrida
///
/// Este es un prototipo visual que muestra TODO en una sola pantalla:
/// - Header con estadísticas
/// - Botón crear invitación
/// - Lista de miembros actuales
/// - Sección colapsable de solicitudes pendientes
///
/// NO ESTÁ CONECTADO A LA API - Solo muestra la UI propuesta

class ManageMembersHybridPrototype extends StatefulWidget {
  const ManageMembersHybridPrototype({super.key});

  @override
  State<ManageMembersHybridPrototype> createState() => _ManageMembersHybridPrototypeState();
}

class _ManageMembersHybridPrototypeState extends State<ManageMembersHybridPrototype> {
  bool _showPendingRequests = true;
  String? _activeInvitationLink;

  // Datos de ejemplo
  final List<Map<String, dynamic>> mockMembers = [
    {
      'id': 1,
      'name': 'Tú (Admin)',
      'email': 'jonitopera777@gmail.com',
      'role': 'ADMIN',
      'joinedAt': '2024-10-01',
    },
    {
      'id': 2,
      'name': 'María González',
      'email': 'maria@example.com',
      'role': 'USER',
      'joinedAt': '2024-11-05',
    },
    {
      'id': 3,
      'name': 'Carlos Pérez',
      'email': 'carlos@example.com',
      'role': 'USER',
      'joinedAt': '2024-11-06',
    },
  ];

  final List<Map<String, dynamic>> mockJoinRequests = [
    {
      'id': 1,
      'userName': 'Juan Rodríguez',
      'userEmail': 'juan@example.com',
      'message': 'Hola, me gustaría unirme al equipo de seguridad',
      'createdAt': '2024-11-07 09:15',
    },
    {
      'id': 2,
      'userName': 'Ana López',
      'userEmail': 'ana@example.com',
      'message': null,
      'createdAt': '2024-11-07 08:30',
    },
  ];

  // ============================================
  // WIDGETS
  // ============================================

  Widget _buildStatsHeader() {
    final activeMembers = mockMembers.length;
    final pendingRequests = mockJoinRequests.length;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
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
              Icon(Icons.business, color: AppConstants.primaryBlue, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Organización: Seguridad Central',
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
                  label: 'Miembros',
                  value: '$activeMembers',
                  color: AppConstants.primaryBlue,
                  icon: Icons.people,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  label: 'Solicitudes',
                  value: '$pendingRequests',
                  color: AppConstants.orange,
                  icon: Icons.notifications_active,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  label: 'Cámaras',
                  value: '5',
                  color: AppConstants.success,
                  icon: Icons.videocam,
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
        const SizedBox(height: 4),
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

  Widget _buildInvitationSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryBlue.withOpacity(0.15),
            AppConstants.primaryBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.primaryBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_add, color: AppConstants.primaryBlue, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Invitar Nuevos Miembros',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Genera un link para compartir y que otros usuarios puedan solicitar unirse',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          // Botón crear invitación o mostrar link activo
          if (_activeInvitationLink == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createInvitation,
                icon: const Icon(Icons.add_link, size: 20),
                label: const Text('Generar Link de Invitación'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: AppConstants.success, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Link Activo',
                      style: TextStyle(
                        color: AppConstants.success,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Expira en 9m 45s',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _activeInvitationLink!,
                          style: const TextStyle(
                            color: AppConstants.primaryBlue,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        color: AppConstants.primaryBlue,
                        onPressed: () => _copyLink(_activeInvitationLink!),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _shareLink,
                        icon: const Icon(Icons.share, size: 16),
                        label: const Text('Compartir'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppConstants.primaryBlue,
                          side: const BorderSide(color: AppConstants.primaryBlue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _revokeLink,
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('Revocar'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppConstants.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsSection() {
    if (mockJoinRequests.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 8),
        // Header colapsable
        InkWell(
          onTap: () {
            setState(() {
              _showPendingRequests = !_showPendingRequests;
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppConstants.orange.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.orange.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_active,
                    color: AppConstants.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Solicitudes Pendientes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${mockJoinRequests.length} usuarios esperando aprobación',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _showPendingRequests ? Icons.expand_less : Icons.expand_more,
                  color: AppConstants.orange,
                  size: 24,
                ),
              ],
            ),
          ),
        ),

        // Lista de solicitudes (colapsable)
        if (_showPendingRequests)
          ...mockJoinRequests.map((request) => _buildJoinRequestCard(request)),
      ],
    );
  }

  Widget _buildJoinRequestCard(Map<String, dynamic> request) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppConstants.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.primaryBlue,
                        AppConstants.primaryBlue.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.person_add,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['userName'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request['userEmail'],
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: AppConstants.orange, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'NUEVO',
                        style: TextStyle(
                          color: AppConstants.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (request['message'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.message, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '"${request['message']}"',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  'Hace 2 horas',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectRequest(request['id']),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Rechazar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.error,
                      side: BorderSide(color: AppConstants.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveRequest(request['id']),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aprobar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppConstants.primaryBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'MIEMBROS ACTUALES',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...mockMembers.map((member) => _buildMemberCard(member)),
      ],
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final isAdmin = member['role'] == 'ADMIN';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAdmin
              ? AppConstants.orange.withOpacity(0.3)
              : AppConstants.primaryBlue.withOpacity(0.2),
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
                  colors: isAdmin
                      ? [AppConstants.orange, AppConstants.orange.withOpacity(0.7)]
                      : [AppConstants.primaryBlue, AppConstants.primaryBlue.withOpacity(0.7)],
                ),
              ),
              child: Icon(
                isAdmin ? Icons.admin_panel_settings : Icons.person,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        member['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.star, color: AppConstants.orange, size: 16),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    member['email'],
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isAdmin
                          ? AppConstants.orange.withOpacity(0.2)
                          : AppConstants.primaryBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAdmin ? 'ADMIN' : 'USER',
                      style: TextStyle(
                        color: isAdmin ? AppConstants.orange : AppConstants.primaryBlue,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isAdmin)
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                onPressed: () => _showMemberOptions(member),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // ACCIONES
  // ============================================

  void _createInvitation() {
    setState(() {
      _activeInvitationLink = 'https://app.vigilancia.com/invite/abc123xyz789';
    });
    _showSnackBar('Link de invitación creado', AppConstants.success);
  }

  void _copyLink(String link) {
    Clipboard.setData(ClipboardData(text: link));
    _showSnackBar('Link copiado al portapapeles', AppConstants.success);
  }

  void _shareLink() {
    _showSnackBar('Compartir link (integración pendiente)', AppConstants.primaryBlue);
  }

  void _revokeLink() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text('Revocar Link', style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Estás seguro? El link dejará de funcionar.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _activeInvitationLink = null;
              });
              _showSnackBar('Link revocado', AppConstants.success);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.error),
            child: const Text('Revocar'),
          ),
        ],
      ),
    );
  }

  void _approveRequest(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text('Aprobar Solicitud', style: TextStyle(color: Colors.white)),
        content: const Text(
          'El usuario será agregado con rol USER.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Usuario aprobado', AppConstants.success);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.success),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
  }

  void _rejectRequest(int id) {
    _showSnackBar('Solicitud rechazada', AppConstants.error);
  }

  void _showMemberOptions(Map<String, dynamic> member) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A3E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.person_remove, color: AppConstants.error),
              title: Text('Eliminar miembro', style: TextStyle(color: AppConstants.error)),
              onTap: () {
                Navigator.pop(context);
                _removeMember(member);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeMember(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text('Eliminar Miembro', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Eliminar a ${member['name']}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('${member['name']} eliminado', AppConstants.success);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2E),
        foregroundColor: Colors.white,
        title: const Text('Gestión de Organización'),
        elevation: 0,
        actions: [
          // Badge de solicitudes pendientes
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  setState(() {
                    _showPendingRequests = true;
                  });
                },
              ),
              if (mockJoinRequests.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppConstants.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${mockJoinRequests.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _showSnackBar('Actualizado', AppConstants.success);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildStatsHeader(),
              _buildInvitationSection(),
              _buildPendingRequestsSection(),
              const SizedBox(height: 16),
              _buildMembersSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
