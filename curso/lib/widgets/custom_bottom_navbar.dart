import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final GlobalKey? inicioKey;
  final GlobalKey? camarasKey;
  final GlobalKey? incidenciasKey;
  final GlobalKey? perfilKey;
  final GlobalKey? ajustesKey;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.inicioKey,
    this.camarasKey,
    this.incidenciasKey,
    this.perfilKey,
    this.ajustesKey,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF1A6BE5),
      unselectedItemColor: Colors.grey,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home, key: inicioKey),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.camera_alt, key: camarasKey),
          label: 'Cámaras',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.warning, key: incidenciasKey),
          label: 'Evidencias',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person, key: perfilKey),
          label: 'Perfil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings, key: ajustesKey),
          label: 'Ajustes',
        ),
      ],
    );
  }
}