// lib/utils/validators.dart
import '../constants/app_constants.dart';

class Validators {
  // Email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo electrónico es requerido';
    }
    
    final emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Ingresa un correo electrónico válido';
    }
    return null;
  }

  // Contraseña
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < AppConstants.passwordMinLength) {
      return 'La contraseña debe tener al menos ${AppConstants.passwordMinLength} caracteres';
    }
    if (!_hasUppercase(value)) {
      return 'La contraseña debe tener al menos una mayúscula';
    }
    if (!_hasLowercase(value)) {
      return 'La contraseña debe tener al menos una minúscula';
    }
    if (!_hasDigit(value)) {
      return 'La contraseña debe tener al menos un número';
    }
    return null;
  }

  // Confirmar contraseña
  static String? confirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != originalPassword) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  // Nombre (solo letras y espacios)
  static String? name(String? value, {String fieldName = 'nombre'}) {
    if (value == null || value.isEmpty) {
      return 'El $fieldName es requerido';
    }
    if (value.trim().length < 2) {
      return 'El $fieldName debe tener al menos 2 caracteres';
    }
    
    final nameRegExp = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
    if (!nameRegExp.hasMatch(value)) {
      return 'El $fieldName solo puede contener letras';
    }
    return null;
  }

  // Apellido paterno
  static String? apellidoPaterno(String? value) {
    return name(value, fieldName: 'apellido paterno');
  }

  // Apellido materno
  static String? apellidoMaterno(String? value) {
    return name(value, fieldName: 'apellido materno');
  }

  // Teléfono (formato mexicano)
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Teléfono es opcional
    }
    
    // Remover espacios, guiones y paréntesis
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Verificar formato mexicano: +52 o 52 seguido de 10 dígitos
    final phoneRegExp = RegExp(r'^(\+52|52)?[0-9]{10}$');
    if (!phoneRegExp.hasMatch(cleanPhone)) {
      return 'Ingresa un número de teléfono válido (10 dígitos)';
    }
    
    return null;
  }

  // Código de verificación (6 dígitos)
  static String? verificationCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'El código de verificación es requerido';
    }
    
    final codeRegExp = RegExp(r'^[0-9]{6}$');
    if (!codeRegExp.hasMatch(value)) {
      return 'El código debe tener exactamente 6 dígitos';
    }
    return null;
  }

  // Código de invitación (8 caracteres alfanuméricos)
  static String? invitationCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'El código de invitación es requerido';
    }
    
    final invitationRegExp = RegExp(r'^[A-Z0-9]{8}$');
    if (!invitationRegExp.hasMatch(value)) {
      return 'El código debe tener 8 caracteres (letras mayúsculas y números)';
    }
    return null;
  }

  // URL RTSP para cámaras
  static String? rtspUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'La URL RTSP es requerida';
    }
    if (!value.toLowerCase().startsWith('rtsp://')) {
      return 'La URL debe comenzar con rtsp://';
    }
    
    final urlRegExp = RegExp(r'^rtsp://[a-zA-Z0-9.-]+(?::[0-9]+)?(?:/.*)?$');
    if (!urlRegExp.hasMatch(value)) {
      return 'Ingresa una URL RTSP válida';
    }
    return null;
  }

  // Nombre de cámara
  static String? cameraName(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre de la cámara es requerido';
    }
    if (value.trim().length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }
    if (value.trim().length > 30) {
      return 'El nombre no puede exceder 30 caracteres';
    }
    return null;
  }

  // Campo requerido genérico
  static String? required(String? value, {String fieldName = 'campo'}) {
    if (value == null || value.trim().isEmpty) {
      return 'El $fieldName es requerido';
    }
    return null;
  }

  // ===== MÉTODOS PRIVADOS =====

  static bool _hasUppercase(String value) {
    return RegExp(r'[A-Z]').hasMatch(value);
  }

  static bool _hasLowercase(String value) {
    return RegExp(r'[a-z]').hasMatch(value);
  }

  static bool _hasDigit(String value) {
    return RegExp(r'[0-9]').hasMatch(value);
  }
}

// Extensión para limpiar strings
extension StringValidation on String {
  String get cleaned => trim();
  
  String get capitalizeFirst {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
  
  String get capitalizeWords {
    return split(' ')
        .map((word) => word.capitalizeFirst)
        .join(' ');
  }
  
  String get phoneFormatted {
    final clean = replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (clean.length == 10) {
      return '${clean.substring(0, 3)} ${clean.substring(3, 6)} ${clean.substring(6)}';
    }
    return this;
  }
}