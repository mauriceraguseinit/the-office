import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart';

import 'office_game.dart';

enum Direction { left, right, up, down }

class Hendrik extends SpriteAnimationGroupComponent<Direction>
    with KeyboardHandler, HasGameReference<OfficeGame>, CollisionCallbacks, HoverCallbacks {
  Hendrik({required Vector2 position}) : super(position: position, size: Vector2.all(boxSize));

  static const double boxSize = 70.0;
  bool _isHighlighted = false;
  static const double _hitboxWidthFactor = 32 / 60;
  static const double _hitboxHeightFactor = 0.5;
  static const double _hitboxXFactor = 14 / 60;
  static const double _hitboxYFactor = 0.5;

  final Vector2 _velocity = Vector2.zero();
  final double _speed = 200.0;
  double _currentDt = 0.0;

  late RectangleHitbox _hitbox;

  /// Stoppt die Touch-Bewegung beim Loslassen des Bildschirms
  void stopTouchMovement() {
    _velocity.setZero();
  }

  void setHighlighted(bool highlighted) {
    _isHighlighted = highlighted;
  }

  @override
  void lookAt(Vector2 target) {
    final Vector2 direction = target - absoluteCenter;

    if (direction.length2 == 0) {
      return;
    }

    if (direction.x.abs() > direction.y.abs()) {
      current = direction.x > 0 ? Direction.right : Direction.left;
    } else {
      current = direction.y > 0 ? Direction.down : Direction.up;
    }
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    // Interaktionsfläche: absichtlich größer als die Collision-Hitbox.
    // So lassen sich Hendrik, Hover und Item-Anwendung zuverlässig treffen.
    const double interactionPadding = 0.0;

    return point.x >= -interactionPadding &&
        point.x <= size.x + interactionPadding &&
        point.y >= -interactionPadding &&
        point.y <= size.y + interactionPadding;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    final Iterable<ShapeHitbox> hitboxes = other.children.whereType<ShapeHitbox>();
    final bool hasActiveCollision = hitboxes.any(
      (ShapeHitbox hitbox) => hitbox.collisionType == CollisionType.active,
    );

    if (hasActiveCollision) {
      // Schiebe Hendrik ein Stück zurück, um nicht im Objekt stecken zu bleiben
      position -= _velocity * _speed * _currentDt;
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final SpriteAnimation animDown = await game.loadSpriteAnimation(
      'down.png',
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.15, textureSize: Vector2(206, 229)),
    );

    final SpriteAnimation animUp = await game.loadSpriteAnimation(
      'up.png',
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.15, textureSize: Vector2(190, 256)),
    );

    final SpriteAnimation animLeft = await game.loadSpriteAnimation(
      'left.png',
      SpriteAnimationData.sequenced(amount: 7, stepTime: 0.15, textureSize: Vector2(286, 512)),
    );

    final SpriteAnimation animRight = await game.loadSpriteAnimation(
      'right.png',
      SpriteAnimationData.sequenced(amount: 7, stepTime: 0.15, textureSize: Vector2(286, 512)),
    );

    animations = <Direction, SpriteAnimation>{
      Direction.down: animDown,
      Direction.up: animUp,
      Direction.left: animLeft,
      Direction.right: animRight,
    };

    anchor = Anchor.center;
    current = Direction.down;

    _hitbox = RectangleHitbox(
      size: Vector2(boxSize * _hitboxWidthFactor, boxSize * _hitboxHeightFactor),
      position: Vector2(boxSize * _hitboxXFactor, boxSize * _hitboxYFactor),
    )..debugMode = false;

    add(_hitbox);
  }

  @override
  void render(Canvas canvas) {
    final Paint shadowPaint = Paint()
      ..color = const Color(0x66000000)
      ..style = PaintingStyle.fill;

    final double shadowWidth = boxSize * 0.55;
    final double shadowHeight = boxSize * 0.18;
    final double shadowX = (boxSize - shadowWidth) / 2;
    final double shadowY = boxSize - (shadowHeight * 1.2);

    canvas.drawOval(Rect.fromLTWH(shadowX, shadowY, shadowWidth, shadowHeight), shadowPaint);

    final SpriteAnimationTicker? ticker = animationTicker;
    if (ticker != null) {
      final Sprite sprite = ticker.getSprite();
      final double aspectRatio = sprite.srcSize.x / sprite.srcSize.y;

      double renderWidth = boxSize;
      double renderHeight = boxSize;

      if (aspectRatio > 1.0) {
        renderHeight = boxSize / aspectRatio;
      } else {
        renderWidth = boxSize * aspectRatio;
      }

      if (current == Direction.up || current == Direction.down) {
        const double scaleFactor = 0.8;
        renderWidth *= scaleFactor;
        renderHeight *= scaleFactor;
      }

      final double offsetX = (boxSize - renderWidth) / 2;
      double offsetY = (boxSize - renderHeight) / 2;

      if (current == Direction.left || current == Direction.right) {
        offsetY -= (boxSize * 0.08);
      }

      if (_isHighlighted) {
        final Paint outlinePaint = Paint()
          ..colorFilter = const ColorFilter.mode(
            Color(0xFFFFFFAA),
            BlendMode.srcIn,
          );

        const List<Offset> offsets = <Offset>[
          Offset(-1, 0),
          Offset(1, 0),
          Offset(0, -1),
          Offset(0, 1),
        ];

        for (final Offset offset in offsets) {
          sprite.render(
            canvas,
            position: Vector2(offsetX + offset.dx, offsetY + offset.dy),
            size: Vector2(renderWidth, renderHeight),
            overridePaint: outlinePaint,
          );
        }
      }

      sprite.render(
        canvas,
        position: Vector2(offsetX, offsetY),
        size: Vector2(renderWidth, renderHeight),
      );
    } else {
      super.render(canvas);
    }
  }

  /// Setzt die Geschwindigkeit direkt anhand des Richtungsvektors vom Bildschirm-Zentrum
  void updateTouchVelocity(Vector2 screenDirection) {
    // Deadzone (in physikalischen Pixeln): Wenn man sehr nah an der Mitte drückt, stoppt er
    if (screenDirection.length > 30.0) {
      _velocity.setFrom(screenDirection);
      _velocity.normalize(); // Macht die diagonale Bewegung genauso schnell wie die gerade

      // Blickrichtung basierend auf der dominierenden Achse setzen
      if (_velocity.x.abs() > _velocity.y.abs()) {
        current = _velocity.x > 0 ? Direction.right : Direction.left;
      } else {
        current = _velocity.y > 0 ? Direction.down : Direction.up;
      }
    } else {
      _velocity.setZero();
    }
  }

  /// Stoppt die Touch-Bewegung beim Loslassen des Bildschirms

  @override
  void update(double dt) {
    _currentDt = dt;

    // HINWEIS: Sämtlicher alter TouchTarget-Code wurde entfernt!
    // Die Velocity wird jetzt rein über updateTouchVelocity von außen gesteuert.

    // --- BEWEGUNG AUSFÜHREN ---
    if (_velocity.length > 0) {
      super.update(dt);
      position += _velocity * _speed * dt;
    } else {
      super.update(0); // Animation im Stand einfrieren
    }

    priority = (y + height / 2).toInt(); // Dynamisches Y-Sorting
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (game.overlays.activeOverlays.isNotEmpty) {
      _velocity.setZero();
      return false;
    }

    if (event is KeyDownEvent && keysPressed.contains(LogicalKeyboardKey.keyE)) {
      _velocity.setZero();
      game.tryInteractWithNearestObject();
      return false;
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

    if (event is KeyDownEvent && keysPressed.contains(LogicalKeyboardKey.space)) {
      game.toggleScreenLock();
      return true;
    }

    return false;
  }

  @override
  void onHoverEnter() {
    if (!game.isTouchDevice) {
      game.setPlayerHighlighted(true);
    }
  }

  @override
  void onHoverExit() {
    if (!game.isTouchDevice) {
      game.setPlayerHighlighted(false);
    }
  }
}
