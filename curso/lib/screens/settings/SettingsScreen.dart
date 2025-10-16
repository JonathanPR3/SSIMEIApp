import 'package:flutter/material.dart';
import 'package:curso/screens/manage_faces_screen.dart';
import 'package:curso/screens/manage_members_screen.dart';



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
      return ManageMembersScreen(
        onBack: _hideMemberManagement,
      );

    }

    // Mostrar la pantalla de settings normal
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección Cuenta
            _buildSectionTitle('Cuenta'),
            const SizedBox(height: 12),
            _buildSettingsCard(
              icon: Icons.person_outline,
              title: 'Editar Perfil',
              onTap: () {
                // Cambiar al tab de perfil (índice 3)
                widget.onTabChange?.call(4);
              },
            ),
            
            const SizedBox(height: 24),
            
            // Sección Cámaras
            _buildSectionTitle('Cámaras'),
            const SizedBox(height: 12),
            _buildSettingsCard(
              icon: Icons.videocam_outlined,
              title: 'Gestionar Cámaras',
              showBadge: true,
              onTap: () {
                // Cambiar al tab de cámaras (índice 1)
                widget.onTabChange?.call(1);
              },
            ),
            
            const SizedBox(height: 24),
            
            // Sección Rostros
            _buildSectionTitle('Rostros'),
            const SizedBox(height: 12),
            _buildSettingsCard(
              icon: Icons.face_outlined,
              title: 'Gestionar Rostros',
              onTap: _showFaceManagement,
            ),
            
            const SizedBox(height: 24),
            
            // Sección Miembros
            _buildSectionTitle('Miembros'),
            const SizedBox(height: 12),
            _buildSettingsCard(
              icon: Icons.people_outline,
              title: 'Gestionar Miembros',
              onTap: _showMemberManagement,
            ),
            
            const SizedBox(height: 24),
            
            // Sección Alertas
            _buildSectionTitle('Alertas'),
            const SizedBox(height: 12),
            _buildAlertasCard(),
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
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            Icon(
              icon,
              color: Colors.white70,
              size: 24,
            ),
            if (showBadge)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: const Text(
          'Activar/Desactivar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        trailing: Switch(
          value: alertasActivadas,
          onChanged: (bool value) {
            setState(() {
              alertasActivadas = value;
            });
          },
          activeColor: const Color(0xFF1A6BE5),
          activeTrackColor: const Color(0xFF1A6BE5).withOpacity(0.3),
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: Colors.grey.withOpacity(0.3),
        ),
      ),
    );
  }
}