import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:curso/constants/app_constants.dart';
import 'package:curso/services/face_service.dart';
import 'package:curso/services/face_storage_service.dart';
import 'package:curso/services/face_recognition_api_service.dart';

class FaceCaptureScreen extends StatefulWidget {
  const FaceCaptureScreen({super.key});

  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen>
    with TickerProviderStateMixin {
  int currentStep = 0;
  bool isProcessing = false;
  bool isCompleted = false;
  double confidence = 0.0;
  String currentInstruction = '';

  // Variables de cámara
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _permissionGranted = false;
  String? _errorMessage;

  // Almacenamiento de imágenes capturadas
  final List<XFile> _capturedImages = [];
  String? _currentFaceId;
  
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  final List<String> steps = [
    'Posiciona tu rostro en el centro',
    'Gira ligeramente hacia la izquierda',
    'Gira ligeramente hacia la derecha',
    'Sonríe naturalmente',
    'Mantén una expresión neutral'
  ];

  @override
  void initState() {
    super.initState();
    currentInstruction = steps[0];
    // Generar ID único para este rostro
    _currentFaceId = DateTime.now().millisecondsSinceEpoch.toString();
    _initializeCamera();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_progressController);
  }

  // AGREGAR ESTE MÉTODO COMPLETO
  Future<void> _initializeCamera() async {
    try {
      // Verificar permisos
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus != PermissionStatus.granted) {
        setState(() {
          _errorMessage = 'Permisos de cámara denegados';
        });
        return;
      }

      setState(() {
        _permissionGranted = true;
      });

      // Obtener cámaras disponibles
      _cameras = await availableCameras();
      
      if (_cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'No se encontraron cámaras';
        });
        return;
      }

      // Buscar cámara frontal
      CameraDescription frontCamera;
      try {
        frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        );
      } catch (e) {
        // Si no hay cámara frontal, usar la primera disponible
        frontCamera = _cameras!.first;
      }

      // Inicializar controlador
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al inicializar cámara: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose(); // AGREGAR ESTA LÍNEA
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _captureStep() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showMessage('Cámara no disponible');
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      // Capturar imagen REAL
      final XFile imageFile = await _cameraController!.takePicture();
      final bytes = await imageFile.readAsBytes();

      // Guardar imagen localmente
      final savedPath = await FaceStorageService.saveCapturedImage(
        imageFile: imageFile,
        faceId: _currentFaceId!,
        stepNumber: currentStep + 1,
      );

      // Agregar a la lista de imágenes capturadas
      _capturedImages.add(imageFile);

      print('✅ Imagen guardada en: $savedPath');

      // Procesar con IA (simulado por ahora)
      final result = await FaceService.processFaceCapture(
        imageData: bytes.toString(),
        stepNumber: currentStep + 1,
      );

      if (result['face_detected']) {
        setState(() {
          confidence = result['confidence'];
          currentInstruction = result['next_instruction'];
        });

        // Animar progreso
        _progressController.animateTo((currentStep + 1) / steps.length);

        await Future.delayed(const Duration(milliseconds: 800));

        if (currentStep < steps.length - 1) {
          setState(() {
            currentStep++;
          });
        } else {
          // Completar proceso
          setState(() {
            isCompleted = true;
          });
          await _completeRegistration();
        }
      } else {
        // Reintentar - eliminar imagen guardada
        await FaceStorageService.deleteFaceImages(_currentFaceId!);
        _capturedImages.clear();
        _showMessage('No se detectó rostro correctamente. Intenta de nuevo.');
      }
    } catch (e) {
      _showMessage('Error en el procesamiento: $e');
      print('❌ Error: $e');
    }

    setState(() {
      isProcessing = false;
    });
  }

  Future<void> _completeRegistration() async {
    final result = await _showRegistrationDialog();
    if (result != null) {
      try {
        final name = result['name'];
        final relationship = result['relationship'];

        if (name != null && relationship != null && name.isNotEmpty && relationship.isNotEmpty) {
          // Obtener todas las imágenes guardadas de este rostro
          final savedImages = await FaceStorageService.getFaceImages(_currentFaceId!);
          final imagePaths = savedImages.map((file) => file.path).toList();

          print('📸 Total de imágenes capturadas: ${imagePaths.length}');
          print('📂 Ubicación: ${imagePaths.isNotEmpty ? imagePaths.first : "N/A"}');

          // NUEVO: Enviar la PRIMERA imagen al backend
          if (imagePaths.isNotEmpty) {
            _showMessage('Enviando rostro al backend...');

            final apiResult = await FaceRecognitionApiService.registerFace(
              imagePath: imagePaths.first, // Solo la primera imagen
              userId: null, // null = persona sin usuario registrado
              fullName: name,
            );

            if (apiResult['success']) {
              print('✅ Backend procesó el rostro correctamente');
              print('   Face ID (backend): ${apiResult['face_id']}');
              print('   Type: ${apiResult['type']}');

              // Registrar también localmente (opcional, para compatibilidad)
              await FaceService.registerFace(
                name: name,
                relationship: relationship,
                imageUrl: imagePaths.first,
                processingResult: {
                  'steps_completed': steps.length,
                  'final_confidence': confidence,
                  'processing_time': DateTime.now().millisecondsSinceEpoch,
                  'face_id': _currentFaceId,
                  'backend_face_id': apiResult['face_id'], // ID del backend
                },
                savedImagePaths: imagePaths,
              );

              _showMessage('✅ Rostro registrado exitosamente en el servidor');
              await Future.delayed(const Duration(seconds: 2));
              Navigator.pop(context, true);
            } else {
              // Error del backend
              _showMessage('❌ Error del servidor: ${apiResult['message']}');
              print('❌ Error del backend: ${apiResult['message']}');

              // Preguntar si quiere guardar localmente de todos modos
              final saveLocal = await _showErrorDialog(
                'Error al registrar en servidor',
                '${apiResult['message']}\n\n¿Deseas guardar localmente?',
              );

              if (saveLocal == true) {
                await FaceService.registerFace(
                  name: name,
                  relationship: relationship,
                  imageUrl: imagePaths.first,
                  processingResult: {
                    'steps_completed': steps.length,
                    'final_confidence': confidence,
                    'processing_time': DateTime.now().millisecondsSinceEpoch,
                    'face_id': _currentFaceId,
                    'backend_error': apiResult['message'],
                  },
                  savedImagePaths: imagePaths,
                );

                _showMessage('Guardado localmente');
                await Future.delayed(const Duration(seconds: 2));
                Navigator.pop(context, true);
              }
            }
          } else {
            _showMessage('No se capturó ninguna imagen');
          }
        } else {
          _showMessage('Por favor completa todos los campos');
        }

      } catch (e) {
        _showMessage('Error al registrar el rostro: $e');
        print('❌ Error en registro: $e');
      }
    }
  }

  Future<Map<String, String>?> _showRegistrationDialog() async {
    final nameController = TextEditingController();
    final relationshipController = TextEditingController();
    
    return await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text(
          'Información del Rostro',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nombre completo',
                labelStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppConstants.primaryBlue),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: relationshipController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Relación (ej: Familiar, Empleado)',
                labelStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppConstants.primaryBlue),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryBlue,
            ),
            onPressed: () {
              if (nameController.text.isNotEmpty && 
                  relationshipController.text.isNotEmpty) {
                Navigator.pop(context, {
                  'name': nameController.text,
                  'relationship': relationshipController.text,
                });
              }
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showErrorDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryBlue,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.primaryBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Progreso de captura',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${currentStep + 1}/${steps.length}',
                style: TextStyle(
                  color: AppConstants.primaryBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: _progressAnimation.value,
                backgroundColor: Colors.grey[700],
                valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryBlue),
                minHeight: 6,
              );
            },
          ),
          if (confidence > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Confianza: ${(confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // REEMPLAZAR COMPLETAMENTE ESTE MÉTODO
  Widget _buildCameraPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isProcessing 
              ? AppConstants.orange 
              : AppConstants.primaryBlue.withAlpha(100),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: _buildCameraContent(),
      ),
    );
  }

  // AGREGAR ESTE MÉTODO COMPLETO
  Widget _buildCameraContent() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 48, color: AppConstants.error),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });
                  _initializeCamera();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_permissionGranted) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Solicitando permisos...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (!_isCameraInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Inicializando cámara...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Vista previa de la cámara REAL
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: CameraPreview(_cameraController!),
        ),
        
        // Overlay de detección
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isProcessing ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 200,
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(120),
                  border: Border.all(
                    color: isProcessing 
                        ? AppConstants.orange.withAlpha(150)
                        : AppConstants.primaryBlue.withAlpha(150),
                    width: 3,
                  ),
                ),
              ),
            );
          },
        ),
        
        // Indicador de procesamiento
        if (isProcessing)
          const CircularProgressIndicator(
            color: AppConstants.orange,
          ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            _getInstructionIcon(),
            color: AppConstants.primaryBlue,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            steps[currentStep],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            currentInstruction,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getInstructionIcon() {
    switch (currentStep) {
      case 0:
        return Icons.center_focus_strong;
      case 1:
        return Icons.arrow_back;
      case 2:
        return Icons.arrow_forward;
      case 3:
        return Icons.sentiment_satisfied;
      case 4:
        return Icons.sentiment_neutral;
      default:
        return Icons.face;
    }
  }

  Widget _buildCaptureButton() {
    if (isCompleted) {
      return Container(
        margin: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.check_circle,
              color: AppConstants.success,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Captura completada exitosamente',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (isProcessing || !_isCameraInitialized) ? null : _captureStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  !_isCameraInitialized 
                      ? 'Inicializando...'
                      : currentStep == 0 ? 'Iniciar Captura' : 'Siguiente Paso',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2E),
        foregroundColor: Colors.white,
        title: const Text('Registro de Rostro'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProgressIndicator(),
            _buildCameraPreview(),
            _buildInstructions(),
            _buildCaptureButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}