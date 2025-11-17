// lib/screens/home/user_profile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curso/providers/auth_provider.dart';
import 'package:curso/constants/app_constants.dart';
import 'package:curso/services/camera_service.dart';
import 'package:curso/services/evidence_service.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  int _totalCameras = 0;
  int _activeCameras = 0;
  int _totalIncidents = 0;
  int _recentIncidents = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);

    try {
      final cameras = await CameraService.getCameras();
      final incidents = await EvidenceService.getEvidences();

      final now = DateTime.now();
      final last24Hours = now.subtract(const Duration(hours: 24));

      setState(() {
        _totalCameras = cameras.length;
        _activeCameras = cameras.where((c) => c.status.name == 'active').length;
        _totalIncidents = incidents.length;
        _recentIncidents = incidents.where((i) => i.detectedAt.isAfter(last24Hours)).length;
        _isLoadingStats = false;
      });
    } catch (e) {
      print('Error cargando estadísticas: $e');
      setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _logout() async {
    // Mostrar diálogo de confirmación
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius + 4),
        ),
        title: Row(
          children: [
            Icon(
              Icons.logout,
              color: AppConstants.error,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Cerrar Sesión',
              style: TextStyle(color: AppConstants.white),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: TextStyle(color: AppConstants.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppConstants.textLight),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: AppConstants.white),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await ref.read(authNotifierProvider.notifier).logout();
      
      // Navegar al welcome screen
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppConstants.welcomeRoute,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final authState = ref.watch(authNotifierProvider);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppConstants.darkBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off,
                size: 64,
                color: AppConstants.textLight.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                "No hay usuario cargado",
                style: TextStyle(
                  fontSize: 18,
                  color: AppConstants.textLight.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.darkBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          color: AppConstants.primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : AppConstants.defaultPadding),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con avatar y saludo
              _buildHeader(user, isSmallScreen),
              
              SizedBox(height: isSmallScreen ? 16 : 24),
              
              // Información del usuario
              _buildUserInfoCard(user, isSmallScreen),
              
              SizedBox(height: isSmallScreen ? 16 : 20),
              
              // Estadísticas
              _buildStatsCard(isSmallScreen),

              SizedBox(height: isSmallScreen ? 16 : 20),

              // Mensaje motivacional
              _buildMotivationalCard(isSmallScreen),

              SizedBox(height: isSmallScreen ? 20 : 32),

              // Botón de cerrar sesión
              _buildLogoutButton(authState, isSmallScreen),
              
              // Espacio adicional para evitar overflow
              const SizedBox(height: 16),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(user, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryBlue,
            AppConstants.primaryBlue.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius + 4),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryBlue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: isSmallScreen ? 60 : 80,
            height: isSmallScreen ? 60 : 80,
            decoration: BoxDecoration(
              color: AppConstants.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(isSmallScreen ? 30 : 40),
              border: Border.all(
                color: AppConstants.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              user.isAdmin ? Icons.admin_panel_settings : Icons.person,
              size: isSmallScreen ? 30 : 40,
              color: AppConstants.white,
            ),
          ),
          
          SizedBox(width: isSmallScreen ? 12 : 16),
          
          // Información del usuario
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "¡Hola!",
                  style: TextStyle(
                    color: AppConstants.white.withOpacity(0.9),
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.nombre,
                  style: TextStyle(
                    color: AppConstants.white,
                    fontSize: isSmallScreen ? 20 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.isAdmin ? "Administrador" : "Usuario",
                    style: TextStyle(
                      color: AppConstants.white,
                      fontSize: isSmallScreen ? 11 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(user, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius + 2),
        border: Border.all(
          color: AppConstants.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: AppConstants.primaryBlue,
                size: isSmallScreen ? 20 : 24,
              ),
              const SizedBox(width: 8),
              Text(
                "Información Personal",
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryBlue,
                ),
              ),
            ],
          ),
          
          SizedBox(height: isSmallScreen ? 12 : 16),
          
          _buildInfoRow(
            Icons.badge_outlined, 
            "Nombre completo", 
            user.nombreCompleto,
            isSmallScreen,
          ),
          _buildDivider(),
          _buildInfoRow(
            Icons.email_outlined, 
            "Correo electrónico", 
            user.email,
            isSmallScreen,
          ),
          _buildDivider(),
          _buildInfoRow(
            Icons.verified_user_outlined,
            "Email verificado",
            user.isEmailVerified ? "Verificado" : "Pendiente",
            isSmallScreen,
            valueColor: user.isEmailVerified ? AppConstants.success : AppConstants.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(bool isSmallScreen) {
    if (_isLoadingStats) {
      return Container(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        decoration: BoxDecoration(
          color: AppConstants.cardBackground,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius + 2),
          border: Border.all(
            color: AppConstants.orange.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppConstants.orange),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius + 2),
        border: Border.all(
          color: AppConstants.orange.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: AppConstants.orange,
                size: isSmallScreen ? 20 : 24,
              ),
              const SizedBox(width: 8),
              Text(
                "Estadísticas del Sistema",
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.orange,
                ),
              ),
            ],
          ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Grid de estadísticas
          if (isSmallScreen) ...[
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    Icons.videocam,
                    "$_activeCameras/$_totalCameras",
                    "Cámaras\nActivas",
                    isSmallScreen,
                    color: AppConstants.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    Icons.warning_amber,
                    "$_totalIncidents",
                    "Total\nIncidencias",
                    isSmallScreen,
                    color: AppConstants.error,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    Icons.access_time,
                    "$_recentIncidents",
                    "Últimas\n24 horas",
                    isSmallScreen,
                    color: AppConstants.orange,
                  ),
                ),
              ],
            ),
          ] else ...[
            _buildInfoRow(
              Icons.videocam,
              "Cámaras activas",
              "$_activeCameras de $_totalCameras conectadas",
              isSmallScreen,
              valueColor: AppConstants.success,
            ),
            _buildDivider(),
            _buildInfoRow(
              Icons.warning_amber,
              "Total de incidencias",
              "$_totalIncidents detectadas",
              isSmallScreen,
              valueColor: AppConstants.error,
            ),
            _buildDivider(),
            _buildInfoRow(
              Icons.access_time,
              "Incidencias recientes",
              "$_recentIncidents en las últimas 24 horas",
              isSmallScreen,
              valueColor: AppConstants.orange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, bool isSmallScreen, {Color? color}) {
    final itemColor = color ?? AppConstants.orange;

    return Container(
      height: isSmallScreen ? 110 : 120,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 12,
        vertical: isSmallScreen ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: itemColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: itemColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: itemColor, size: isSmallScreen ? 22 : 28),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen ? 15 : 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 12,
              color: AppConstants.textLight,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationalCard(bool isSmallScreen) {
    final messages = [
      {"emoji": "🛡️", "text": "Tu vigilancia mantiene todo seguro", "color": AppConstants.success},
      {"emoji": "👀", "text": "Siempre alerta, siempre protegiendo", "color": AppConstants.primaryBlue},
      {"emoji": "🎯", "text": "Detección precisa, seguridad garantizada", "color": AppConstants.orange},
      {"emoji": "⚡", "text": "Tecnología que nunca duerme", "color": AppConstants.warning},
      {"emoji": "🚀", "text": "Innovación en seguridad 24/7", "color": AppConstants.success},
      {"emoji": "💪", "text": "Protección que inspira confianza", "color": AppConstants.primaryBlue},
    ];

    final randomMessage = messages[DateTime.now().hour % messages.length];

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (randomMessage["color"] as Color).withOpacity(0.2),
            (randomMessage["color"] as Color).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius + 2),
        border: Border.all(
          color: (randomMessage["color"] as Color).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            randomMessage["emoji"] as String,
            style: TextStyle(fontSize: isSmallScreen ? 32 : 40),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              randomMessage["text"] as String,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: AppConstants.white,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(authState, bool isSmallScreen) {
    return SizedBox(
      width: double.infinity,
      height: isSmallScreen ? 48 : AppConstants.buttonHeight,
      child: ElevatedButton(
        onPressed: authState.isLoading ? null : _logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.error,
          disabledBackgroundColor: AppConstants.error.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius + 2),
          ),
          elevation: 4,
          shadowColor: AppConstants.error.withOpacity(0.3),
        ),
        child: authState.isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppConstants.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout, color: AppConstants.white),
                  const SizedBox(width: 8),
                  Text(
                    "Cerrar Sesión",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      color: AppConstants.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isSmallScreen, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 6 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppConstants.primaryBlue.withOpacity(0.7),
            size: isSmallScreen ? 18 : 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: AppConstants.textLight.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppConstants.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        color: AppConstants.textLight.withOpacity(0.1),
        thickness: 1,
      ),
    );
  }
}