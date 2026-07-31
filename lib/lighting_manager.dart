import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';

import 'office_game.dart';

class LightingManager extends PositionComponent with HasGameReference<OfficeGame> {
  LightingManager({
    required this.lightSources,
    required this.targetCamera,
  });

  final List<TiledObject> lightSources;
  final CameraComponent targetCamera;
  double ambientDarkness = 0.75;

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
    for (final TiledObject lightWorldPos in lightSources) {
      _renderLightCircle(canvas, lightWorldPos);
    }

    canvas.restore();
  }

  void _renderLightCircle(Canvas canvas, TiledObject worldPos) {
    final double radius = 250.0;
    final Offset centerOffset = Offset(
      worldPos.width != 0 ? worldPos.x + worldPos.width / 2 : worldPos.x,
      worldPos.height != 0 ? worldPos.y + worldPos.height / 2 : worldPos.y,
    );
    final double maxBrightness = worldPos.properties.byName.keys.contains('brightness')
        ? ((worldPos.properties.byName['brightness']!) as FloatProperty).value
        : 1.0;

    final List<Color> colors = <Color>[
      Colors.white.withValues(alpha: maxBrightness),
      Colors.white.withValues(alpha: maxBrightness / 2),
      Colors.white.withValues(alpha: 0.0),
    ];

    final Shader gradient =
        RadialGradient(
          colors: colors,
        ).createShader(
          Rect.fromCenter(
            center: centerOffset,
            width: worldPos.width != 0 ? worldPos.width : radius * 2,
            height: worldPos.height != 0 ? worldPos.height : radius * 2,
          ),
        );

    final Paint paint = Paint()
      ..shader = gradient
      ..blendMode = BlendMode.dstOut; // Stanzt den radialen Verlauf aus der schwarzen Ebene aus

    canvas.drawCircle(centerOffset, radius, paint);
  }
}
