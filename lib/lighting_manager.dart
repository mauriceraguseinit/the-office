import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class LightingManager extends PositionComponent with HasGameReference {
  final List<Vector2> lightSources;
  final List<Rect> shadowBlockers;

  double ambientDarkness = 0.85;

  LightingManager({required this.lightSources, required this.shadowBlockers});

  @override
  Future<void> onLoad() async {
    super.onLoad();
    size = game.size;
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    size = newSize;
  }

  @override
  void render(Canvas canvas) {
    if (size == Vector2.zero()) return;

    final screenRect = size.toRect();
    final camera = game.camera;
    final zoom = camera.viewfinder.scale.x;

    canvas.saveLayer(screenRect, Paint());
    canvas.drawRect(screenRect, Paint()..color = Colors.black.withValues(alpha: ambientDarkness));

    // Lichter zeichnen
    for (final lightWorldPos in lightSources) {
      final lightScreenPos = _worldToScreenPos(lightWorldPos, camera);
      _renderLightCircle(canvas, lightScreenPos, zoom);

      // Schatten von Blockern zeichnen
      for (final blocker in shadowBlockers) {
        _renderShadowFromBlocker(canvas, lightWorldPos, lightScreenPos, blocker, camera, zoom);
      }
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

  void _renderShadowFromBlocker(
    Canvas canvas,
    Vector2 lightWorldPos,
    Offset lightScreenPos,
    Rect blockerWorldRect,
    CameraComponent camera,
    double zoom,
  ) {
    final lightRadius = 250.0 * zoom;

    // DEBUG: Blocker-Position anzeigen
    final blockerScreenTopLeft = _worldToScreenPos(Vector2(blockerWorldRect.left, blockerWorldRect.top), camera);
    final blockerScreenBottomRight = _worldToScreenPos(
      Vector2(blockerWorldRect.right, blockerWorldRect.bottom),
      camera,
    );

    final blockerCenter = Vector2(blockerWorldRect.center.dx, blockerWorldRect.center.dy);
    final distToLight = lightWorldPos.distanceTo(blockerCenter);

    if (distToLight > lightRadius / zoom + 200) {
      return;
    }

    // Blocker-Ecken
    final blockerCorners = [
      Vector2(blockerWorldRect.left, blockerWorldRect.top),
      Vector2(blockerWorldRect.right, blockerWorldRect.top),
      Vector2(blockerWorldRect.right, blockerWorldRect.bottom),
      Vector2(blockerWorldRect.left, blockerWorldRect.bottom),
    ];

    final shadowPoints = <Offset>[];
    final shadowLength = 600.0; // Wie weit der Schatten geht

    for (final corner in blockerCorners) {
      // Ray vom Licht durch die Ecke
      final rayDir = corner - lightWorldPos;
      if (rayDir.length == 0) continue;

      final normalizedDir = rayDir.normalized();
      final shadowEnd = corner + (normalizedDir * shadowLength);

      final shadowScreenPos = _worldToScreenPos(shadowEnd, camera);
      shadowPoints.add(shadowScreenPos);
    }

    // Zeichne Schatten-Polygon
    if (shadowPoints.length >= 3) {
      final path = Path()..moveTo(shadowPoints[0].dx, shadowPoints[0].dy);
      for (int i = 1; i < shadowPoints.length; i++) {
        path.lineTo(shadowPoints[i].dx, shadowPoints[i].dy);
      }
      path.close();

      // Abdunkeln im Schattenbereich
      canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: ambientDarkness));
    }
  }

  Offset _worldToScreenPos(Vector2 worldPos, CameraComponent camera) {
    // Hole den sichtbaren Bereich der Kamera in World-Koordinaten
    final visibleRect = camera.visibleWorldRect;

    // Berechne die Position relativ zum Viewport
    final relativeX = worldPos.x - visibleRect.left;
    final relativeY = worldPos.y - visibleRect.top;

    // Skaliere auf Screen-Größe
    final screenX = (relativeX / visibleRect.width) * size.x;
    final screenY = (relativeY / visibleRect.height) * size.y;

    return Offset(screenX, screenY);
  }
}
