// lib/constants/app_constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'SSIMEI';
  static const String appDescription = 'Sistema de Seguridad Inteligente';
  static const String version = '1.0.0';
  
  // Colores (basados en tu paleta del documento)
  static const Color primaryBlue = Color(0xFF4A9EFF);
  static const Color orange = Color(0xFFFF8A00);
  static const Color darkBackground = Color(0xFF121721);
  static const Color cardBackground = Color(0xFF2C3447);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFFE5E7EB);
  static const Color textDark = Color(0xFF374151);
  
  // Estados
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  
  // Dimensiones
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 8.0;
  static const double buttonHeight = 50.0;
  
  // Animaciones
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
  
  // Límites
  static const int maxCamerasPerUser = 10;
  static const int maxIncidentsHistory = 100;
  static const int passwordMinLength = 8;
  
  // Rutas
  static const String splashRoute = '/';
  static const String welcomeRoute = '/welcome';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String confirmEmailRoute = '/confirm-email';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String resetPasswordRoute = '/reset-password';
  static const String homeRoute = '/home';
  static const String camerasRoute = '/cameras';
  static const String incidentsRoute = '/incidents';
  static const String manageOrganizationRoute = '/manage-organization';
  
  // Storage Keys
  static const String userDataKey = 'user_data';
  static const String authTokenKey = 'auth_token';
  static const String settingsKey = 'app_settings';
  static const String camerasKey = 'user_cameras';
  static const String themeKey = 'theme_mode';
  
  // Test Users (para desarrollo)
  static const String testAdminEmail = 'admin@ssimei.com';
  static const String testCommonEmail = 'usuario@ssimei.com';
  static const String testPassword = '12345678';
}