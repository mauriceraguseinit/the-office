import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'office_game.dart';

class LightingManager extends PositionComponent with HasGameReference<OfficeGame> {
  LightingManager({
    required this.lightSources,
    required this.targetCamera,
  });

  final List<Vector2> lightSources;
  final CameraComponent targetCamera;

  double ambientDarkness = 0.55;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    size = Vector2(5000, 5000);
    position = Vector2.zero();
    priority = 500;
  }

  // 🟢 DER IMMUNITÄTS-TRICK AGAINST FLAME UPDATES:
  // Wir klinken uns in den RenderTree-Lifecycle ein. Hier bestimmt die Komponente selbst,
  // ob sie für die aktuell zeichnende Kamera überhaupt existiert.
  @override
  void renderTree(Canvas canvas) {
    if (CameraComponent.currentCamera != targetCamera) {
      return;
    }
    super.renderTree(canvas);
  }

  @override
  void render(Canvas canvas) {
    final Rect visibleRect = targetCamera.visibleWorldRect;

    canvas.saveLayer(visibleRect, Paint());
    canvas.drawRect(visibleRect, Paint()..color = Colors.black.withValues(alpha: ambientDarkness));

    for (final Vector2 lightWorldPos in lightSources) {
      _renderLightCircle(canvas, lightWorldPos);
    }

    canvas.restore();
  }

  void _renderLightCircle(Canvas canvas, Vector2 worldPos) {
    final double radius = 200.0;

    final List<Color> colors = <Color>[
      Colors.white.withValues(alpha: 1.0),
      Colors.white.withValues(alpha: 0.5),
      Colors.white.withValues(alpha: 0.0),
    ];

    final Offset centerOffset = Offset(worldPos.x, worldPos.y);

    final Shader gradient = RadialGradient(
      colors: colors,
    ).createShader(Rect.fromCircle(center: centerOffset, radius: radius));

    final Paint paint = Paint()
      ..shader = gradient
      ..blendMode = BlendMode.dstOut;

    canvas.drawCircle(centerOffset, radius, paint);
  }
}
