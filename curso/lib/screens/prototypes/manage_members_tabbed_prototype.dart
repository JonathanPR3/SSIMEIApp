import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:curso/constants/app_constants.dart';

/// PROTOTIPO - Opción A: Gestión de Miembros con Tabs
///
/// Este es un prototipo visual para mostrar cómo quedaría la pantalla
/// con el sistema completo de tabs para:
/// - Miembros actuales
/// - Invitaciones generadas
/// - Solicitudes de unión pendientes
///
/// NO ESTÁ CONECTADO A LA API - Solo muestra la UI propuesta

class ManageMembersTabbedPrototype extends StatefulWidget {
  const ManageMembersTabbedPrototype({super.key});

  @override
  State<ManageMembersTabbedPrototype> createState() => _ManageMembersTabbedPrototypeState();
}

class _ManageMembersTabbedPrototypeState extends State<ManageMembersTabbedPrototype>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  final List<Map<String, dynamic>> mockInvitations = [
    {
      'id': 1,
      'token': 'abc123xyz789',
      'link': 'https://app.vigilancia.com/invite/abc123xyz789',
      'createdAt': '2024-11-07 10:30',
      'expiresAt': '2024-11-07 20:30',
      'status': 'PENDING',
    },
    {
      'id': 2,
      'token': 'def456uvw012',
      'link': 'https://app.vigilancia.com/invite/def456uvw012',
      'createdAt': '2024-11-06 15:20',
      'expiresAt': '2024-11-06 16:20',
      'status': 'EXPIRED',
    },
  ];

  final List<Map<String, dynamic>> mockJoinRequests = [
    {
      'id': 1,
      'userName': 'Juan Rodríguez',
      'userEmail': 'juan@example.com',
      'message': 'Hola, me gustaría unirme al equipo de seguridad',
      'status': 'PENDING',
      'createdAt': '2024-11-07 09:15',
    },
    {
      'id': 2,
      'userName': 'Ana López',
      'userEmail': 'ana@example.com',
      'message': 'Trabajo en el edificio y necesito acceso',
      'status': 'PENDING',
      'createdAt': '2024-11-07 08:30',
    },
    {
      'id': 3,
      'userName': 'Pedro Martínez',
      'userEmail': 'pedro@example.com',
      'message': null,
      'status': 'APPROVED',
      'createdAt': '2024-11-06 18:00',
      'reviewedAt': '2024-11-06 19:00',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ============================================
  // TAB 1: MIEMBROS
  // ============================================

  Widget _buildMembersTab() {
    final activeMembers = mockMembers.length;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header de estadísticas
            Container(
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
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Miembros',
                      '$activeMembers',
                      Icons.people,
                      AppConstants.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Admins',
                      '1',
                      Icons.admin_panel_settings,
                      AppConstants.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Usuarios',
                      '${activeMembers - 1}',
                      Icons.person,
                      AppConstants.success,
                    ),
                  ),
                ],
              ),
            ),

            // Lista de miembros
            ...mockMembers.map((member) => _buildMemberCard(member)),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
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
            // Avatar
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

            // Información
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

            // Botón eliminar (solo para users)
            if (!isAdmin)
              IconButton(
                icon: Icon(Icons.person_remove, color: AppConstants.error),
                onPressed: () => _showRemoveMemberDialog(member),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // TAB 2: INVITACIONES
  // ============================================

  Widget _buildInvitationsTab() {
    final activeInvitations = mockInvitations.where((i) => i['status'] == 'PENDING').length;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.primaryBlue.withOpacity(0.2),
                  AppConstants.primaryBlue.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppConstants.primaryBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.link, color: AppConstants.primaryBlue, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Links de Invitación',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Genera links para compartir con nuevos usuarios',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _createInvitation,
                    icon: const Icon(Icons.add_link),
                    label: const Text('Crear Nueva Invitación'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Estadística
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[400], size: 16),
                const SizedBox(width: 8),
                Text(
                  '$activeInvitations invitaciones activas',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Lista de invitaciones
          if (mockInvitations.isEmpty)
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
                    Icon(Icons.link_off, size: 64, color: Colors.grey[600]),
                    const SizedBox(height: 16),
                    Text(
                      'No hay invitaciones',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...mockInvitations.map((invitation) => _buildInvitationCard(invitation)),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInvitationCard(Map<String, dynamic> invitation) {
    final isExpired = invitation['status'] == 'EXPIRED';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpired
              ? Colors.grey.withOpacity(0.3)
              : AppConstants.success.withOpacity(0.3),
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
                Icon(
                  isExpired ? Icons.link_off : Icons.link,
                  color: isExpired ? Colors.grey : AppConstants.success,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isExpired ? 'Expirada' : 'Activa',
                  style: TextStyle(
                    color: isExpired ? Colors.grey : AppConstants.success,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (!isExpired)
                  TextButton.icon(
                    onPressed: () => _copyInvitationLink(invitation['link']),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copiar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppConstants.primaryBlue,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Link
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      invitation['link'],
                      style: TextStyle(
                        color: isExpired ? Colors.grey[600] : AppConstants.primaryBlue,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Metadata
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  'Creada: ${invitation['createdAt']}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isExpired ? Icons.event_busy : Icons.event_available,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Text(
                  'Expira: ${invitation['expiresAt']}',
                  style: TextStyle(
                    color: isExpired ? AppConstants.error : Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                if (!isExpired)
                  TextButton(
                    onPressed: () => _revokeInvitation(invitation['id']),
                    child: Text(
                      'Revocar',
                      style: TextStyle(
                        color: AppConstants.error,
                        fontSize: 12,
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

  // ============================================
  // TAB 3: SOLICITUDES
  // ============================================

  Widget _buildJoinRequestsTab() {
    final pendingRequests = mockJoinRequests.where((r) => r['status'] == 'PENDING').toList();
    final historicalRequests = mockJoinRequests.where((r) => r['status'] != 'PENDING').toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.orange.withOpacity(0.2),
                  AppConstants.orange.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_active, color: AppConstants.orange, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Solicitudes de Unión',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${pendingRequests.length} solicitudes pendientes',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Pendientes
          if (pendingRequests.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppConstants.orange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'PENDIENTES DE REVISIÓN',
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
            const SizedBox(height: 12),
            ...pendingRequests.map((request) => _buildJoinRequestCard(request, isPending: true)),
          ] else
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A3E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppConstants.success, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'No hay solicitudes pendientes',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // Historial
          if (historicalRequests.isNotEmpty) ...[
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'HISTORIAL',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...historicalRequests.map((request) => _buildJoinRequestCard(request, isPending: false)),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildJoinRequestCard(Map<String, dynamic> request, {required bool isPending}) {
    final status = request['status'];
    final isApproved = status == 'APPROVED';
    final isRejected = status == 'REJECTED';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? AppConstants.orange.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppConstants.primaryBlue.withOpacity(0.2),
                  ),
                  child: const Icon(
                    Icons.person_add,
                    color: AppConstants.primaryBlue,
                    size: 20,
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
                if (!isPending)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isApproved
                          ? AppConstants.success.withOpacity(0.2)
                          : AppConstants.error.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isApproved ? 'APROBADO' : 'RECHAZADO',
                      style: TextStyle(
                        color: isApproved ? AppConstants.success : AppConstants.error,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
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
                        request['message'],
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 13,
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
                  'Solicitó: ${request['createdAt']}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),

            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectJoinRequest(request['id']),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Rechazar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppConstants.error,
                        side: BorderSide(color: AppConstants.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveJoinRequest(request['id']),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Aprobar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================
  // ACCIONES
  // ============================================

  void _createInvitation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text('Crear Invitación', style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Se generará un link universal que cualquier persona puede usar para solicitar unirse a la organización.',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              '⏰ El link expirará en 10 minutos',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Link de invitación creado', AppConstants.success);
            },
            icon: const Icon(Icons.add_link),
            label: const Text('Crear Link'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  void _copyInvitationLink(String link) {
    Clipboard.setData(ClipboardData(text: link));
    _showSnackBar('Link copiado al portapapeles', AppConstants.success);
  }

  void _revokeInvitation(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text('Revocar Invitación', style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Estás seguro? El link dejará de funcionar inmediatamente.',
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
              _showSnackBar('Invitación revocada', AppConstants.success);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.error),
            child: const Text('Revocar'),
          ),
        ],
      ),
    );
  }

  void _approveJoinRequest(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text('Aprobar Solicitud', style: TextStyle(color: Colors.white)),
        content: const Text(
          'El usuario será agregado a la organización con rol USER.',
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
              _showSnackBar('Usuario aprobado y agregado', AppConstants.success);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.success),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
  }

  void _rejectJoinRequest(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text('Rechazar Solicitud', style: TextStyle(color: Colors.white)),
        content: const Text(
          'El usuario recibirá una notificación de rechazo.',
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
              _showSnackBar('Solicitud rechazada', AppConstants.error);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.error),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  void _showRemoveMemberDialog(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text('Eliminar Miembro', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Estás seguro de eliminar a ${member['name']}? Perderá acceso a todas las cámaras.',
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppConstants.primaryBlue,
          labelColor: AppConstants.primaryBlue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(
              icon: Icon(Icons.people),
              text: 'Miembros',
            ),
            Tab(
              icon: Icon(Icons.link),
              text: 'Invitaciones',
            ),
            Tab(
              icon: Icon(Icons.notifications_active),
              text: 'Solicitudes',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMembersTab(),
          _buildInvitationsTab(),
          _buildJoinRequestsTab(),
        ],
      ),
    );
  }
}
