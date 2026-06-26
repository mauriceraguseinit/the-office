import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:the_office/trigger_zone.dart';

import 'office_game.dart';

enum Direction { left, right, up, down }

class Hendrik extends SpriteAnimationGroupComponent<Direction>
    with KeyboardHandler, HasGameReference<OfficeGame>, CollisionCallbacks {
  // ==========================================
  // ZENTRALE SKALIERUNGS-REGLER
  // ==========================================
  // Ändere NUR diese eine Zahl, um Hendrik insgesamt größer oder kleiner zu machen!
  static const double boxSize = 70.0;

  // Hitbox-Verhältnisse basierend auf deinen funktionierenden 60er-Werten:
  // Breite: 32/60 ≈ 53.3% | Höhe: 40/60 ≈ 66.6%
  // X-Pos:  14/60 ≈ 23.3% | Y-Pos:  18/60 ≈ 30.0%
  static const double _hitboxWidthFactor = 32 / 60;
  static const double _hitboxHeightFactor = 40 / 60;
  static const double _hitboxXFactor = 14 / 60;
  static const double _hitboxYFactor = 18 / 60;
  // ==========================================

  Hendrik({required Vector2 position}) : super(position: position, size: Vector2.all(boxSize));

  final Vector2 _velocity = Vector2.zero();
  final double _speed = 200.0;
  double _currentDt = 0.0;

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
      SpriteAnimationData.sequenced(amount: 7, stepTime: 0.15, textureSize: Vector2(286, 512)),
    );

    final animRight = await game.loadSpriteAnimation(
      'right.png',
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.15, textureSize: Vector2(286, 512)),
    );

    animations = {Direction.down: animDown, Direction.up: animUp, Direction.left: animLeft, Direction.right: animRight};

    anchor = Anchor.center;
    current = Direction.down;

    // --- AUTOMATISCHE HITBOX-SKALIERUNG ---
    // Hier berechnen wir die Werte vollautomatisch über die Faktoren!
    _hitbox = RectangleHitbox(
      size: Vector2(boxSize * _hitboxWidthFactor, boxSize * _hitboxHeightFactor),
      position: Vector2(boxSize * _hitboxXFactor, boxSize * _hitboxYFactor),
    );

    add(_hitbox);
    priority = 11;
  }

  @override
  void render(Canvas canvas) {
    // ==========================================
    // FAKE SCHATTEN ZEICHNEN
    // ==========================================
    final shadowPaint = Paint()
      ..color = const Color(0x66000000)
      ..style = PaintingStyle.fill;

    final double shadowWidth = boxSize * 0.55;
    final double shadowHeight = boxSize * 0.18;

    final double shadowX = (boxSize - shadowWidth) / 2;

    // Standard-Höhe für Hoch/Runter
    double shadowY = boxSize - (shadowHeight * 1.2);

    if (current == Direction.left || current == Direction.right) {
      // Wir vergrößern den Abzug (z.B. von 0.7 auf 1.5),
      // um den Schatten auf der Y-Achse weiter nach oben (höher) zu schieben.
      shadowY = boxSize - (shadowHeight * 1.2);
    }

    canvas.drawOval(Rect.fromLTWH(shadowX, shadowY, shadowWidth, shadowHeight), shadowPaint);
    // ==========================================
    // ==========================================
    // ==========================================

    // Ab hier folgt dein ganz normaler, bestehender AnimationCode...
    final ticker = animationTicker;
    if (ticker != null) {
      final sprite = ticker.getSprite();

      final double spriteWidth = sprite.srcSize.x;
      final double spriteHeight = sprite.srcSize.y;
      final double aspectRatio = spriteWidth / spriteHeight;

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
        // Wir ziehen einen kleinen Prozentsatz ab (z.B. 8% der Box-Größe),
        // um das Sprite beim Seitwärtslaufen ein Stück nach oben (höher) zu schieben.
        offsetY -= (boxSize * 0.08);
      }

      sprite.render(canvas, position: Vector2(offsetX, offsetY), size: Vector2(renderWidth, renderHeight));
    } else {
      super.render(canvas);
    }
  }

  @override
  void update(double dt) {
    _currentDt = dt;

    if (_velocity.length > 0) {
      super.update(dt);
      position += _velocity * _speed * dt;
    } else {
      super.update(0);
    }
  }

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

    if (event is KeyDownEvent && keysPressed.contains(LogicalKeyboardKey.space)) {
      game.toggleScreenLock();
      return true;
    }

    return false;
  }
}
