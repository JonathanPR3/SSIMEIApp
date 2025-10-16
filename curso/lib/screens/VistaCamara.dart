import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';


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
    _controller = VlcPlayerController.network(
      widget.rtspUrl,
      autoPlay: true,
      hwAcc: HwAcc.full,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vista de Cámara"),
        backgroundColor: const Color(0XFF1A6BE5),
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: VlcPlayer(
            controller: _controller,
            placeholder: const Center(child: CircularProgressIndicator()), aspectRatio: 720,
          ),
        ),
      ),
    );
  }
}
