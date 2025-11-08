// lib/screens/organization/accept_invitation_web_wrapper.dart

import 'package:flutter/material.dart';
import 'package:curso/screens/organization/accept_invitation_screen.dart';
import 'dart:html' as html;

/// Wrapper para extraer el token del query parameter en web
class AcceptInvitationWebWrapper extends StatelessWidget {
  const AcceptInvitationWebWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Extraer token del query parameter
    final uri = Uri.parse(html.window.location.href);
    final token = uri.queryParameters['token'];

    if (token == null || token.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF121721),
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red),
                SizedBox(height: 24),
                Text(
                  'Token de invitación no encontrado',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'El link de invitación no es válido',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AcceptInvitationScreen(token: token);
  }
}
