// lib/screens/organization/join_organization_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:curso/constants/app_constants.dart';
import 'package:curso/screens/organization/accept_invitation_screen.dart';

/// Pantalla para unirse a una organización mediante token o QR
class JoinOrganizationScreen extends StatefulWidget {
  const JoinOrganizationScreen({super.key});

  @override
  State<JoinOrganizationScreen> createState() => _JoinOrganizationScreenState();
}

class _JoinOrganizationScreenState extends State<JoinOrganizationScreen> {
  final TextEditingController _tokenController = TextEditingController();
  bool _isScanning = false;
  MobileScannerController? _scannerController;

  @override
  void dispose() {
    _tokenController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      setState(() {
        _tokenController.text = data.text!.trim();
      });
    }
  }

  void _processToken(String token) {
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor ingresa un token válido'),
          backgroundColor: AppConstants.error,
        ),
      );
      return;
    }

    // Navegar a la pantalla de aceptar invitación
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AcceptInvitationScreen(token: token),
      ),
    );
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );
    });
  }

  void _stopScanning() {
    _scannerController?.dispose();
    setState(() {
      _isScanning = false;
      _scannerController = null;
    });
  }

  void _onQRDetected(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        // Detener escaneo
        _stopScanning();

        // Procesar el token
        _processToken(code);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.darkBackground,
      appBar: AppBar(
        backgroundColor: AppConstants.cardBackground,
        title: const Text('Unirse a Organización'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_isScanning) {
              _stopScanning();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _isScanning ? _buildScanner() : _buildTokenInput(),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        // Cámara
        MobileScanner(
          controller: _scannerController,
          onDetect: _onQRDetected,
        ),
        // Overlay
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
          ),
          child: Stack(
            children: [
              // Área de escaneo transparente
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(
                      color: AppConstants.primaryBlue,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              // Instrucciones
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    const Text(
                      'Escanea el código QR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Apunta la cámara al QR de invitación',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Botón cancelar
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: _stopScanning,
                    icon: const Icon(Icons.close),
                    label: const Text('Cancelar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.cardBackground,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTokenInput() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icono principal
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppConstants.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.group_add,
                size: 50,
                color: AppConstants.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Título
          const Text(
            'Unirse a una Organización',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Botón escanear QR
          ElevatedButton.icon(
            onPressed: _startScanning,
            icon: const Icon(Icons.qr_code_scanner, size: 28),
            label: const Text(
              'Escanear Código QR',
              style: TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Divisor
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey[700])),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'o ingresa el token',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey[700])),
            ],
          ),
          const SizedBox(height: 24),

          // Campo de token
          TextField(
            controller: _tokenController,
            maxLines: 4,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
            decoration: InputDecoration(
              labelText: 'Token de Invitación',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'Pega el token aquí...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: AppConstants.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white30),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white30),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppConstants.primaryBlue),
              ),
              suffixIcon: IconButton(
                icon: Icon(Icons.paste, color: AppConstants.primaryBlue),
                onPressed: _pasteFromClipboard,
                tooltip: 'Pegar',
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Botón continuar
          OutlinedButton.icon(
            onPressed: () => _processToken(_tokenController.text.trim()),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Continuar con Token'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppConstants.primaryBlue,
              side: BorderSide(color: AppConstants.primaryBlue),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Información de ayuda
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.help_outline, color: Colors.grey[400], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '¿Cómo obtener el token?',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'El administrador de la organización debe generar una invitación y compartirte el código QR o el token de texto.',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
