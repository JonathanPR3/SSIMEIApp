// lib/screens/register_screen.dart - Actualización clave
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'package:curso/constants/app_constants.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController apellidoPaternoController = TextEditingController();
  final TextEditingController apellidoMaternoController = TextEditingController();
  
  // NUEVO: Variable para controlar la visibilidad de la contraseña
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nombreController.dispose();
    apellidoPaternoController.dispose();
    apellidoMaternoController.dispose();
    super.dispose();
  }

  void _register() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String nombre = nombreController.text.trim();
    String apellidoPaterno = apellidoPaternoController.text.trim();
    String apellidoMaterno = apellidoMaternoController.text.trim();

    // Validaciones
    if (nombre.isEmpty || apellidoPaterno.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar('Por favor, completa los campos obligatorios.');
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnackBar('Por favor, ingresa un correo válido.');
      return;
    }

    if (!_isStrongPassword(password)) {
      _showSnackBar('La contraseña debe tener mínimo 8 caracteres, incluir mayúsculas, minúsculas y números.');
      return;
    }

    final success = await ref.read(authNotifierProvider.notifier).registerAdmin(
      email: email,
      password: password,
      nombre: nombre,
      apellidoPaterno: apellidoPaterno,
      apellidoMaterno: apellidoMaterno,
    );

    if (success) {
      _showSnackBar('Registro exitoso. Verifica tu correo electrónico.');

      // NUEVO FLUJO: Navegar a pantalla de confirmación de email
      Future.delayed(const Duration(milliseconds: 1500), () {
        Navigator.pushNamed(
          context,
          AppConstants.confirmEmailRoute,
          arguments: {'email': email},
        );
      });
    } else {
      final error = ref.read(authNotifierProvider).errorMessage;
      
      if (error != null) {
        // NUEVO: Manejar caso de usuario ya registrado
        if (_isUserAlreadyExistsError(error)) {
          _handleExistingUser(email);
        } else {
          _showSnackBar(error);
        }
      }
    }
  }

  // NUEVO: Detectar si el usuario ya existe
  bool _isUserAlreadyExistsError(String error) {
    return error.toLowerCase().contains('ya existe') ||
           error.toLowerCase().contains('already exists') ||
           error.toLowerCase().contains('UsernameExistsException');
  }

  // NUEVO: Manejar usuario existente
  void _handleExistingUser(String email) {
    showDialog(
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
              Icons.person_outline,
              color: AppConstants.warning,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Usuario ya existe',
              style: TextStyle(color: AppConstants.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ya existe una cuenta con el email $email',
              style: TextStyle(color: AppConstants.textLight),
            ),
            const SizedBox(height: 8),
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppConstants.textLight),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _goToLogin();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryBlue,
            ),
            child: const Text(
              'Iniciar sesión',
              style: TextStyle(color: AppConstants.white),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _goToConfirmation(email);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.success,
            ),
            child: const Text(
              'Confirmar email',
              style: TextStyle(color: AppConstants.white),
            ),
          ),
        ],
      ),
    );
  }

  // NUEVO: Ir al login
  void _goToLogin() {
    Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
  }

  // NUEVO: Ir a confirmación con email
  void _goToConfirmation(String email) {
    Navigator.pushNamed(
      context,
      AppConstants.confirmEmailRoute,
      arguments: {'email': email},
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains('exitoso') || message.contains('confirmado') 
            ? AppConstants.success
            : AppConstants.error,
      ),
    );
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    return emailRegex.hasMatch(email);
  }

  bool _isStrongPassword(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
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
              // Título
              const Text(
                "¡Crea tu cuenta!",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Regístrate para comenzar a proteger tu inmueble",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppConstants.textLight,
                ),
              ),
              const SizedBox(height: 40),
              
              // Formulario de registro
              TextField(
                controller: nombreController,
                decoration: _buildInputDecoration("Nombre"),
                style: const TextStyle(color: AppConstants.white),
                enabled: !authState.isLoading,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: apellidoPaternoController,
                decoration: _buildInputDecoration("Apellido Paterno"),
                style: const TextStyle(color: AppConstants.white),
                enabled: !authState.isLoading,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: apellidoMaternoController,
                decoration: _buildInputDecoration("Apellido Materno (opcional)"),
                style: const TextStyle(color: AppConstants.white),
                enabled: !authState.isLoading,
              ),
              const SizedBox(height: 15),
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
                onSubmitted: (_) => _register(),
              ),
              
              const SizedBox(height: 20),
              
              // Botón registrar
              SizedBox(
                width: double.infinity,
                height: AppConstants.buttonHeight,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _register,
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
                          "Registrarme",
                          style: TextStyle(
                            fontSize: 18,
                            color: AppConstants.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Link a login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "¿Ya tienes cuenta?",
                    style: TextStyle(color: AppConstants.white),
                  ),
                  TextButton(
                    onPressed: authState.isLoading ? null : _goToLogin,
                    child: const Text(
                      "Inicia sesión",
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