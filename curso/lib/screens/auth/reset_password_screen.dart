// lib/screens/auth/reset_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'package:curso/constants/app_constants.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final TextEditingController codeController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  String email = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
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
    codeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final code = codeController.text.trim();
    final newPassword = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // Validaciones
    if (code.isEmpty) {
      _showSnackBar('Por favor, ingresa el código de confirmación.');
      return;
    }

    if (newPassword.isEmpty) {
      _showSnackBar('Por favor, ingresa tu nueva contraseña.');
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar('Las contraseñas no coinciden.');
      return;
    }

    if (!_isStrongPassword(newPassword)) {
      _showSnackBar('La contraseña debe tener mínimo 8 caracteres, incluir mayúsculas, minúsculas y números.');
      return;
    }

    if (email.isEmpty) {
      _showSnackBar('Error: Email no encontrado.');
      return;
    }

    final success = await ref.read(authNotifierProvider.notifier).confirmPassword(
      email: email,
      confirmationCode: code,
      newPassword: newPassword,
    );

    if (success) {
      _showSnackBar('Contraseña restablecida exitosamente');
      
      // Mostrar diálogo de éxito y navegar al login
      _showSuccessDialog();
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
      final success = await ref.read(authNotifierProvider.notifier).forgotPassword(email);
      
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius + 4),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppConstants.success,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Contraseña restablecida',
              style: TextStyle(color: AppConstants.white),
            ),
          ],
        ),
        content: const Text(
          'Tu contraseña ha sido restablecida exitosamente. Ya puedes iniciar sesión con tu nueva contraseña.',
          style: TextStyle(color: AppConstants.textLight),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _goToLogin();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.success,
            ),
            child: const Text(
              'Ir al login',
              style: TextStyle(color: AppConstants.white),
            ),
          ),
        ],
      ),
    );
  }

  void _goToLogin() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppConstants.loginRoute,
      (route) => false,
    );
  }

  bool _isStrongPassword(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains('exitoso') || 
                        message.contains('restablecida') ||
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
                // Icono de nueva contraseña
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppConstants.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: AppConstants.success.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_open,
                    size: 50,
                    color: AppConstants.success,
                  ),
                ),

                const SizedBox(height: 30),

                // Título
                const Text(
                  "Restablecer contraseña",
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
                  "Ingresa el código que enviamos a:",
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
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppConstants.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Campo de código
                TextField(
                  controller: codeController,
                  decoration: _buildInputDecoration("Código de confirmación", Icons.verified_user),
                  style: const TextStyle(
                    color: AppConstants.white,
                    fontSize: 18,
                    letterSpacing: 2,
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  enabled: !authState.isLoading,
                ),

                const SizedBox(height: 20),

                // Campo de nueva contraseña
                TextField(
                  controller: passwordController,
                  decoration: _buildPasswordDecoration(
                    "Nueva contraseña",
                    _obscurePassword,
                    () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  style: const TextStyle(color: AppConstants.white),
                  obscureText: _obscurePassword,
                  enabled: !authState.isLoading,
                ),

                const SizedBox(height: 15),

                // Campo de confirmar contraseña
                TextField(
                  controller: confirmPasswordController,
                  decoration: _buildPasswordDecoration(
                    "Confirmar contraseña",
                    _obscureConfirmPassword,
                    () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  style: const TextStyle(color: AppConstants.white),
                  obscureText: _obscureConfirmPassword,
                  enabled: !authState.isLoading,
                  onSubmitted: (_) => _resetPassword(),
                ),

                const SizedBox(height: 30),

                // Botón restablecer contraseña
                SizedBox(
                  width: double.infinity,
                  height: AppConstants.buttonHeight,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.success,
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
                            "Restablecer contraseña",
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
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: AppConstants.warning,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Reenviando...",
                              style: TextStyle(
                                color: AppConstants.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          "Reenviar código",
                          style: TextStyle(
                            color: AppConstants.warning,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),

                const SizedBox(height: 32),

                // Botón volver al login
                TextButton.icon(
                  onPressed: _goToLogin,
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

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: AppConstants.cardBackground,
      labelText: label,
      labelStyle: const TextStyle(color: AppConstants.textLight),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius + 2),
        borderSide: BorderSide.none,
      ),
      counterText: '',
      prefixIcon: Icon(
        icon,
        color: AppConstants.textLight,
      ),
    );
  }

  InputDecoration _buildPasswordDecoration(String label, bool obscure, VoidCallback toggle) {
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
        Icons.lock_outline,
        color: AppConstants.textLight,
      ),
      suffixIcon: IconButton(
        onPressed: toggle,
        icon: Icon(
          obscure ? Icons.visibility : Icons.visibility_off,
          color: AppConstants.textLight,
        ),
      ),
    );
  }
}