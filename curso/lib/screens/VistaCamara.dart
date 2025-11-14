import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:curso/constants/app_constants.dart';

class VistaCamara extends StatefulWidget {
  final String rtspUrl;

  const VistaCamara({super.key, required this.rtspUrl});

  @override
  State<VistaCamara> createState() => _VistaCamaraState();
}

class _VistaCamaraState extends State<VistaCamara> {
  late VlcPlayerController _controller;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = VlcPlayerController.network(
        widget.rtspUrl,
        autoPlay: true,
        hwAcc: HwAcc.full,
      );
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.darkBackground,
      appBar: AppBar(
        title: const Text(
          "Vista de Cámara",
          style: TextStyle(color: AppConstants.white),
        ),
        backgroundColor: AppConstants.primaryBlue,
        iconTheme: const IconThemeData(color: AppConstants.white),
      ),
      body: kIsWeb ? _buildWebView() : _buildMobileView(),
    );
  }

  // Vista para WEB (RTSP no soportado)
  Widget _buildWebView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam_off,
              size: 64,
              color: AppConstants.primaryBlue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Vista de cámara no disponible en Web',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'La reproducción de streams RTSP no está soportada en navegadores web.',
              style: TextStyle(
                fontSize: 14,
                color: AppConstants.textLight.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Vista para MOBILE/DESKTOP (VLC Player) - VERSIÓN SIMPLIFICADA
  Widget _buildMobileView() {
    return Center(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: VlcPlayer(
          controller: _controller,
          aspectRatio: 16 / 9,
          placeholder: const Center(
            child: CircularProgressIndicator(
              color: AppConstants.primaryBlue,
            ),
          ),
        ),
      ),
    );
  }
}
