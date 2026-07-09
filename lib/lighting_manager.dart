import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'office_game.dart';

class LightingManager extends PositionComponent with HasGameReference<OfficeGame> {
  LightingManager({required this.lightSources, required this.targetCamera});
  final List<Vector2> lightSources;

  final CameraComponent targetCamera;

  double ambientDarkness = 0.55;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    size = targetCamera.viewport.size;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = targetCamera.viewport.size;
  }

  @override
  void render(Canvas canvas) {
    if (size == Vector2.zero()) return;

    final Rect screenRect = size.toRect();
    final double zoom = targetCamera.viewfinder.zoom;

    canvas.saveLayer(screenRect, Paint());
    canvas.drawRect(screenRect, Paint()..color = Colors.black.withValues(alpha: ambientDarkness));

    // Lichter zeichnen
    for (final Vector2 lightWorldPos in lightSources) {
      final Offset lightScreenPos = _worldToScreenPos(lightWorldPos, targetCamera);
      _renderLightCircle(canvas, lightScreenPos, zoom);
    }

    canvas.restore();
  }

  void _renderLightCircle(Canvas canvas, Offset screenPos, double zoom) {
    final double radius = 200.0 * zoom;

    final List<Color> colors = <Color>[
      Colors.white.withValues(alpha: 1.0),
      Colors.white.withValues(alpha: 0.5),
      Colors.white.withValues(alpha: 0.0),
    ];

    final Shader gradient = RadialGradient(
      colors: colors,
    ).createShader(Rect.fromCircle(center: screenPos, radius: radius));

    final Paint paint = Paint()
      ..shader = gradient
      ..blendMode = BlendMode.dstOut;

    canvas.drawCircle(screenPos, radius, paint);
  }

  Offset _worldToScreenPos(Vector2 worldPos, CameraComponent camera) {
    final Rect visibleRect = camera.visibleWorldRect;

    final double relativeX = worldPos.x - visibleRect.left;
    final double relativeY = worldPos.y - visibleRect.top;

    final double screenX = (relativeX / visibleRect.width) * size.x;
    final double screenY = (relativeY / visibleRect.height) * size.y;

    return Offset(screenX, screenY);
  }
}
