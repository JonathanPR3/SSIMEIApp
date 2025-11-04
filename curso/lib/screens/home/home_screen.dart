import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:curso/screens/gestion_camaras.dart';
import 'package:curso/screens/incidencias.dart';
import 'package:curso/screens/home/user_profile.dart';
import 'package:curso/screens/settings/SettingsScreen.dart';
import 'package:curso/widgets/custom_bottom_navbar.dart';
import 'package:curso/providers/auth_provider.dart';
import 'package:curso/constants/app_constants.dart';
import 'package:curso/services/evidence_service.dart';
import 'package:curso/services/camera_service.dart';
import 'package:curso/models/camera_model.dart';
import 'package:curso/services/websocket_service.dart';
import 'package:curso/models/evidence_model.dart';
import 'dart:async';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> cameras = [];
  List<Map<String, dynamic>> recentEvidences = [];
  bool isLoading = true;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<EvidenceModel>? _incidentSubscription;

  @override
  void initState() {
    super.initState();
    _inicializarNotificaciones();
    _loadHomeData();
    _conectarWebSocket(); // NUEVO: Conectar WebSocket para notificaciones en tiempo real
  }

  @override
  void dispose() {
    _incidentSubscription?.cancel();
    webSocketService.disconnect();
    super.dispose();
  }

  Future<void> _loadHomeData() async {
    print('🔄 Cargando datos del home...');
    setState(() => isLoading = true);

    try {
      final results = await Future.wait([
        CameraService.getCameras(),
        EvidenceService.getEvidences(),
      ]);

      final camerasResult = results[0] as List;
      final evidencesResult = results[1] as List;

      print('✅ Datos cargados: ${camerasResult.length} cámaras, ${evidencesResult.length} evidencias');

      setState(() {
        cameras = camerasResult.take(4).map((camera) => {
          'id': camera.id,
          'name': camera.name,
          'location': camera.location,
          'status': camera.status.displayName,
          'isActive': camera.status == CameraStatus.active,
        }).toList();

        recentEvidences = evidencesResult.take(3).map((evidence) => {
          'id': evidence.id,
          'title': evidence.title,
          'camera': evidence.cameraName,
          'time': evidence.detectedAt,
          'type': evidence.type.displayName,
        }).toList();

        isLoading = false;
      });

      print('📊 Home actualizado: ${cameras.length} cámaras, ${recentEvidences.length} evidencias recientes');
    } catch (e) {
      print('❌ Error cargando datos del home: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _inicializarNotificaciones() async {
    const AndroidInitializationSettings initAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: initAndroid);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  /// Conectar al WebSocket para recibir notificaciones en tiempo real
  void _conectarWebSocket() {
    print('🔌 Conectando WebSocket...');
    webSocketService.connect();

    // Escuchar nuevos incidentes
    _incidentSubscription = webSocketService.incidentStream.listen((incident) {
      print('🚨 Nuevo incidente recibido: ${incident.title}');

      // Mostrar notificación local
      _mostrarNotificacion(incident);

      // Recargar datos del home
      _loadHomeData();

      // Mostrar SnackBar en la UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🚨 Nuevo Incidente',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(incident.title),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });
  }

  /// Mostrar notificación local cuando llega un nuevo incidente
  Future<void> _mostrarNotificacion(EvidenceModel incident) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'incidents_channel',
      'Incidentes',
      channelDescription: 'Notificaciones de incidentes detectados',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      incident.id.hashCode,
      '🚨 ${incident.title}',
      '${incident.cameraName} - ${incident.description}',
      details,
    );

    print('📨 Notificación mostrada: ${incident.title}');
  }

  String _formatEvidenceTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final evidenceDay = DateTime(time.year, time.month, time.day);
    
    if (evidenceDay == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} - ${(time.add(const Duration(minutes: 5))).hour.toString().padLeft(2, '0')}:${(time.add(const Duration(minutes: 5))).minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} - ${(time.add(const Duration(minutes: 5))).hour.toString().padLeft(2, '0')}:${(time.add(const Duration(minutes: 5))).minute.toString().padLeft(2, '0')}';
    }
  }


  AppBar _buildAppBar(int index, String? nombreUsuario) {
    switch (index) {
      case 0:
        return AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true, // Centra el título
          title: Text(
            "Bienvenido, $nombreUsuario",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: const Color(0xFF1E1E2E), // Mismo color del fondo
          foregroundColor: AppConstants.white,
          elevation: 0,
          shadowColor: Colors.transparent,
        );
      case 1:
        return AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true, // Centra el título
          title: const Text(
            "Gestión de Cámaras",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: const Color(0xFF1E1E2E), // Mismo color del fondo
          foregroundColor: AppConstants.white,
          elevation: 0,
          shadowColor: Colors.transparent,
        );
      case 2:
        return AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true, // Centra el título
          title: const Text(
            "Evidencias",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: const Color(0xFF1E1E2E), // Mismo color del fondo
          foregroundColor: AppConstants.white,
          elevation: 0,
          shadowColor: Colors.transparent,
        );
      case 3:
        return AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true, // Centra el título
          title: const Text(
            "Perfil de Usuario",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: const Color(0xFF1E1E2E), // Mismo color del fondo
          foregroundColor: AppConstants.white,
          elevation: 0,
          shadowColor: Colors.transparent,
        );
      case 4:
        return AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true, // Centra el título
          title: const Text(
            "Ajustes",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: const Color(0xFF1E1E2E), // Mismo color del fondo
          foregroundColor: AppConstants.white,
          elevation: 0,
          shadowColor: Colors.transparent,
        );
      default:
        return AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true, // Centra el título
          title: const Text(
            "SSIMEI",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: const Color(0xFF1E1E2E), // Mismo color del fondo
          foregroundColor: AppConstants.white,
          elevation: 0,
          shadowColor: Colors.transparent,
        );
    }
  }








  Widget _buildCameraCard(Map<String, dynamic> camera) {
    final isActive = camera['isActive'] as bool;
    final statusColor = isActive ? AppConstants.success : AppConstants.error;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con ícono y estado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.videocam,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Nombre
            Text(
              camera['name'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Ubicación
            Text(
              camera['location'],
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Estado
            Text(
              camera['status'],
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceCard(Map<String, dynamic> evidence) {
    final typeColor = evidence['type'] == 'Pose Sospechosa'
        ? AppConstants.orange
        : Colors.red;
    final typeIcon = evidence['type'] == 'Pose Sospechosa'
        ? Icons.person_search
        : Icons.person_off;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: typeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Ícono de tipo
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              typeIcon,
              color: typeColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evidence['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.videocam, color: Colors.grey[400], size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        evidence['camera'],
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.grey[400], size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _formatEvidenceTime(evidence['time']),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final activeCameras = cameras.where((c) => c['isActive'] == true).length;
    final recentCount = recentEvidences.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              value: '$activeCameras/${cameras.length}',
              label: 'Cámaras Activas',
              color: AppConstants.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              value: '$recentCount',
              label: 'Evidencias Hoy',
              color: AppConstants.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppConstants.primaryBlue),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHomeData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuickStats(),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mis Cámaras',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _currentIndex = 1),
                    child: Text(
                      'Ver todas',
                      style: TextStyle(
                        color: AppConstants.primaryBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Container(
              height: 160,
              margin: const EdgeInsets.only(bottom: 24),
              child: cameras.isEmpty 
                  ? Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A3E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam_off, color: Colors.grey[500], size: 32),
                            const SizedBox(height: 8),
                            Text(
                              'No hay cámaras configuradas',
                              style: TextStyle(color: Colors.grey[400], fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: cameras.length,
                      itemBuilder: (context, index) {
                        return _buildCameraCard(cameras[index]);
                      },
                    ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Evidencias',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _currentIndex = 2),
                    child: Text(
                      'Ver todas',
                      style: TextStyle(
                        color: AppConstants.primaryBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: recentEvidences.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A3E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.security,
                              size: 48,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No hay evidencias recientes',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'El sistema está monitoreando',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: recentEvidences
                          .map((evidence) => _buildEvidenceCard(evidence))
                          .toList(),
                    ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    final List<Widget> pantallas = [
      _buildHomeContent(),
      const GestionCamaras(),
      const Incidencias(),
      const UserProfileScreen(),
      SettingsScreen(
        onTabChange: (index) => setState(() => _currentIndex = index),
      ),
    ];

    return PopScope(
      canPop: _currentIndex == 0, // Solo permite salir si está en el tab principal
      onPopInvoked: (didPop) {
        // Si no está en el tab principal, regresar al tab 0
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E2E),
        appBar: _buildAppBar(_currentIndex, user?.nombre),
        body: IndexedStack(index: _currentIndex, children: pantallas),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }
}