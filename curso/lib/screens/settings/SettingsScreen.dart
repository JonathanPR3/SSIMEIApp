import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curso/screens/manage_faces_screen.dart';
import 'package:curso/screens/organization/manage_organization_screen.dart';
import 'package:curso/screens/test_face_recognition_screen.dart';
import 'package:curso/services/invitation_service.dart';
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

  Future<void> _showJoinWithTokenDialog() async {
    final TextEditingController tokenController = TextEditingController();
    final mainContext = context; // Capturar el contexto principal del SettingsScreen

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: Row(
          children: [
            Icon(Icons.vpn_key, color: AppConstants.primaryBlue),
            const SizedBox(width: 12),
            const Text(
              'Unirse con Token',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pega el token de invitación que recibiste:',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tokenController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
                hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF1E1E2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste, color: Colors.white54),
                  onPressed: () async {
                    final clipboardData = await Clipboard.getData('text/plain');
                    if (clipboardData != null) {
                      tokenController.text = clipboardData.text ?? '';
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
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
                  Icon(Icons.info_outline, color: AppConstants.orange, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Este token te permite unirte a una organización',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final token = tokenController.text.trim();

              if (token.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor ingresa un token'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Cerrar diálogo de input
              Navigator.pop(dialogContext);

              // Mostrar loading usando el contexto principal
              showDialog(
                context: mainContext,
                barrierDismissible: false,
                builder: (loadingContext) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                // Aceptar invitación
                final result = await InvitationService.acceptInvitation(token);

                // Cerrar loading
                Navigator.of(mainContext).pop();

                // Mostrar diálogo de éxito
                if (!mounted) return;

                final orgName = result['organization']?['name'] ?? 'la organización';

                showDialog(
                  context: mainContext,
                  barrierDismissible: false,
                  builder: (successContext) => AlertDialog(
                      backgroundColor: const Color(0xFF2A2A3E),
                      title: Row(
                        children: [
                          Icon(Icons.check_circle, color: AppConstants.primaryBlue, size: 32),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              '¡Invitación Aceptada!',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Te has unido exitosamente a $orgName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppConstants.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppConstants.orange.withOpacity(0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, color: AppConstants.orange, size: 24),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Acción requerida',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Para que los cambios se reflejen correctamente, debes cerrar sesión e iniciar sesión nuevamente.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(successContext); // Cerrar diálogo

                            // Mostrar loading breve
                            showDialog(
                              context: mainContext,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            // Cerrar sesión
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.clear();

                            // Pequeña pausa para que se vea el loading
                            await Future.delayed(const Duration(milliseconds: 500));

                            // Navegar a login
                            if (mounted) {
                              Navigator.of(mainContext).pop(); // Cerrar loading
                              Navigator.of(mainContext).pushNamedAndRemoveUntil(
                                '/login',
                                (route) => false,
                              );
                            }
                          },
                          icon: const Icon(Icons.logout, size: 20),
                          label: const Text('Cerrar Sesión e Iniciar de Nuevo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  );
              } catch (e) {
                Navigator.pop(mainContext); // Cerrar loading

                // Mostrar error
                if (mounted) {
                  showDialog(
                    context: mainContext,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF2A2A3E),
                      title: Row(
                        children: [
                          Icon(Icons.error, color: AppConstants.error),
                          const SizedBox(width: 12),
                          const Text(
                            'Error',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      content: Text(
                        e.toString().replaceAll('Exception: ', ''),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryBlue,
            ),
            child: const Text('Unirse'),
          ),
        ],
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

            // Unirse con token (para desarrollo web)
            _buildSettingsCard(
              icon: Icons.vpn_key,
              title: 'Unirse con Token de Invitación',
              subtitle: 'Únete a una organización',
              onTap: _showJoinWithTokenDialog,
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