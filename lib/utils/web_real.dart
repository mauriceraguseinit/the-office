// lib/utils/web_real.dart
import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:web/web.dart' as web;


void toggleFullscreen(void Function(bool isFullscreen) setFullscreen) {
  if (!kIsWeb) return;

  try {
    if (web.document.fullscreenElement == null) {
      // In den Vollbildmodus wechseln
      web.document.documentElement?.requestFullscreen();
      web.window.screen.orientation.lock('landscape');
      setFullscreen(true);
    } else {
      // Vollbildmodus verlassen
      web.document.exitFullscreen();
      setFullscreen(false);
    }
  } catch (e) {
    debugPrint('Fullscreen-Toggle fehlgeschlagen: $e');
  }
}
