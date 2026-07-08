import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class LightingManager extends PositionComponent with HasGameReference {
  final List<Vector2> lightSources;

  // Die Kamera, die wir überwachen
  final CameraComponent targetCamera;

  double ambientDarkness = 0.55;

  LightingManager({required this.lightSources, required this.targetCamera});

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Holt die exakte virtuelle Größe des Viewports der Zielkamera
    size = targetCamera.viewport.size;
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    // Aktualisiert die physische Zeichenfläche des Licht-Overlays exakt bei jeder Fensteränderung
    size = targetCamera.viewport.size;
  }

  @override
  void render(Canvas canvas) {
    if (size == Vector2.zero()) return;

    final screenRect = size.toRect();
    final zoom = targetCamera.viewfinder.scale.x;

    canvas.saveLayer(screenRect, Paint());
    canvas.drawRect(screenRect, Paint()..color = Colors.black.withValues(alpha: ambientDarkness));

    // Lichter zeichnen
    for (final lightWorldPos in lightSources) {
      final lightScreenPos = _worldToScreenPos(lightWorldPos, targetCamera);
      _renderLightCircle(canvas, lightScreenPos, zoom);
    }

    canvas.restore();
  }

  void _renderLightCircle(Canvas canvas, Offset screenPos, double zoom) {
    final radius = 200.0 * zoom;

    final colors = [
      Colors.white.withValues(alpha: 1.0),
      Colors.white.withValues(alpha: 0.5),
      Colors.white.withValues(alpha: 0.0),
    ];

    final gradient = RadialGradient(colors: colors).createShader(Rect.fromCircle(center: screenPos, radius: radius));

    final paint = Paint()
      ..shader = gradient
      ..blendMode = BlendMode.dstOut;

    canvas.drawCircle(screenPos, radius, paint);
  }

  Offset _worldToScreenPos(Vector2 worldPos, CameraComponent camera) {
    final visibleRect = camera.visibleWorldRect;

    final relativeX = worldPos.x - visibleRect.left;
    final relativeY = worldPos.y - visibleRect.top;

    final screenX = (relativeX / visibleRect.width) * size.x;
    final screenY = (relativeY / visibleRect.height) * size.y;

    return Offset(screenX, screenY);
  }
}
