// lib/screens/organization/manage_organization_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:curso/constants/app_constants.dart';
import 'package:curso/models/organization_model.dart';
import 'package:curso/models/invitation_model.dart';
import 'package:curso/models/join_request_model.dart';
import 'package:curso/services/organization_service.dart';
import 'package:curso/services/invitation_service.dart';
import 'package:curso/services/join_request_service.dart';
import 'package:curso/services/camera_permission_service.dart';
import 'package:curso/screens/organization/manage_user_cameras_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pantalla principal de gestión de organización con Tabs
///
/// Incluye:
/// - Tab 1: Miembros de la organización
/// - Tab 2: Invitaciones generadas
/// - Tab 3: Solicitudes de unión pendientes
class ManageOrganizationScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ManageOrganizationScreen({
    super.key,
    this.onBack,
  });

  @override
  State<ManageOrganizationScreen> createState() => _ManageOrganizationScreenState();
}

class _ManageOrganizationScreenState extends State<ManageOrganizationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Estado
  bool _isLoading = true;
  Organization? _organization;
  List<Invitation> _invitations = [];
  List<JoinRequest> _joinRequests = [];
  String? _currentUserRole;
  int? _currentUserId;
  Map<int, int> _userCameraCounts = {}; // userId -> camera count

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadCurrentUser();
    await _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString(AppConstants.userDataKey);

      if (userDataStr != null) {
        final userMap = json.decode(userDataStr) as Map<String, dynamic>;

        // Intentar obtener role directamente del backend (ADMIN/USER)
        // Si no está, usar userType del modelo Flutter (administrator/common)
        String? role = userMap['role'] as String?;
        final userId = userMap['id'];

        // Si no hay role del backend, convertir desde userType
        if (role == null || role.isEmpty) {
          final userType = userMap['userType'] as String?;
          if (userType == 'administrator') {
            role = 'ADMIN';
          } else if (userType == 'common') {
            role = 'USER';
          }
        }

        setState(() {
          _currentUserRole = role;
          // Convertir el ID a int si es string
          if (userId is String) {
            _currentUserId = int.tryParse(userId);
          } else if (userId is int) {
            _currentUserId = userId;
          }
        });

        print('👤 Usuario cargado - Rol: $_currentUserRole, ID: $_currentUserId');
      } else {
        print('⚠️ No se encontraron datos de usuario en SharedPreferences');
      }
    } catch (e) {
      print('❌ Error cargando usuario: $e');
    }
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      // Cargar organización (incluye miembros)
      final organization = await OrganizationService.getMyOrganization();

      // Solo Admin puede ver invitaciones y solicitudes
      List<Invitation> invitations = [];
      List<JoinRequest> joinRequests = [];

      if (_currentUserRole == 'ADMIN') {
        invitations = await InvitationService.listInvitations();
        joinRequests = await JoinRequestService.getAllRequests();
      }

      setState(() {
        _organization = organization;
        _invitations = invitations;
        _joinRequests = joinRequests;
        _isLoading = false;
      });

      // Cargar conteo de cámaras para cada usuario (solo para ADMIN)
      if (_currentUserRole == 'ADMIN') {
        _loadUserCameraCounts();
      }
    } catch (e) {
      print('Error cargando datos: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error al cargar datos: $e');
    }
  }

  Future<void> _loadUserCameraCounts() async {
    if (_organization == null) return;

    try {
      final members = _organization!.members ?? [];
      final Map<int, int> counts = {};

      // Cargar conteo para cada miembro USER (no ADMIN)
      for (final member in members) {
        if (!member.isAdmin) {
          try {
            final cameras = await CameraPermissionService.getUserCameras(member.userId);
            counts[member.userId] = cameras.length;
          } catch (e) {
            print('⚠️ Error obteniendo cámaras de usuario ${member.userId}: $e');
            counts[member.userId] = 0;
          }
        }
      }

      setState(() {
        _userCameraCounts = counts;
      });

      print('✅ Conteos de cámaras cargados: $counts');
    } catch (e) {
      print('❌ Error cargando conteos de cámaras: $e');
    }
  }

  // ============================================
  // TAB 1: MIEMBROS
  // ============================================

  Widget _buildMembersTab() {
    if (_organization == null) {
      return _buildErrorState('No se pudo cargar la organización');
    }

    final members = _organization!.members ?? [];
    final adminCount = members.where((m) => m.isAdmin).length;
    final userCount = members.length - adminCount;

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header de estadísticas
            _buildStatsHeader(members.length, adminCount, userCount),

            // Lista de miembros
            if (members.isEmpty)
              _buildEmptyState(
                icon: Icons.group_off,
                title: 'No hay miembros',
                subtitle: 'Invita personas para compartir el acceso',
              )
            else
              ...members.map((member) => _buildMemberCard(member)),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(int total, int admins, int users) {
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
              Expanded(
                child: Text(
                  _organization?.name ?? 'Mi Organización',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  '$total',
                  Icons.people,
                  AppConstants.primaryBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Admins',
                  '$admins',
                  Icons.admin_panel_settings,
                  AppConstants.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Usuarios',
                  '$users',
                  Icons.person,
                  AppConstants.success,
                ),
              ),
            ],
          ),
        ],
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

  Widget _buildMemberCard(OrganizationMember member) {
    final isCurrentUser = member.userId == _currentUserId;
    final canRemove = _currentUserRole == 'ADMIN' && !member.isAdmin && !isCurrentUser;
    final canManageCameras = _currentUserRole == 'ADMIN' && !member.isAdmin;
    final cameraCount = _userCameraCounts[member.userId] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: member.isAdmin
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
                  colors: member.isAdmin
                      ? [AppConstants.orange, AppConstants.orange.withOpacity(0.7)]
                      : [AppConstants.primaryBlue, AppConstants.primaryBlue.withOpacity(0.7)],
                ),
              ),
              child: Icon(
                member.isAdmin ? Icons.admin_panel_settings : Icons.person,
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
                      Flexible(
                        child: Text(
                          isCurrentUser ? 'Tú (${member.fullName})' : member.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (member.isAdmin) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.star, color: AppConstants.orange, size: 16),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
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
                          color: member.isAdmin
                              ? AppConstants.orange.withOpacity(0.2)
                              : AppConstants.primaryBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          member.role,
                          style: TextStyle(
                            color: member.isAdmin ? AppConstants.orange : AppConstants.primaryBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // Badge de cámaras (solo para USER)
                      if (!member.isAdmin) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: cameraCount > 0
                                ? AppConstants.success.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.videocam,
                                size: 12,
                                color: cameraCount > 0
                                    ? AppConstants.success
                                    : Colors.grey[400],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$cameraCount',
                                style: TextStyle(
                                  color: cameraCount > 0
                                      ? AppConstants.success
                                      : Colors.grey[400],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Botones de acción (columna)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón gestionar cámaras (solo para USER, solo visible para ADMIN)
                if (canManageCameras)
                  IconButton(
                    icon: Icon(Icons.videocam, color: AppConstants.primaryBlue),
                    tooltip: 'Gestionar Cámaras',
                    onPressed: () => _navigateToManageCameras(member),
                  ),
                // Botón eliminar (solo para Admin, no puede eliminar a otros Admin ni a sí mismo)
                if (canRemove)
                  IconButton(
                    icon: Icon(Icons.person_remove, color: AppConstants.error),
                    tooltip: 'Eliminar Miembro',
                    onPressed: () => _showRemoveMemberDialog(member),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToManageCameras(OrganizationMember member) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageUserCamerasScreen(
          userId: member.userId,
          userName: member.fullName,
          userEmail: member.email,
        ),
      ),
    );

    // Si hubo cambios, recargar el conteo de cámaras
    if (result == true) {
      _loadUserCameraCounts();
    }
  }

  // ============================================
  // TAB 2: INVITACIONES
  // ============================================

  Widget _buildInvitationsTab() {
    if (_currentUserRole != 'ADMIN') {
      return _buildPermissionDenied();
    }

    final activeInvitations = _invitations.where((i) => i.isActive).length;

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
            if (_invitations.isEmpty)
              _buildEmptyState(
                icon: Icons.link_off,
                title: 'No hay invitaciones',
                subtitle: 'Crea una invitación para compartir',
              )
            else
              ..._invitations.map((invitation) => _buildInvitationCard(invitation)),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationCard(Invitation invitation) {
    final isExpired = invitation.isExpired;
    final isActive = invitation.isActive;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpired
              ? Colors.grey.withOpacity(0.3)
              : isActive
                  ? AppConstants.success.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
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
                  isActive ? Icons.link : Icons.link_off,
                  color: isActive ? AppConstants.success : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  invitation.statusDisplay,
                  style: TextStyle(
                    color: isActive ? AppConstants.success : Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Solo mostrar botón de copiar si el token está disponible
                if (isActive && invitation.token != null && invitation.token!.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _copyInvitationToken(invitation.token!),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copiar Token'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppConstants.primaryBlue,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Info de la invitación
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.badge,
                    size: 16,
                    color: isActive ? AppConstants.primaryBlue : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Invitación #${invitation.id} • Rol: USER',
                      style: TextStyle(
                        color: isActive ? Colors.white70 : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Metadata
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  isActive
                      ? 'Expira en ${invitation.timeUntilExpirationDisplay}'
                      : 'Expirada',
                  style: TextStyle(
                    color: isExpired ? AppConstants.error : Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                if (isActive)
                  TextButton(
                    onPressed: () => _revokeInvitation(invitation.id),
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
    if (_currentUserRole != 'ADMIN') {
      return _buildPermissionDenied();
    }

    final pendingRequests = _joinRequests.where((r) => r.isPending).toList();
    final historicalRequests = _joinRequests.where((r) => !r.isPending).toList();

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
      ),
    );
  }

  Widget _buildJoinRequestCard(JoinRequest request, {required bool isPending}) {
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
                        request.userFullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        request.userEmail,
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
                      color: request.isApproved
                          ? AppConstants.success.withOpacity(0.2)
                          : AppConstants.error.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      request.statusDisplay.toUpperCase(),
                      style: TextStyle(
                        color: request.isApproved ? AppConstants.success : AppConstants.error,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),

            if (request.message != null && request.message!.isNotEmpty) ...[
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
                        '"${request.message}"',
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
                  request.timeAgo,
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
                      onPressed: () => _rejectJoinRequest(request),
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
                      onPressed: () => _approveJoinRequest(request),
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
  // WIDGETS AUXILIARES
  // ============================================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
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

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppConstants.error),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAllData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'Solo los Administradores pueden ver esta sección',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // ACCIONES
  // ============================================

  Future<void> _createInvitation() async {
    try {
      _showLoadingDialog('Creando invitación...');

      final invitation = await InvitationService.createInvitation(expiresInMinutes: 10);

      Navigator.pop(context); // Cerrar loading

      // Copiar token automáticamente al portapapeles
      final token = invitation.token ?? '';
      if (token.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: token));
      }

      // Mostrar diálogo con el token
      await _showInvitationTokenDialog(invitation);

      // Recargar invitaciones
      await _loadAllData();
    } catch (e) {
      Navigator.pop(context); // Cerrar loading
      _showErrorSnackBar('Error al crear invitación: $e');
    }
  }

  Future<void> _showInvitationTokenDialog(Invitation invitation) async {
    final token = invitation.token ?? 'Token no disponible';

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppConstants.primaryBlue, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Invitación Creada',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 280,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // QR Code
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SizedBox(
                    width: 180,
                    height: 180,
                    child: QrImageView(
                      data: token,
                      version: QrVersions.auto,
                      size: 180,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Escanea el código QR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'o comparte el token:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              // Token texto (colapsable)
              Container(
                padding: const EdgeInsets.all(10),
                constraints: const BoxConstraints(maxHeight: 80),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppConstants.primaryBlue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    token,
                    style: TextStyle(
                      color: AppConstants.primaryBlue,
                      fontSize: 9,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Advertencia de expiración
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppConstants.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppConstants.orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer, color: AppConstants.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Expira en ${invitation.timeUntilExpirationDisplay}',
                        style: TextStyle(
                          color: AppConstants.orange,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: token));
              _showSuccessSnackBar('Token copiado');
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copiar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryBlue,
            ),
            child: const Text('Listo'),
          ),
        ],
      ),
    );
  }

  void _copyInvitationToken(String token) {
    Clipboard.setData(ClipboardData(text: token));
    _showSuccessSnackBar('Token copiado al portapapeles');
  }

  Future<void> _revokeInvitation(int invitationId) async {
    final confirmed = await showDialog<bool>(
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.error),
            child: const Text('Revocar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        _showLoadingDialog('Revocando invitación...');

        await InvitationService.revokeInvitation(invitationId);

        Navigator.pop(context); // Cerrar loading

        _showSuccessSnackBar('Invitación revocada');

        // Recargar
        await _loadAllData();
      } catch (e) {
        Navigator.pop(context); // Cerrar loading
        _showErrorSnackBar('Error al revocar invitación: $e');
      }
    }
  }

  Future<void> _approveJoinRequest(JoinRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text('Aprobar Solicitud', style: TextStyle(color: Colors.white)),
        content: Text(
          '${request.userFullName} será agregado a la organización con rol USER.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.success),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        _showLoadingDialog('Aprobando solicitud...');

        await JoinRequestService.approveRequest(request.id);

        Navigator.pop(context); // Cerrar loading

        _showSuccessSnackBar('${request.userFullName} agregado a la organización');

        // Recargar todo (ahora incluye el nuevo miembro)
        await _loadAllData();

        // Cambiar a tab de miembros para ver el nuevo miembro
        _tabController.animateTo(0);
      } catch (e) {
        Navigator.pop(context); // Cerrar loading
        _showErrorSnackBar('Error al aprobar solicitud: $e');
      }
    }
  }

  Future<void> _rejectJoinRequest(JoinRequest request) async {
    try {
      _showLoadingDialog('Rechazando solicitud...');

      await JoinRequestService.rejectRequest(request.id);

      Navigator.pop(context); // Cerrar loading

      _showSuccessSnackBar('Solicitud rechazada');

      // Recargar
      await _loadAllData();
    } catch (e) {
      Navigator.pop(context); // Cerrar loading
      _showErrorSnackBar('Error al rechazar solicitud: $e');
    }
  }

  Future<void> _showRemoveMemberDialog(OrganizationMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text('Eliminar Miembro', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Estás seguro de eliminar a ${member.fullName}? Perderá acceso a todas las cámaras.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        _showLoadingDialog('Eliminando miembro...');

        await OrganizationService.removeUser(member.userId);

        Navigator.pop(context); // Cerrar loading

        _showSuccessSnackBar('${member.fullName} ha sido eliminado');

        // Recargar
        await _loadAllData();
      } catch (e) {
        Navigator.pop(context); // Cerrar loading
        _showErrorSnackBar('Error al eliminar miembro: $e');
      }
    }
  }

  // ============================================
  // UTILIDADES
  // ============================================

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        content: Row(
          children: [
            const CircularProgressIndicator(color: AppConstants.primaryBlue),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
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
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E1E2E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E2E),
          foregroundColor: Colors.white,
          title: const Text('Gestión de Organización'),
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

    final pendingRequestsCount = _joinRequests.where((r) => r.isPending).length;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2E),
        foregroundColor: Colors.white,
        title: const Text('Gestión de Organización'),
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        actions: [
          if (_currentUserRole == 'ADMIN' && pendingRequestsCount > 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () => _tabController.animateTo(2),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppConstants.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '$pendingRequestsCount',
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
            onPressed: _loadAllData,
          ),
        ],
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
