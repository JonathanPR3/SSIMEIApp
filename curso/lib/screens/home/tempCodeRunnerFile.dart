import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:curso/screens/gestion_camaras.dart';
import 'package:curso/screens/incidencias.dart';
import 'package:curso/screens/registros_actividad.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Método para generar una notificación de prueba
  void generarNotificacion() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("Notificación tocada: ${response.payload}");
      },
    );

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'canal_notificaciones',
      'Notificaciones del sistema',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      "Nueva incidencia",
      "Se ha detectado una pose sospechosa en la cámara 1.",
      notificationDetails,
      payload: 'payload',
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const maxContentWidth = 1200.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sistema de Seguridad"),
        backgroundColor: const Color(0xFF1A6BE5),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF1A6BE5)),
              child: Text(
                "Menú",
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF1A6BE5)),
              title: const Text("Gestión de cámaras"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/gestion_camaras');
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning, color: Color(0xFF1A6BE5)),
              title: const Text("Incidencias"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/incidencias');
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment, color: Color(0xFF1A6BE5)),
              title: const Text("Registros de actividad"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/registros_actividad');
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: maxContentWidth),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Estado del sistema",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A6BE5),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Cámaras activas: 4",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Última incidencia: Hace 5 minutos",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Estado: Todo en orden",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          print("Ver detalles del sistema");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A6BE5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Ver detalles",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Notificaciones recientes",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A6BE5),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: [
                    _buildNotificationTile(
                      title: "Pose sospechosa detectada",
                      subtitle: "Hace 5 minutos",
                    ),
                    _buildNotificationTile(
                      title: "Movimiento inusual detectado",
                      subtitle: "Hace 15 minutos",
                    ),
                    _buildNotificationTile(
                      title: "Cámara 3 desconectada",
                      subtitle: "Hace 1 hora",
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: generarNotificacion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A6BE5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Generar notificación de prueba",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ListTile _buildNotificationTile({required String title, required String subtitle}) {
    return ListTile(
      leading: const Icon(Icons.notifications, color: Colors.orange),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () {
        print("Ver detalles de la notificación: $title");
      },
    );
  }
}
