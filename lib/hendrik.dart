import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:the_office/trigger_zone.dart';

import 'office_game.dart';

enum Direction { left, right, up, down }

/// Der Spieler (Flutter-Entwickler) mit Tastatur-Steuerung
/// Der Spieler mit echten Lauf-Animationen
/// Der Spieler (Flutter-Entwickler) nutzt jetzt Flame's fertige SpriteAnimationGroupComponent.
/// Das ist der sauberste Weg für Richtungs-Animationen!
/// Der Spieler (Flutter-Entwickler) nutzt jetzt Flame's fertige SpriteAnimationGroupComponent.
class Hendrik extends SpriteAnimationGroupComponent<Direction>
    with KeyboardHandler, HasGameReference<OfficeGame>, CollisionCallbacks {
  Hendrik({required super.position, required super.size});

  final Vector2 _velocity = Vector2.zero();
  final double _speed = 200.0;
  double _currentDt = 0.0;

  // Referenz auf die Hitbox, damit wir sie später anpassen können
  late RectangleHitbox _hitbox;

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    final hitboxes = other.children.whereType<ShapeHitbox>();
    final hasActiveCollision = hitboxes.any((hitbox) => hitbox.collisionType == CollisionType.active);

    if (hasActiveCollision) {
      position -= _velocity * _speed * _currentDt;
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Ziel-Höhe des Spielers
    const double targetHeight = 60.0;

    // Animationen laden (wie gehabt)
    const double widthDown = (206 / 229) * targetHeight;
    final animDown = await game.loadSpriteAnimation(
      'down.png',
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.15, textureSize: Vector2(206, 229)),
    );

    final animUp = await game.loadSpriteAnimation(
      'up.png',
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.15, textureSize: Vector2(190, 256)),
    );

    final animLeft = await game.loadSpriteAnimation(
      'left.png',
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.15, textureSize: Vector2(139, 261)),
    );

    final animRight = await game.loadSpriteAnimation(
      'right.png',
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.15, textureSize: Vector2(139, 261)),
    );

    // Animationen zuweisen
    animations = {Direction.down: animDown, Direction.up: animUp, Direction.left: animLeft, Direction.right: animRight};

    // Standard-Größe setzen
    size = Vector2(widthDown, targetHeight);
    current = Direction.down;

    // --- HITBOX ANPASSEN ---
    // Wir erstellen eine Hitbox, die nur 50% der Höhe hat.
    // Die Position ist relativ zur oberen linken Ecke des Spielers.
    // Ein y-Offset von targetHeight / 2 verschiebt die Hitbox nach unten.
    _hitbox = RectangleHitbox(size: Vector2(widthDown, targetHeight), position: Vector2(0, 0));
    add(_hitbox);
    priority = 11;
  }

  @override
  void update(double dt) {
    const double targetHeight = 60.0;
    _currentDt = dt;

    // Wir passen die Größe des Players und der Hitbox dynamisch an
    if (current == Direction.down) {
      double width = (206 / 229) * targetHeight;
      size = Vector2(width, targetHeight);
      _hitbox.size.x = width; // Breite der Hitbox anpassen
    } else if (current == Direction.up) {
      double width = (190 / 256) * targetHeight;
      size = Vector2(width, targetHeight);
      _hitbox.size.x = width; // Breite der Hitbox anpassen
    } else if (current == Direction.left || current == Direction.right) {
      double width = (139 / 261) * targetHeight;
      size = Vector2(width, targetHeight);
      _hitbox.size.x = width; // Breite der Hitbox anpassen
    }

    if (_velocity.length > 0) {
      super.update(dt);
      position += _velocity * _speed * dt;
    } else {
      super.update(0);
    }
  }

  // In hendrik.dart:
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (game.overlays.activeOverlays.isNotEmpty) {
      _velocity.setZero();
      return false;
    }

    if (event is KeyDownEvent && keysPressed.contains(LogicalKeyboardKey.keyE)) {
      final zones = game.world.children.whereType<TriggerZone>();
      for (final zone in zones) {
        if (zone.checkInteraction(this)) {
          return false;
        }
      }
    }

    _velocity.setZero();

    if (keysPressed.contains(LogicalKeyboardKey.keyI)) {
      game.overlays.add('inventory');
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyW) || keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      _velocity.y = -1;
      current = Direction.up;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyS) || keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      _velocity.y = 1;
      current = Direction.down;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyA) || keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      _velocity.x = -1;
      current = Direction.left;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyD) || keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      _velocity.x = 1;
      current = Direction.right;
    }

    if (_velocity.length > 0) {
      _velocity.normalize();
    }

    // PC sperren mit Leertaste
    if (event is KeyDownEvent && keysPressed.contains(LogicalKeyboardKey.space)) {
      game.toggleScreenLock();
      return true;
    }

    return false;
  }
}
