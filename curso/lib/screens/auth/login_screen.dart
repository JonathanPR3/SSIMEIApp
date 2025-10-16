// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'package:curso/constants/app_constants.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  // NUEVO: Variable para controlar la visibilidad de la contraseña
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }




  Future<void> _iniciarSesion() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Por favor, completa todos los campos.');
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnackBar('Por favor, ingresa un correo válido.');
      return;
    }

    // Usar el AuthProvider para hacer login
    final success = await ref.read(authNotifierProvider.notifier).login(
      email: email,
      password: password,
    );

    // VERIFICAR SI EL WIDGET SIGUE MONTADO
    if (!mounted) return;

    if (success) {
      _showSnackBar('Inicio de sesión exitoso');
      
      // CAMBIO CRÍTICO: Verificar mounted también en el Future.delayed
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return; // ⭐ ESTA LÍNEA ES CLAVE
        
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppConstants.homeRoute,
          (route) => false,
        );
      });
    } else {
      // NUEVO: Manejar diferentes tipos de errores
      final error = ref.read(authNotifierProvider).errorMessage;
      
      if (error != null) {
        print('🔍 Error de login recibido: $error');
        
        // Detectar si el error es por cuenta no confirmada
        if (_isUserNotConfirmedError(error)) {
          print('🚨 Detectado error de cuenta no confirmada');
          _handleUnconfirmedUser(email);
        } else {
          print('⚠️ Mostrando error normal: $error');
          _showSnackBar(error);
        }
      }
    }
  }





  // NUEVO: Detectar si el error es por cuenta no confirmada
  bool _isUserNotConfirmedError(String error) {
    return error.toLowerCase().contains('verifica tu email') ||
           error.toLowerCase().contains('not confirmed') ||
           error.toLowerCase().contains('usernotconfirmedexception') ||
           error.toLowerCase().contains('user confirmation necessary');
  }

  // NUEVO: Manejar usuario no confirmado
  void _handleUnconfirmedUser(String email) {
    // VERIFICAR MOUNTED ANTES DE MOSTRAR DIALOG
    if (!mounted) return;
    
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
              Icons.email_outlined,
              color: AppConstants.warning,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Cuenta no confirmada',
              style: TextStyle(color: AppConstants.white),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu cuenta existe pero aún no está confirmada.',
              style: TextStyle(color: AppConstants.textLight),
            ),
            SizedBox(height: 8),
            Text(
              '¿Qué deseas hacer?',
              style: TextStyle(
                color: AppConstants.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (!mounted) return; // ⭐ VERIFICAR MOUNTED
              Navigator.of(context).pop();
            },
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppConstants.textLight),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (!mounted) return; // ⭐ VERIFICAR MOUNTED
              Navigator.of(context).pop();
              _resendConfirmationCode(email);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryBlue,
            ),
            child: const Text(
              'Reenviar código',
              style: TextStyle(color: AppConstants.white),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (!mounted) return; // ⭐ VERIFICAR MOUNTED
              Navigator.of(context).pop();
              _goToConfirmation(email);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.success,
            ),
            child: const Text(
              'Confirmar ahora',
              style: TextStyle(color: AppConstants.white),
            ),
          ),
        ],
      ),
    );
  }




  // NUEVO: Reenviar código de confirmación
  Future<void> _resendConfirmationCode(String email) async {
    try {
      final success = await ref.read(authNotifierProvider.notifier).resendConfirmationCode(email);
      
      // VERIFICAR MOUNTED DESPUÉS DE LA OPERACIÓN ASÍNCRONA
      if (!mounted) return;
      
      if (success) {
        _showSnackBar('Código reenviado a $email');
        _goToConfirmation(email);
      } else {
        final error = ref.read(authNotifierProvider).errorMessage;
        _showSnackBar(error ?? 'Error al reenviar código');
      }
    } catch (e) {
      if (!mounted) return; // ⭐ VERIFICAR MOUNTED EN CATCH
      _showSnackBar('Error al reenviar código');
    }
  }




  // NUEVO: Ir a pantalla de confirmación
  void _goToConfirmation(String email) {
    if (!mounted) return; // ⭐ VERIFICAR MOUNTED
    
    Navigator.pushNamed(
      context, 
      '/confirm-email',
      arguments: {'email': email},
    );
  }

void _recuperarContrasena() {
  if (!mounted) return; // ⭐ VERIFICAR MOUNTED
  Navigator.pushNamed(context, '/forgot-password');
}

void _irARegistro() {
  if (!mounted) return; // ⭐ VERIFICAR MOUNTED
  Navigator.pushReplacementNamed(context, AppConstants.registerRoute);
}

void _showSnackBar(String message) {
  if (!mounted) return; // ⭐ VERIFICAR MOUNTED ANTES DE USAR CONTEXT
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: message.contains('exitoso') || message.contains('reenviado')
          ? AppConstants.success
          : AppConstants.error,
    ),
  );
}






  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    
    return Scaffold(
      backgroundColor: AppConstants.darkBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.largePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "¡Bienvenido de nuevo!",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Inicia sesión para proteger tu inmueble",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppConstants.textLight,
                ),
              ),
              const SizedBox(height: 40),
              
              // Campo Email
              TextField(
                controller: emailController,
                decoration: _buildInputDecoration("Correo electrónico"),
                style: const TextStyle(color: AppConstants.white),
                keyboardType: TextInputType.emailAddress,
                enabled: !authState.isLoading,
              ),
              const SizedBox(height: 15),
              
              // Campo Contraseña - MODIFICADO para incluir el ojito
              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: _buildPasswordDecoration("Contraseña"),
                style: const TextStyle(color: AppConstants.white),
                enabled: !authState.isLoading,
                onSubmitted: (_) => _iniciarSesion(),
              ),
              const SizedBox(height: 10),
              
              // Link recuperar contraseña
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: authState.isLoading ? null : _recuperarContrasena,
                  child: const Text(
                    "¿Olvidaste tu contraseña?",
                    style: TextStyle(
                      color: AppConstants.primaryBlue,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              
              // Botón Iniciar Sesión
              SizedBox(
                width: double.infinity,
                height: AppConstants.buttonHeight,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _iniciarSesion,
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
                          "Iniciar sesión",
                          style: TextStyle(fontSize: 18, color: AppConstants.white),
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Link a registro
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "¿No tienes una cuenta?",
                    style: TextStyle(color: AppConstants.white),
                  ),
                  TextButton(
                    onPressed: authState.isLoading ? null : _irARegistro,
                    child: const Text(
                      "Regístrate",
                      style: TextStyle(
                        color: AppConstants.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Mostrar error si existe
              if (authState.errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(10),
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
    );
  }

  // NUEVO: Método para crear la decoración del campo de contraseña con el ojito
  InputDecoration _buildPasswordDecoration(String label) {
    return InputDecoration(
      filled: true,
      fillColor: AppConstants.cardBackground,
      labelText: label,
      labelStyle: const TextStyle(color: AppConstants.textLight),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius + 2),
        borderSide: BorderSide.none,
      ),
      suffixIcon: IconButton(
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        icon: Icon(
          _obscurePassword ? Icons.visibility : Icons.visibility_off,
          color: AppConstants.textLight,
        ),
      ),
    );
  }
}