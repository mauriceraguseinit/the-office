import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:the_office/hendrik.dart';
import 'package:the_office/interactiveObjects/interactive_object.dart';
import 'package:the_office/models/interaction_system.dart';

class GymBall extends InteractiveObject {
  GymBall({
    required super.position,
    required PositionComponent renderComponent,
    super.size,
    super.priorityOffset,
    required super.displayName,
  }) : super(renderComponent: _GymBallRenderer(size: size ?? Vector2.all(64))) {
    // Wir ignorieren das von Tiled kommende renderComponent und nutzen unseren eigenen Renderer.
    // Die Hitbox bekommt eine runde Form für Kollisionen mit dem Spieler.
    add(CircleHitbox(radius: (size.x / 2) * 0.8, anchor: Anchor.center, position: size / 2));
  }

  final Vector2 _velocity = Vector2.zero();
  double _rotationSpeed = 0;
  static const double _friction = 0.98; // Verlangsamt den Ball über Zeit
  static const double _pushPower = 300; // Stärke des Schubsers durch den Spieler

  @override
  void update(double dt) {
    super.update(dt);

    if (_velocity.length > 5) {
      final Vector2 delta = _velocity * dt;
      final Vector2 nextPosition = position + delta;

      // Kollisionsprüfung mit der Umgebung via NavMesh/canWalkBetween
      if (game.canWalkBetween(position, nextPosition)) {
        position = nextPosition;
      } else {
        // Einfache Abprall-Logik (Bounce)
        final bool canMoveX = game.canWalkBetween(position, position + Vector2(delta.x, 0));
        final bool canMoveY = game.canWalkBetween(position, position + Vector2(0, delta.y));

        if (canMoveX) {
          position.x += delta.x;
          _velocity.y *= -0.7; // Energieverlust beim Abprallen
        } else if (canMoveY) {
          position.y += delta.y;
          _velocity.x *= -0.7;
        } else {
          _velocity.multiply(Vector2.all(-0.7));
        }
      }

      // Reibung anwenden
      _velocity.scale(_friction);

      // Visuelle Rotation basierend auf der Bewegung
      _rotationSpeed = _velocity.length / (size.x / 2);
      renderComponent.angle += _rotationSpeed * dt * (_velocity.x > 0 ? 1 : -1);
    } else {
      _velocity.setZero();
    }

    // Depth-Sortierung
    priority = y.toInt() + priorityOffset;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is Hendrik) {
      final Vector2 pushDir = (absoluteCenter - other.absoluteCenter).normalized();
      _velocity.setFrom(pushDir * _pushPower);
    }
  }

  @override
  List<InteractionRule> get rules => <InteractionRule>[
    InteractionRule(
      requirements: <Requirement>[NoItemRequirement()],
      actions: <GameAction>[
        ShowMessageAction('[b]Hendrik:[/b]\n\nEin Gymnastikball. Gut für den Rücken, schlecht für die Konzentration.'),
      ],
    ),
  ];
}

/// Ein interner Renderer, der den Ball im 8-Bit Stil zeichnet.
class _GymBallRenderer extends PositionComponent {
  _GymBallRenderer({required super.size}) : super(anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    final double r = size.x / 2;
    const int pixelScale = 1;

    final Paint paint = Paint()..style = PaintingStyle.fill;

    // Farb-Palette für den Verlauf (Hell -> Dunkel)
    final List<Color> palette = <Color>[
      Colors.lightBlueAccent.shade100, // Highlight Bereich
      Colors.lightBlue.shade200, // Mittel
      Colors.lightBlue.shade400, // Schatten
      Colors.lightBlue.shade700, // Tiefschatten
    ];

    // Wir zeichnen in einem Raster für den 8-Bit Look
    for (double y = -r; y < r; y += pixelScale) {
      for (double x = -r; x < r; x += pixelScale) {
        final double dist = sqrt(x * x + y * y);

        if (dist < r) {
          // Berechne Helligkeit basierend auf Abstand zu "Lichtquelle" (oben links: -r, -r)
          // Wir normalisieren den Wert auf 0.0 bis 1.0
          final double lightDist = sqrt(pow(x + r * 0.5, 2) + pow(y + r * 0.5, 2));
          final double brightness = (lightDist / (r * 2.5)).clamp(0.0, 0.99);

          // Wähle Basisfarbe aus Palette
          final int colorIndex = (brightness * palette.length).floor();
          paint.color = palette[colorIndex];

          // Riefen/Streifen zeichnen
          // Die Streifen sind im Schatten dunkler
          if ((y % 8.0).abs() < pixelScale) {
            paint.color = Colors.lightBlue.shade300;
          }

          // Glanzpunkt (noch heller als die Palette)
          if (dist < r * 0.3 && x < -r * 0.2 && y < -r * 0.2) {
            paint.color = Colors.white.withValues(alpha: 0.6);
          }

          // Subtiler "Rim Light" Effekt (heller Rand links oben)
          if (dist > r * 0.85 && x < 0 && y < 0 && dist < r) {
            paint.color = palette[0].withValues(alpha: 0.5);
          }

          canvas.drawRect(
            Rect.fromLTWH(x + r, y + r, pixelScale.toDouble(), pixelScale.toDouble()),
            paint,
          );
        }
      }
    }
  }
}
