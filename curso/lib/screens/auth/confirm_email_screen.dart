// lib/screens/confirm_email_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'package:curso/constants/app_constants.dart';

class ConfirmEmailScreen extends ConsumerStatefulWidget {
  const ConfirmEmailScreen({super.key});

  @override
  ConsumerState<ConfirmEmailScreen> createState() => _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends ConsumerState<ConfirmEmailScreen> {
  final TextEditingController confirmationCodeController = TextEditingController();
  String email = '';
  bool _isResending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Obtener email desde argumentos de navegación
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['email'] != null) {
      email = args['email'] as String;
    }
  }

  @override
  void dispose() {
    confirmationCodeController.dispose();
    super.dispose();
  }

  Future<void> _confirmEmail() async {
    final code = confirmationCodeController.text.trim();
    
    if (code.isEmpty) {
      _showSnackBar('Por favor, ingresa el código de confirmación.');
      return;
    }

    if (email.isEmpty) {
      _showSnackBar('Error: Email no encontrado.');
      return;
    }

    final success = await ref.read(authNotifierProvider.notifier).confirmRegistration(
      email: email,
      confirmationCode: code,
    );

    if (success) {
      _showSnackBar('Email confirmado exitosamente. Ya puedes iniciar sesión.');
      
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppConstants.loginRoute,
          (route) => false,
        );
      });
    } else {
      final error = ref.read(authNotifierProvider).errorMessage;
      if (error != null) {
        _showSnackBar(error);
      }
    }
  }

  Future<void> _resendCode() async {
    if (email.isEmpty) {
      _showSnackBar('Error: Email no encontrado.');
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      final success = await ref.read(authNotifierProvider.notifier).resendConfirmationCode(email);
      
      if (success) {
        _showSnackBar('Código reenviado a $email');
      } else {
        final error = ref.read(authNotifierProvider).errorMessage;
        _showSnackBar(error ?? 'Error al reenviar código');
      }
    } catch (e) {
      _showSnackBar('Error al reenviar código');
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  void _goBackToLogin() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppConstants.loginRoute,
      (route) => false,
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains('exitoso') || 
                        message.contains('confirmado') ||
                        message.contains('reenviado')
            ? AppConstants.success
            : AppConstants.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    
    return Scaffold(
      backgroundColor: AppConstants.darkBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.largePadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icono de email
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: AppConstants.primaryBlue.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.email_outlined,
                    size: 50,
                    color: AppConstants.primaryBlue,
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Título
                const Text(
                  "Confirma tu email",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.white,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Descripción
                Text(
                  "Hemos enviado un código de 6 dígitos a:",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppConstants.textLight.withOpacity(0.8),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Email
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppConstants.cardBackground.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  child: Text(
                    email,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppConstants.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Campo de código
                TextField(
                  controller: confirmationCodeController,
                  decoration: _buildInputDecoration("Código de confirmación"),
                  style: const TextStyle(
                    color: AppConstants.white,
                    fontSize: 18,
                    letterSpacing: 2,
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  enabled: !authState.isLoading,
                  onSubmitted: (_) => _confirmEmail(),
                ),
                
                const SizedBox(height: 20),
                
                // Botón confirmar
                SizedBox(
                  width: double.infinity,
                  height: AppConstants.buttonHeight,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _confirmEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius + 4),
                      ),
                      elevation: 5,
                    ),
                    child: authState.isLoading
                        ? const CircularProgressIndicator(
                            color: AppConstants.white,
                            strokeWidth: 2,
                          )
                        : const Text(
                            "Confirmar email",
                            style: TextStyle(
                              fontSize: 18,
                              color: AppConstants.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Sección de reenvío
                Text(
                  "¿No recibiste el código?",
                  style: TextStyle(
                    color: AppConstants.textLight.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                TextButton(
                  onPressed: _isResending ? null : _resendCode,
                  child: _isResending
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: AppConstants.primaryBlue,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Reenviando...",
                              style: TextStyle(
                                color: AppConstants.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          "Reenviar código",
                          style: TextStyle(
                            color: AppConstants.primaryBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
                
                const SizedBox(height: 32),
                
                // Botón volver al login
                TextButton.icon(
                  onPressed: _goBackToLogin,
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppConstants.textLight,
                    size: 20,
                  ),
                  label: const Text(
                    "Volver al inicio de sesión",
                    style: TextStyle(
                      color: AppConstants.textLight,
                      fontSize: 14,
                    ),
                  ),
                ),
                
                // Mostrar error si existe
                if (authState.errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      border: Border.all(color: AppConstants.error.withOpacity(0.3)),
                    ),
                    child: Text(
                      authState.errorMessage!,
                      style: const TextStyle(color: AppConstants.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      filled: true,
      fillColor: AppConstants.cardBackground,
      labelText: label,
      labelStyle: const TextStyle(color: AppConstants.textLight),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius + 2),
        borderSide: BorderSide.none,
      ),
      counterText: '', // Ocultar contador de caracteres
    );
  }
}