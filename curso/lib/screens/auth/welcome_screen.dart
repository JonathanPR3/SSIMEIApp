import 'package:curso/screens/registro.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart'; 
import 'package:curso/widgets/auth_button.dart';
import 'package:curso/widgets/auth_title.dart';


class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121721),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const AuthTitle(text: '¡Bienvenido a SSIMEI!'),
              const SizedBox(height: 40),
              AuthButton(
                text: 'Iniciar sesión',
                backgroundColor: const Color(0xFF1A6BE5),
                onPressed: () => Navigator.pushNamed(context, '/login'),
              ),
              const SizedBox(height: 15),
              AuthButton(
                text: 'Registrarse',
                backgroundColor: const Color(0xFF243347),
                onPressed: () => Navigator.pushNamed(context, '/register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}