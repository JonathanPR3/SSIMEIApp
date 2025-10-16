// lib/screens/home/user_profile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curso/providers/auth_provider.dart';
import 'package:curso/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  bool _tutorialCompleted = false;
  bool _isLoadingTutorial = true;

  @override
  void initState() {
    super.initState();
    _loadTutorialStatus();
  }

  Future<void> _loadTutorialStatus() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _tutorialCompleted = prefs.getBool('tutorial_completed_${user.id}') ?? false;
        _isLoadingTutorial = false;
      });
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
        child: SingleChildScrollView(
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
              
              // Configuraciones
              _buildSettingsCard(isSmallScreen),
              
              SizedBox(height: isSmallScreen ? 20 : 32),
              
              // Botón de cerrar sesión
              _buildLogoutButton(authState, isSmallScreen),
              
              // Espacio adicional para evitar overflow
              const SizedBox(height: 16),
            ],
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
                "Estadísticas",
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.orange,
                ),
              ),
            ],
          ),
          
          SizedBox(height: isSmallScreen ? 12 : 16),
          
          // Grid de estadísticas en pantallas pequeñas
          if (isSmallScreen) ...[
            Row(
              children: [
                Expanded(child: _buildStatItem(Icons.videocam, "4", "Cámaras", isSmallScreen)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatItem(Icons.warning, "12", "Incidencias", isSmallScreen)),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatItem(Icons.access_time, "Hace 5 min", "Última actividad", isSmallScreen),
          ] else ...[
            _buildInfoRow(Icons.videocam, "Cámaras registradas", "4", isSmallScreen),
            _buildDivider(),
            _buildInfoRow(Icons.warning, "Incidencias detectadas", "12", isSmallScreen),
            _buildDivider(),
            _buildInfoRow(Icons.access_time, "Última actividad", "Hace 5 min", isSmallScreen),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.darkBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppConstants.orange, size: isSmallScreen ? 20 : 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 12,
              color: AppConstants.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: AppConstants.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius + 2),
        border: Border.all(
          color: AppConstants.success.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings_outlined,
                color: AppConstants.success,
                size: isSmallScreen ? 20 : 24,
              ),
              const SizedBox(width: 8),
              Text(
                "Configuración",
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.success,
                ),
              ),
            ],
          ),
          
          SizedBox(height: isSmallScreen ? 12 : 16),
          
          _buildInfoRow(
            Icons.school_outlined,
            "Tutorial completado",
            _isLoadingTutorial ? "Cargando..." : (_tutorialCompleted ? "Completado" : "Pendiente"),
            isSmallScreen,
            valueColor: _tutorialCompleted ? AppConstants.success : AppConstants.warning,
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