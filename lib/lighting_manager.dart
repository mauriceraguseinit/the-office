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
  double ambientDarkness = 0.85;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Groß genug ansetzen, um die gesamte Spielwelt abzudecken
    size = Vector2(20000, 20000);
    position = Vector2.zero();
    anchor = Anchor.topLeft;
  }

  @override
  void renderTree(Canvas canvas) {
    // Verhindert, dass Kameras fälschlicherweise das Lichtsystem der jeweils anderen zeichnen
    if (CameraComponent.currentCamera != targetCamera) {
      return;
    }
    super.renderTree(canvas);
  }

  @override
  void render(Canvas canvas) {
    final Rect localRect = size.toRect();

    // saveLayer wird zwingend für das korrekte Compositing von BlendMode.dstOut benötigt
    canvas.saveLayer(localRect, Paint());

    // Ambient-Dunkelheit zeichnen
    canvas.drawRect(
      localRect,
      Paint()..color = Colors.black.withValues(alpha: ambientDarkness),
    );

    // Lichtkegel in die Dunkelheit stanzen
    for (final Vector2 lightWorldPos in lightSources) {
      _renderLightCircle(canvas, lightWorldPos);
    }

    canvas.restore();
  }

  void _renderLightCircle(Canvas canvas, Vector2 worldPos) {
    final double radius = 250.0;
    final Offset centerOffset = Offset(worldPos.x, worldPos.y);

    final List<Color> colors = <Color>[
      Colors.white.withValues(alpha: 1.0),
      Colors.white.withValues(alpha: 0.5),
      Colors.white.withValues(alpha: 0.0),
    ];

    final Shader gradient = RadialGradient(
      colors: colors,
    ).createShader(Rect.fromCircle(center: centerOffset, radius: radius));

    final Paint paint = Paint()
      ..shader = gradient
      ..blendMode = BlendMode.dstOut; // Stanzt den radialen Verlauf aus der schwarzen Ebene aus

    canvas.drawCircle(centerOffset, radius, paint);
  }
}
