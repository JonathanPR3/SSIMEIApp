// lib/screens/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'package:curso/constants/app_constants.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar('Por favor, ingresa tu correo electrónico.');
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnackBar('Por favor, ingresa un correo válido.');
      return;
    }

    final success = await ref.read(authNotifierProvider.notifier).forgotPassword(email);

    if (success) {
      _showSnackBar('Código enviado a $email');
      
      // Navegar a pantalla de confirmación
      Future.delayed(const Duration(milliseconds: 1000), () {
        Navigator.pushNamed(
          context,
          '/reset-password',
          arguments: {'email': email},
        );
      });
    } else {
      final error = ref.read(authNotifierProvider).errorMessage;
      if (error != null) {
        _showSnackBar(error);
      }
    }
  }

  void _goBackToLogin() {
    Navigator.pop(context);
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    return emailRegex.hasMatch(email);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains('enviado') 
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
                // Icono de password reset
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppConstants.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: AppConstants.warning.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_reset,
                    size: 50,
                    color: AppConstants.warning,
                  ),
                ),

                const SizedBox(height: 30),

                // Título
                const Text(
                  "¿Olvidaste tu contraseña?",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Descripción
                Text(
                  "No te preocupes, te enviaremos un código para restablecer tu contraseña.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppConstants.textLight.withOpacity(0.8),
                  ),
                ),

                const SizedBox(height: 40),

                // Campo de email
                TextField(
                  controller: emailController,
                  decoration: _buildInputDecoration("Correo electrónico"),
                  style: const TextStyle(color: AppConstants.white),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !authState.isLoading,
                  onSubmitted: (_) => _sendResetCode(),
                ),

                const SizedBox(height: 30),

                // Botón enviar código
                SizedBox(
                  width: double.infinity,
                  height: AppConstants.buttonHeight,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _sendResetCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.warning,
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
                            "Enviar código",
                            style: TextStyle(
                              fontSize: 18,
                              color: AppConstants.white,
                              fontWeight: FontWeight.w600,
                            ),
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
      prefixIcon: const Icon(
        Icons.email_outlined,
        color: AppConstants.textLight,
      ),
    );
  }
}