import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import 'main.dart';

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

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // Prüfen, ob das andere Objekt eine Wand ist
    if (other.children.any((component) => component is RectangleHitbox)) {
      // Hier stoppst du die Bewegung des Spielers
      // Beispiel: Position auf den vorherigen Frame zurücksetzen
      position -= _velocity * _speed * _currentDt;
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Wir definieren die gewünschte Ziel-Höhe des Spielers im Spiel (ca. 50% größer als vorher)
    const double targetHeight = 75.0;

    // 1. DOWN Animation (Original Frame: 206 x 229)
    // Wir berechnen die perfekte Breite: (206 / 229) * 75 = ca. 67.4
    const double widthDown = (206 / 229) * targetHeight;
    final animDown = await game.loadSpriteAnimation(
      'down.png',
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.15, textureSize: Vector2(206, 229)),
    );

    // 2. UP Animation (Original Frame: 190 x 256)
    // Perfekte Breite: (190 / 256) * 75 = ca. 55.6
    final animUp = await game.loadSpriteAnimation(
      'up.png',
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.15, textureSize: Vector2(190, 256)),
    );

    // 3. LEFT Animation (Original Frame: 139 x 261)
    // Perfekte Breite: (139 / 261) * 75 = ca. 39.9
    final animLeft = await game.loadSpriteAnimation(
      'left.png',
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.15, textureSize: Vector2(139, 261)),
    );

    // 4. RIGHT Animation (Identisch zu Left)
    final animRight = await game.loadSpriteAnimation(
      'right.png',
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.15, textureSize: Vector2(139, 261)),
    );

    // Jetzt übergeben wir die Animationen an die Komponente
    animations = {Direction.down: animDown, Direction.up: animUp, Direction.left: animLeft, Direction.right: animRight};

    // WICHTIG: Wir setzen die Standard-Größe beim Start auf die Down-Maße
    size = Vector2(widthDown, targetHeight);
    current = Direction.down;
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    const double targetHeight = 75.0;
    _currentDt = dt;

    // Wir passen die hitbox/Größe des Players dynamisch an die aktuelle Richtung an
    if (current == Direction.down) {
      size = Vector2((206 / 229) * targetHeight, targetHeight);
    } else if (current == Direction.up) {
      size = Vector2((190 / 256) * targetHeight, targetHeight);
    } else if (current == Direction.left || current == Direction.right) {
      size = Vector2((139 / 261) * targetHeight, targetHeight);
    }

    if (_velocity.length > 0) {
      super.update(dt);
      position += _velocity * _speed * dt;
    } else {
      super.update(0);
    }
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // Bewegung zurücksetzen
    _velocity.setZero();

    // Tasten abfragen und den 'current'-Zustand der Komponente ändern
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
    }

    return false;
  }
}
