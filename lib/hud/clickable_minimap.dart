import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class ClickableMinimap extends PositionComponent with TapCallbacks {
  ClickableMinimap({
    required this.minimapCamera,
    required this.onMinimapPressed,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size) {
    minimapCamera.viewport = FixedSizeViewport(size.x, size.y);
    add(minimapCamera);

    final RectangleComponent border = RectangleComponent(
      size: size,
      paint: Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    add(border);
  }

  final CameraComponent minimapCamera;
  final VoidCallback onMinimapPressed;

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    event.handled = true;
    onMinimapPressed();
  }
}
