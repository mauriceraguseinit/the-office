import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class VerticalWall extends PositionComponent {
  final Color color;
  final double strokeWidth;
  final bool isFilled;
  final bool hasShadow; // Neu: Schatten an/ausschaltbar machen
  late final Paint _paint;

  VerticalWall({
    required super.position,
    required super.size,
    this.color = const Color(0xFFdddddd),
    this.strokeWidth = 3.0,
    this.isFilled = true,
    this.hasShadow = true, // Standardmäßig wirft die Wand einen Schatten
  });

  @override
  void onLoad() {
    super.onLoad();
    _paint = Paint()
      ..color = color
      ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Schatten VOR der eigentlichen Wand zeichnen, damit er darunter liegt
    if (hasShadow) {
      // Path aus dem Rechteck der Wand erstellen
      final Path shadowPath = Path()..addRect(size.toRect());

      canvas.drawShadow(
        shadowPath,
        Colors.black, // Schattenfarbe (Transparenz wird über die Elevation geregelt)
        4.0, // Elevation (Höhe): Höhere Werte machen den Schatten größer/unscharfer
        true, // Transparent Occluder: Sorgt für weichere Schatten bei 2D
      );
    }

    // 2. Die eigentliche Wand zeichnen
    canvas.drawRect(size.toRect(), _paint);
  }
}
