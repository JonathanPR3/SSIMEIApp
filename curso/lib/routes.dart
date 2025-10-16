import 'package:curso/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:curso/screens/auth/welcome_screen.dart';
import 'package:curso/screens/auth/login_screen.dart';
import 'package:curso/screens/auth/register_screen.dart';
import 'package:curso/screens/auth/forgot_password_screen.dart'; 
import 'package:curso/screens/auth/reset_password_screen.dart'; 
import 'package:curso/screens/home/user_profile.dart';
import 'package:curso/screens/gestion_camaras.dart';
import 'package:curso/screens/incidencias.dart';
import 'package:curso/screens/registros_actividad.dart';
import 'package:curso/screens/auth/confirm_email_screen.dart';
import 'package:curso/screens/settings/SettingsScreen.dart';






final Map<String, WidgetBuilder> appRoutes = {
  '/welcome': (context) => const WelcomeScreen(),
  '/login': (context) => const LoginScreen(),
  '/register': (context) => const RegisterScreen(),
  '/forgot-password': (context) => const ForgotPasswordScreen(), 
  '/reset-password': (context) => const ResetPasswordScreen(), 

  '/home': (context) => const HomeScreen(),
  '/gestion_camaras': (context) => const GestionCamaras(),
  '/incidencias': (context) => const Incidencias(),
  '/registros_actividad': (context) => const RegistrosActividad(),
  '/perfil_usuario': (context) => const UserProfileScreen(),
  '/confirm-email': (context) => const ConfirmEmailScreen(),
  '/settings': (context) => const SettingsScreen(), 

};
