import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class ClickableMinimap extends PositionComponent with TapCallbacks {
  final CameraComponent minimapCamera;
  final VoidCallback onMinimapPressed;

  ClickableMinimap({
    required this.minimapCamera,
    required this.onMinimapPressed,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size) {
    // Die Minimap-Kamera wird als Kind dieser Komponente hinzugefügt
    // und an deren Position/Größe angepasst
    minimapCamera.viewport = FixedSizeViewport(size.x, size.y);
    add(minimapCamera);

    // Optionaler schicker Rahmen
    final border = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    add(border);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    event.handled = true;
    // Wenn auf die Minimap geklickt wird, führen wir die Zoom-Funktion aus
    onMinimapPressed();
  }
}
