import 'package:flutter/foundation.dart';

/// Modelo de usuario
class User {
  final String nombre;
  final String correo;

  User({required this.nombre, required this.correo});

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      nombre: map['nombre'],
      correo: map['correo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'correo': correo,
    };
  }
}

/// Provider para el manejo del usuario
class UserProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;

  void setUser(User userData) {
    _user = userData;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }

  bool get isLoggedIn => _user != null;
}
