import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart' hide ColorProperty;

import 'office_game.dart';

class LightingManager extends PositionComponent with HasGameReference<OfficeGame> {
  LightingManager({
    required this.lightSources,
    required this.targetCamera,
  });

  final List<TiledObject> lightSources;
  final CameraComponent targetCamera;
  double ambientDarkness = 0.75;
  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

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
    final double defaultRadius = 250.0;

    // Wir nutzen die Maße aus Tiled für Ellipsen.
    // Falls Breite/Höhe 0 sind (Punkt-Objekt), nutzen wir den Standard-Radius.
    final double halfWidth = worldPos.width != 0 ? worldPos.width / 2 : defaultRadius;
    final double halfHeight = worldPos.height != 0 ? worldPos.height / 2 : defaultRadius;

    final Offset centerOffset = Offset(
      worldPos.width != 0 ? worldPos.x + halfWidth : worldPos.x,
      worldPos.height != 0 ? worldPos.y + halfHeight : worldPos.y,
    );

    final double maxBrightness = worldPos.properties.byName.keys.contains('brightness')
        ? ((worldPos.properties.byName['brightness']!) as FloatProperty).value
        : 1.0;

    final bool flickering = worldPos.properties.byName.keys.contains('flickering')
        ? ((worldPos.properties.byName['flickering']!) as BoolProperty).value
        : false;

    final Color color = worldPos.properties.byName.keys.contains('color')
        ? ((worldPos.properties.byName['color']!) as ColorProperty).value.toColor()
        : Colors.white;

    double currentBrightness = maxBrightness;
    if (flickering) {
      // Wir nutzen einen schnelleren Takt (20 statt 15) für nervöseres Flackern
      final Random random = Random(worldPos.id + (_time * 20).toInt());
      final double noise = random.nextDouble();

      if (noise < 0.05) {
        // Kurzer kompletter Aussetzer (5% Chance)
        currentBrightness *= 0.1;
      } else if (noise < 0.15) {
        // Kurzes Flackern / Dimmen (10% Chance)
        currentBrightness *= (0.3 + random.nextDouble() * 0.4);
      }
      // Die restlichen 85% der Zeit ist das Licht voll an
    }

    // Wir speichern den Zustand und transformieren den Canvas für das elliptische Licht
    canvas.save();
    canvas.translate(centerOffset.dx, centerOffset.dy);
    canvas.scale(halfWidth, halfHeight);

    // Ein Einheitskreis-Rect für die Shader-Berechnung (da wir den Canvas skalieren)
    final Rect unitRect = Rect.fromCircle(center: Offset.zero, radius: 1.0);

    // 1. SCHRITT: Loch in die Dunkelheit stanzen
    final Paint maskPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: currentBrightness),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(unitRect)
      ..blendMode = BlendMode.dstOut;

    // Wir zeichnen einen Kreis mit Radius 1.0, der durch die Skalierung zur Ellipse wird
    canvas.drawCircle(Offset.zero, 1.0, maskPaint);

    // 2. SCHRITT: Farbiger Lichtschimmer
    final double saturation = HSVColor.fromColor(color).saturation;
    final double tintOpacity = 0.3 * saturation;

    if (tintOpacity > 0) {
      final Paint tintPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: currentBrightness * tintOpacity),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(unitRect)
        ..blendMode = BlendMode.srcOver;

      canvas.drawCircle(Offset.zero, 1.0, tintPaint);
    }

    canvas.restore();
  }
}
