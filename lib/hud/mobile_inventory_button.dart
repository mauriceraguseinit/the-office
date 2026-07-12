import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

/// Ein reiner Touch-Button für die mobile Steuerung unten in der Mitte
/// Ein robuster Pixel-Look Touch-Button, der den Rucksack manuell zeichnet (kein Emoji-Fehler!)
/// Ein Button, der einen gefüllten Kreis als Hintergrund hat und das Rucksack-Sprite zentriert.
/// Ein Button im groben 8-Bit-Pixel-Stil (kantig, kein perfekter Kreis)
class MobileInventoryButton extends PositionComponent with TapCallbacks {
  MobileInventoryButton({
    required super.position,
    required this._onPressed,
  }) : super(size: Vector2(70, 70), anchor: Anchor.center);
  final VoidCallback _onPressed;

  @override
  Future<void> onLoad() async {
    // Das Icon laden
    final Sprite sprite = await Sprite.load('backpack.png');
    add(
      SpriteComponent(
        sprite: sprite,
        size: Vector2(70, 70),
        anchor: Anchor.center,
        position: size / 2,
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    // 1. Hintergrund-Box (dunkles Anthrazit)
    final Paint bgPaint = Paint()..color = const Color(0xFF2C3E50);

    // 2. Rahmen-Paint (Weiß, Pixel-Stil)
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Wir zeichnen ein Quadrat mit einer kleinen "Einbuchtung" an den Ecken,
    // um den Pixel-Look zu erzeugen:
    final Rect rect = Rect.fromLTWH(0, 0, size.x, size.y);

    // Hintergrund zeichnen
    canvas.drawRect(rect, bgPaint);

    // Rahmen zeichnen (einfaches Quadrat wirkt hier pixeliger als ein Kreis)
    canvas.drawRect(rect.deflate(2), borderPaint);

    // Ecken "abrunden" durch Überzeichnen (Pixel-Art-Stil)
    final Paint clearPaint = Paint()
      ..color = const Color(0x00000000)
      ..blendMode = BlendMode.clear;
    canvas.drawRect(Rect.fromLTWH(0, 0, 4, 4), clearPaint); // Ecke oben links weg
    canvas.drawRect(Rect.fromLTWH(size.x - 4, 0, 4, 4), clearPaint); // Oben rechts
    canvas.drawRect(Rect.fromLTWH(0, size.y - 4, 4, 4), clearPaint); // Unten links
    canvas.drawRect(Rect.fromLTWH(size.x - 4, size.y - 4, 4, 4), clearPaint); // Unten rechts
  }

  @override
  void onTapDown(TapDownEvent event) => scale = Vector2.all(0.9);

  @override
  void onTapUp(TapUpEvent event) {
    scale = Vector2.all(1.0);
    _onPressed();
  }

  @override
  void onTapCancel(TapCancelEvent event) => scale = Vector2.all(1.0);
}
