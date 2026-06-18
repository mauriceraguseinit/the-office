import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import 'hendrik.dart';

class TriggerZone extends PositionComponent with CollisionCallbacks {
  final PositionComponent target;
  final double padding;
  final VoidCallback onAction;

  bool _playerInside = false;

  TriggerZone({required this.target, required this.onAction, this.padding = 35.0});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final isRotated = target.angle == 1.5707963267948966 || target.angle == 4.71238898038469;

    if (isRotated) {
      size = Vector2(target.size.y, target.size.x) + Vector2(padding * 2, padding * 2);
    } else {
      size = target.size + Vector2(padding * 2, padding * 2);
    }

    anchor = Anchor.center;
    position = target.absoluteCenter;

    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Hendrik) {
      _playerInside = true;
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is Hendrik) {
      _playerInside = false;
    }
  }

  /// Der Clou: Wenn Hendrik 'E' drückt, verpassen wir der Abfrage ein Sicherheitsnetz.
  bool checkInteraction(Hendrik player) {
    // 1. Check: Erkennt Flame die Kollision ganz normal?
    if (_playerInside) return _executeAction();

    // 2. Sicherheitsnetz: Wenn der Spieler die innere Box rammt,
    // messen wir einfach den direkten Abstand zwischen den Mittelpunkten.
    final distance = (player.absoluteCenter - target.absoluteCenter).length;

    // Wir berechnen die maximale Reichweite (halbe Diagonale der Trigger-Zone)
    final maxAllowedDistance = size.length / 2;

    if (distance <= maxAllowedDistance) {
      return _executeAction();
    }

    return false;
  }

  bool _executeAction() {
    onAction();
    return true;
  }
}
