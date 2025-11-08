// lib/screens/organization/accept_invitation_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curso/services/invitation_service.dart';
import 'package:curso/services/join_request_service.dart';
import 'package:curso/models/invitation_model.dart';
import 'package:curso/models/join_request_model.dart';
import 'package:curso/constants/app_constants.dart';

class AcceptInvitationScreen extends StatefulWidget {
  final String token;

  const AcceptInvitationScreen({
    super.key,
    required this.token,
  });

  @override
  State<AcceptInvitationScreen> createState() => _AcceptInvitationScreenState();
}

class _AcceptInvitationScreenState extends State<AcceptInvitationScreen> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _isAccepting = false;
  InvitationVerification? _invitationInfo;
  String? _errorMessage;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkAuthentication();
    await _verifyInvitation();
  }

  Future<void> _checkAuthentication() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_access_token');
      setState(() {
        _isAuthenticated = token != null;
      });
    } catch (e) {
      print('Error checking auth: $e');
    }
  }

  Future<void> _verifyInvitation() async {
    try {
      final verification = await InvitationService.verifyInvitation(widget.token);
      setState(() {
        _invitationInfo = verification;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptInvitation() async {
    if (!_isAuthenticated) {
      _showLoginRequiredDialog();
      return;
    }

    setState(() {
      _isAccepting = true;
    });

    try {
      // Crear solicitud de unión en vez de unirse directamente
      final result = await JoinRequestService.createJoinRequest(
        invitationToken: widget.token,
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
      );

      if (mounted) {
        // Mostrar éxito (solicitud enviada)
        _showSuccessDialog(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAccepting = false;
        });
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: Row(
          children: [
            Icon(Icons.login, color: AppConstants.primaryBlue),
            const SizedBox(width: 12),
            const Text(
              'Sesión Requerida',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'Necesitas iniciar sesión o crear una cuenta para aceptar esta invitación.',
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
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryBlue,
            ),
            child: const Text('Ir a Login'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(JoinRequest result) {
    final orgName = result.organizationName ?? 'la organización';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: Row(
          children: [
            Icon(Icons.send, color: AppConstants.primaryBlue, size: 32),
            const SizedBox(width: 12),
            const Text(
              'Solicitud Enviada',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'Tu solicitud para unirte a $orgName ha sido enviada. Recibirás una notificación cuando el administrador la apruebe.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryBlue,
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
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
          error,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.darkBackground,
      appBar: AppBar(
        backgroundColor: AppConstants.cardBackground,
        title: const Text('Invitación'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return _buildError();
    }

    if (_invitationInfo == null || !_invitationInfo!.valid) {
      return _buildInvalidInvitation();
    }

    return _buildInvitationContent();
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppConstants.error,
            ),
            const SizedBox(height: 24),
            const Text(
              'Error al Verificar Invitación',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Error desconocido',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvalidInvitation() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.link_off,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            const Text(
              'Invitación No Válida',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _invitationInfo?.message ?? 'Esta invitación ha expirado o ya fue utilizada',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icono principal
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppConstants.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.group_add,
                size: 60,
                color: AppConstants.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Título
          const Text(
            'Has sido invitado',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Organización
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppConstants.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppConstants.primaryBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.business,
                  color: AppConstants.primaryBlue,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  _invitationInfo!.organizationName ?? 'Organización',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Rol: Usuario',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Info adicional
          if (!_isAuthenticated)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppConstants.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppConstants.orange),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Necesitas iniciar sesión o crear una cuenta para continuar',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Campo opcional para mensaje
          if (_isAuthenticated) ...[
            TextField(
              controller: _messageController,
              maxLines: 3,
              maxLength: 200,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Mensaje (opcional)',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: 'Añade un mensaje para el administrador...',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: AppConstants.cardBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white30),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppConstants.primaryBlue),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Botones
          if (_isAuthenticated) ...[
            ElevatedButton(
              onPressed: _isAccepting ? null : _acceptInvitation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isAccepting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Enviar Solicitud',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isAccepting ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.white30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Rechazar',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Iniciar Sesión',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppConstants.primaryBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Crear Cuenta',
                style: TextStyle(
                  color: AppConstants.primaryBlue,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
