import 'package:flutter/material.dart';
import 'package:curso/screens/manage_faces_screen.dart';
import 'package:curso/screens/organization/manage_organization_screen.dart';
import 'package:curso/screens/organization/join_organization_screen.dart';
import 'package:curso/screens/test_face_recognition_screen.dart';
import 'package:curso/constants/app_constants.dart';



class SettingsScreen extends StatefulWidget {
  final Function(int)? onTabChange;

  const SettingsScreen({
    super.key,
    this.onTabChange,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool alertasActivadas = true;
  bool _showingFaceManagement = false;
  bool _showingMemberManagement = false;

  void _showFaceManagement() {
    setState(() {
      _showingFaceManagement = true;
    });
  }

  void _hideFaceManagement() {
    setState(() {
      _showingFaceManagement = false;
    });
  }

  void _showMemberManagement() {
    setState(() {
      _showingMemberManagement = true;
    });
  }

  void _hideMemberManagement() {
    setState(() {
      _showingMemberManagement = false;
    });
  }

  void _openJoinOrganization() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const JoinOrganizationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si está mostrando gestión de rostros, mostrar esa pantalla
    if (_showingFaceManagement) {
      return ManageFacesScreen(
        onBack: _hideFaceManagement,
      );
    }

    // Si está mostrando gestión de miembros, mostrar esa pantalla
    if (_showingMemberManagement) {
      return ManageOrganizationScreen(
        onBack: _hideMemberManagement,
      );
    }

    // Mostrar la pantalla de settings normal
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Sección Alertas (PRIORIDAD 1)
            _buildSectionTitle('Alertas'),
            const SizedBox(height: 12),
            _buildAlertasCard(),

            const SizedBox(height: 24),

            // 2. Sección Miembros (PRIORIDAD 2)
            _buildSectionTitle('Miembros'),
            const SizedBox(height: 12),
            _buildSettingsCard(
              icon: Icons.people_outline,
              title: 'Gestionar Miembros',
              subtitle: 'Administra tu organización',
              onTap: _showMemberManagement,
            ),

            const SizedBox(height: 12),

            // Unirse a organización con QR o token
            _buildSettingsCard(
              icon: Icons.qr_code_scanner,
              title: 'Unirse a Organización',
              subtitle: 'Escanea QR o ingresa token',
              onTap: _openJoinOrganization,
            ),

            const SizedBox(height: 24),

            // 3. Sección Rostros (PRIORIDAD 3)
            _buildSectionTitle('Reconocimiento Facial'),
            const SizedBox(height: 12),
            _buildSettingsCard(
              icon: Icons.face_outlined,
              title: 'Gestionar Rostros',
              subtitle: 'Administra rostros registrados',
              onTap: _showFaceManagement,
            ),

            const SizedBox(height: 12),

            // Probar Reconocimiento Facial (Test/Demo)
            _buildSettingsCard(
              icon: Icons.face_retouching_natural,
              title: 'Probar Reconocimiento Facial',
              subtitle: 'Modo de prueba',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TestFaceRecognitionScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // 4. Sección Cámaras (PRIORIDAD 4)
            _buildSectionTitle('Cámaras'),
            const SizedBox(height: 12),
            _buildSettingsCard(
              icon: Icons.videocam_outlined,
              title: 'Gestionar Cámaras',
              subtitle: 'Configura tus cámaras',
              onTap: () {
                // Cambiar al tab de cámaras (índice 1)
                widget.onTabChange?.call(1);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          icon,
          color: Colors.white70,
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              )
            : null,
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white54,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAlertasCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Icon(
          alertasActivadas ? Icons.notifications_active : Icons.notifications_off,
          color: alertasActivadas ? AppConstants.primaryBlue : Colors.grey,
          size: 24,
        ),
        title: const Text(
          'Notificaciones Push',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          alertasActivadas
            ? 'Recibirás alertas de incidentes en tiempo real'
            : 'No recibirás notificaciones de incidentes',
          style: TextStyle(
            color: alertasActivadas ? Colors.white70 : Colors.white54,
            fontSize: 13,
          ),
        ),
        trailing: Switch(
          value: alertasActivadas,
          onChanged: (bool value) {
            setState(() {
              alertasActivadas = value;
            });

            // Mostrar feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  value
                    ? '✅ Notificaciones activadas'
                    : '🔕 Notificaciones desactivadas',
                ),
                backgroundColor: value ? AppConstants.success : Colors.grey[700],
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          activeColor: AppConstants.primaryBlue,
          activeTrackColor: AppConstants.primaryBlue.withOpacity(0.3),
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: Colors.grey.withOpacity(0.3),
        ),
      ),
    );
  }
}