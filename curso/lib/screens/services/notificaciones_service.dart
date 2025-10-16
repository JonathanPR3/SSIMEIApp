import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificacionesService {
  static final NotificacionesService _instance = NotificacionesService._internal();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  factory NotificacionesService() {
    return _instance;
  }

  NotificacionesService._internal();

  // Inicializar el plugin de notificaciones
  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Ícono de la app

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Mostrar una notificación
  Future<void> mostrarNotificacion(String titulo, String cuerpo) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'canal_notificaciones', // ID del canal
      'Notificaciones del sistema', // Nombre del canal
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0, // ID de la notificación
      titulo,
      cuerpo,
      platformChannelSpecifics,
    );
  }
}