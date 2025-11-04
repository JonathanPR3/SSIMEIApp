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
  VlcPlayerController? _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    // VLC Player solo funciona en mobile y desktop, NO en web
    if (!kIsWeb) {
      try {
        _controller = VlcPlayerController.network(
          widget.rtspUrl,
          autoPlay: true,
          hwAcc: HwAcc.full,
          options: VlcPlayerOptions(
            advanced: VlcAdvancedOptions([
              VlcAdvancedOptions.networkCaching(1500),
            ]),
            rtp: VlcRtpOptions([
              '--rtsp-tcp', // Usar TCP en lugar de UDP para mejor compatibilidad
            ]),
          ),
        );

        _controller!.addListener(() {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Error al inicializar el reproductor: $e';
          _isLoading = false;
        });
      }
    } else {
      // En web, no se puede usar VLC
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
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

  // Vista para WEB (RTSP no soportado directamente)
  Widget _buildWebView() {
    return Container(
      color: AppConstants.darkBackground,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono de cámara
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppConstants.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(
                    color: AppConstants.primaryBlue.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.videocam_off,
                  size: 60,
                  color: AppConstants.primaryBlue,
                ),
              ),

              const SizedBox(height: 30),

              // Título
              const Text(
                'Vista de cámara no disponible en Web',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Descripción
              Text(
                'La reproducción de streams RTSP no está soportada en navegadores web.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppConstants.textLight.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // URL RTSP
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.cardBackground,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'URL RTSP:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.rtspUrl,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppConstants.textLight,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Instrucciones
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppConstants.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  border: Border.all(
                    color: AppConstants.warning.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppConstants.warning,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Para ver la cámara:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildBulletPoint('Usa la app en Android o iOS'),
                    _buildBulletPoint('O ejecuta en Windows/macOS/Linux'),
                    const SizedBox(height: 8),
                    Text(
                      'La web no soporta RTSP directamente. Necesitarías convertir el stream a HLS o WebRTC para verlo en navegador.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppConstants.textLight.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppConstants.warning,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppConstants.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Vista para MOBILE/DESKTOP (VLC Player)
  Widget _buildMobileView() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppConstants.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar la cámara',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppConstants.textLight.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppConstants.primaryBlue,
            ),
            SizedBox(height: 16),
            Text(
              'Conectando con la cámara...',
              style: TextStyle(
                color: AppConstants.textLight,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_controller == null) {
      return const Center(
        child: Text(
          'No se pudo inicializar el reproductor',
          style: TextStyle(color: AppConstants.error),
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: VlcPlayer(
          controller: _controller!,
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
