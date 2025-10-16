import 'package:flutter/material.dart';
import 'package:curso/constants/app_constants.dart';

// Enums para estados y roles
enum MemberStatus { active, pending, blocked }
enum MemberRole { owner, viewer }

// Modelo de Miembro
class GroupMember {
  final String id;
  final String name;
  final String email;
  final MemberRole role;
  final MemberStatus status;
  final DateTime addedAt;
  final DateTime? lastActive;
  final String? avatarUrl;

  GroupMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.addedAt,
    this.lastActive,
    this.avatarUrl,
  });
}

// Extensión para nombres de estados
extension MemberStatusExtension on MemberStatus {
  String get displayName {
    switch (this) {
      case MemberStatus.active:
        return 'Activo';
      case MemberStatus.pending:
        return 'Pendiente';
      case MemberStatus.blocked:
        return 'Bloqueado';
    }
  }
}

// Extensión para nombres de roles
extension MemberRoleExtension on MemberRole {
  String get displayName {
    switch (this) {
      case MemberRole.owner:
        return 'Propietario';
      case MemberRole.viewer:
        return 'Espectador';
    }
  }

  String get description {
    switch (this) {
      case MemberRole.owner:
        return 'Control total del grupo';
      case MemberRole.viewer:
        return 'Solo ver transmisiones';
    }
  }
}

class ManageMembersScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ManageMembersScreen({
    super.key,
    this.onBack,
  });

  @override
  State<ManageMembersScreen> createState() => _ManageMembersScreenState();
}

class _ManageMembersScreenState extends State<ManageMembersScreen> {
  List<GroupMember> members = [];
  bool isLoading = true;
  final int maxMembers = 10;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => isLoading = true);
    
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      members = [
        GroupMember(
          id: '1',
          name: 'Tú',
          email: 'tu@email.com',
          role: MemberRole.owner,
          status: MemberStatus.active,
          addedAt: DateTime.now().subtract(const Duration(days: 30)),
          lastActive: DateTime.now(),
        ),
        GroupMember(
          id: '2',
          name: 'María González',
          email: 'maria@email.com',
          role: MemberRole.viewer,
          status: MemberStatus.active,
          addedAt: DateTime.now().subtract(const Duration(days: 15)),
          lastActive: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        GroupMember(
          id: '3',
          name: 'Carlos Pérez',
          email: 'carlos@email.com',
          role: MemberRole.viewer,
          status: MemberStatus.pending,
          addedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
      isLoading = false;
    });
  }

  Future<void> _inviteMember() async {
    final TextEditingController emailController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text(
          'Invitar Espectador',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'correo@ejemplo.com',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.email, color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF1E1E2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.primaryBlue.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppConstants.primaryBlue.withAlpha(100),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.visibility,
                    color: AppConstants.primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rol: Espectador',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Podrá ver todas las transmisiones de tus cámaras',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryBlue,
            ),
            onPressed: () {
              if (emailController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Enviar Invitación'),
          ),
        ],
      ),
    );

    if (result == true) {
      _showSuccessSnackBar('Invitación enviada a ${emailController.text}');
      _loadMembers();
    }
  }

  Future<void> _removeMember(GroupMember member) async {
    if (member.role == MemberRole.owner) {
      _showErrorSnackBar('No puedes eliminar al propietario');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text(
          'Eliminar Miembro',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar a ${member.name}? Perderá acceso a todas las cámaras.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _showSuccessSnackBar('${member.name} ha sido eliminado del grupo');
      _loadMembers();
    }
  }

  Future<void> _resendInvitation(GroupMember member) async {
    _showSuccessSnackBar('Invitación reenviada a ${member.email}');
  }

  Color _getStatusColor(MemberStatus status) {
    switch (status) {
      case MemberStatus.active:
        return AppConstants.success;
      case MemberStatus.pending:
        return AppConstants.orange;
      case MemberStatus.blocked:
        return AppConstants.error;
    }
  }

  IconData _getStatusIcon(MemberStatus status) {
    switch (status) {
      case MemberStatus.active:
        return Icons.check_circle;
      case MemberStatus.pending:
        return Icons.schedule;
      case MemberStatus.blocked:
        return Icons.block;
    }
  }

  IconData _getRoleIcon(MemberRole role) {
    switch (role) {
      case MemberRole.owner:
        return Icons.star;
      case MemberRole.viewer:
        return Icons.visibility;
    }
  }

  String _formatLastActive(DateTime? lastActive) {
    if (lastActive == null) return 'Nunca activo';
    
    final diff = DateTime.now().difference(lastActive);
    if (diff.inMinutes < 1) return 'Activo ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    return 'Hace más de una semana';
  }

  Widget _buildStatsHeader() {
    final activeMembers = members.where((m) => m.status == MemberStatus.active).length;
    final pendingMembers = members.where((m) => m.status == MemberStatus.pending).length;

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
              Icon(Icons.groups, color: AppConstants.primaryBlue, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Miembros del Grupo',
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
                  label: 'Total',
                  value: '${members.length}/$maxMembers',
                  color: AppConstants.primaryBlue,
                  icon: Icons.people,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  label: 'Activos',
                  value: '$activeMembers',
                  color: AppConstants.success,
                  icon: Icons.check_circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  label: 'Pendientes',
                  value: '$pendingMembers',
                  color: AppConstants.orange,
                  icon: Icons.schedule,
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

  Widget _buildMemberCard(GroupMember member) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(member.status).withAlpha(100),
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
              child: Icon(
                _getRoleIcon(member.role),
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
                      Flexible(
                        child: Text(
                          member.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (member.role == MemberRole.owner) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.star, color: AppConstants.orange, size: 16),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member.email,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getStatusColor(member.status).withAlpha(50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(member.status),
                              color: _getStatusColor(member.status),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              member.status.displayName,
                              style: TextStyle(
                                color: _getStatusColor(member.status),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        member.role.displayName,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      if (member.status == MemberStatus.active)
                        Text(
                          _formatLastActive(member.lastActive),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
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
              enabled: member.role != MemberRole.owner,
              itemBuilder: (context) => [
                if (member.status == MemberStatus.pending)
                  PopupMenuItem(
                    value: 'resend',
                    child: Row(
                      children: [
                        Icon(Icons.send, color: Colors.white70, size: 18),
                        const SizedBox(width: 12),
                        const Text(
                          'Reenviar invitación',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove, color: AppConstants.error, size: 18),
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
                  case 'resend':
                    _resendInvitation(member);
                    break;
                  case 'remove':
                    _removeMember(member);
                    break;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteButton() {
    final canInvite = members.length < maxMembers;
    
    return Container(
      margin: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: canInvite ? _inviteMember : null,
          icon: const Icon(Icons.person_add),
          label: Text(
            canInvite 
                ? 'Invitar Espectador' 
                : 'Límite de $maxMembers miembros alcanzado',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: canInvite ? AppConstants.primaryBlue : Colors.grey,
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
          title: const Text('Gestionar Miembros'),
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
        title: const Text('Gestionar Miembros'),
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
            onPressed: _loadMembers,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMembers,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildStatsHeader(),
              _buildInviteButton(),
              
              if (members.isEmpty) ...[
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
                          Icons.group_off,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay miembros en el grupo',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Invita personas para compartir el acceso a tus cámaras',
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
                ...members.map((member) => _buildMemberCard(member)),
              ],
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}