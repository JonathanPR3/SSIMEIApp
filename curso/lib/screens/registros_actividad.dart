import 'package:flutter/material.dart';

class RegistrosActividad extends StatelessWidget {
  const RegistrosActividad({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registros de Actividad"),
        backgroundColor: const Color(0XFF1A6BE5),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            ListTile(
              leading: Icon(Icons.assignment, color: Color(0XFF1A6BE5)),
              title: Text("Inicio de sesión exitoso"),
              subtitle: Text("Usuario: admin - Hace 2 horas"),
            ),
            ListTile(
              leading: Icon(Icons.assignment, color: Color(0XFF1A6BE5)),
              title: Text("Nueva cámara conectada"),
              subtitle: Text("Cámara 4 - Hace 3 horas"),
            ),
            ListTile(
              leading: Icon(Icons.assignment, color: Color(0XFF1A6BE5)),
              title: Text("Incidencia resuelta"),
              subtitle: Text("Cámara 2 - Hace 5 horas"),
            ),
          ],
        ),
      ),
    );
  }
}