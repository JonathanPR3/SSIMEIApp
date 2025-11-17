import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:curso/constants/app_constants.dart';
import 'package:curso/services/face_recognition_api_service.dart';
import 'dart:io';

/// Pantalla para probar reconocimiento facial
class TestFaceRecognitionScreen extends StatefulWidget {
  const TestFaceRecognitionScreen({super.key});

  @override
  State<TestFaceRecognitionScreen> createState() => _TestFaceRecognitionScreenState();
}

class _TestFaceRecognitionScreenState extends State<TestFaceRecognitionScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String? _recognitionResult;
  Map<String, dynamic>? _matchData;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus != PermissionStatus.granted) {
        _showMessage('Permisos de cámara denegados');
        return;
      }

      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        _showMessage('No se encontraron cámaras');
        return;
      }

      // Usar cámara frontal
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      _showMessage('Error al inicializar cámara: $e');
    }
  }

  Future<void> _captureAndRecognize() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showMessage('Cámara no inicializada');
      return;
    }

    setState(() {
      _isProcessing = true;
      _recognitionResult = 'Procesando...';
      _matchData = null;
    });

    try {
      // Capturar imagen
      final image = await _cameraController!.takePicture();
      print('📸 Imagen capturada: ${image.path}');

      // Enviar al backend para reconocimiento
      _showMessage('Reconociendo rostro...');

      final result = await FaceRecognitionApiService.recognizeFace(
        imagePath: image.path,
        threshold: 0.4,
        topN: 1,
      );

      print('📡 Resultado: $result');

      if (result['success']) {
        if (result['match_found'] == true) {
          final face = result['face'];
          final confidence = (result['confidence'] * 100).toStringAsFixed(1);

          String name = 'Desconocido';
          String type = 'unknown';

          if (face['type'] == 'registered_user' && face['user'] != null) {
            name = '${face['user']['name']} ${face['user']['last_name'] ?? ''}'.trim();
            type = 'Usuario Registrado';
          } else if (face['type'] == 'non_user' && face['metadata'] != null) {
            name = face['metadata']['full_name'];
            type = 'Visitante';
          }

          setState(() {
            _recognitionResult = '✅ Rostro Reconocido!\n\n'
                '👤 Nombre: $name\n'
                '🏷️ Tipo: $type\n'
                '📊 Confianza: $confidence%\n'
                '🆔 Face ID: ${face['id']}';
            _matchData = result;
          });

          _showMessage('✅ Rostro identificado: $name', isSuccess: true);
        } else {
          setState(() {
            _recognitionResult = '❌ Rostro No Reconocido\n\n'
                '${result['message'] ?? 'No se encontró coincidencia en la base de datos'}';
            _matchData = null;
          });

          _showMessage('❌ Rostro no reconocido');
        }
      } else {
        setState(() {
          _recognitionResult = '❌ Error\n\n${result['message']}';
          _matchData = null;
        });
        _showMessage('Error: ${result['message']}');
      }
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _recognitionResult = '❌ Error\n\n$e';
        _matchData = null;
      });
      _showMessage('Error: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : AppConstants.primaryBlue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2E),
        foregroundColor: Colors.white,
        title: const Text('Prueba de Reconocimiento'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Vista previa de la cámara
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _matchData != null && _matchData!['match_found'] == true
                      ? Colors.green
                      : AppConstants.primaryBlue,
                  width: 3,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: _isCameraInitialized
                    ? CameraPreview(_cameraController!)
                    : const Center(
                        child: CircularProgressIndicator(
                          color: AppConstants.primaryBlue,
                        ),
                      ),
              ),
            ),
          ),

          // Resultado del reconocimiento
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A3E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _matchData != null && _matchData!['match_found'] == true
                      ? Colors.green
                      : Colors.grey.shade700,
                  width: 2,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _matchData != null && _matchData!['match_found'] == true
                              ? Icons.check_circle
                              : Icons.info_outline,
                          color: _matchData != null && _matchData!['match_found'] == true
                              ? Colors.green
                              : Colors.white70,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Resultado',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _recognitionResult ?? 'Presiona el botón para capturar y reconocer un rostro',
                      style: TextStyle(
                        color: _matchData != null && _matchData!['match_found'] == true
                            ? Colors.white
                            : Colors.white70,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Botón de captura
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _captureAndRecognize,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.camera_alt, size: 28),
                label: Text(
                  _isProcessing ? 'Procesando...' : 'Capturar y Reconocer',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
              ),
            ),
          ),

          // Información
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade700, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade300, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Posiciona tu rostro en el centro y presiona el botón',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
