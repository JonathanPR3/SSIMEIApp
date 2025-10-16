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

  @override
  void initState() {
    super.initState();
    _inicializarNotificaciones();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        CameraService.getCameras(),
        EvidenceService.getEvidences(),
      ]);
      
      final camerasResult = results[0] as List;
      final evidencesResult = results[1] as List;
      
      setState(() {
        cameras = camerasResult.take(4).map((camera) => {
          'id': camera.id,
          'name': camera.name,
          'location': camera.location,
          'status': camera.status.displayName,
          'isActive': camera.status.name == 'active',
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
    } catch (e) {
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
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppConstants.primaryBlue.withAlpha(200),
                  AppConstants.primaryBlue.withAlpha(150),
                ],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.videocam,
                    size: 32,
                    color: Colors.white.withAlpha(230),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: camera['isActive'] ? AppConstants.success : AppConstants.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, color: Colors.white, size: 6),
                        const SizedBox(width: 4),
                        Text(
                          camera['isActive'] ? 'ON' : 'OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(Map<String, dynamic> evidence) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A3E),
        borderRadius: BorderRadius.all(Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 60,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppConstants.orange.withAlpha(200),
                  AppConstants.orange.withAlpha(150),
                ],
              ),
            ),
            child: Center(
              child: Icon(
                evidence['type'] == 'Pose Sospechosa' ? Icons.person_search : Icons.person_off,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatEvidenceTime(evidence['time']),
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
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
                ],
              ),
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
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A3E),
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.videocam,
              value: '$activeCameras/${cameras.length}',
              label: 'Cámaras Activas',
              color: AppConstants.success,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey[600],
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.warning_amber,
              value: '$recentCount',
              label: 'Evidencias Hoy',
              color: AppConstants.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
              height: 140,
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

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: _buildAppBar(_currentIndex, user?.nombre),
      body: IndexedStack(index: _currentIndex, children: pantallas),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}