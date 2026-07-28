import 'dart:async';
import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart' show Curves, Colors, FontWeight;
import 'package:flutter/services.dart';
import 'package:the_office/utils/assets.dart';
import 'package:the_office/utils/config.dart';
import 'package:the_office/utils/styles.dart';

enum FighterState {
  idle,
  walking,
  jumping,
  crouching,
  punching,
  kicking,
}

class BeatEmUpGame extends FlameGame<World> with HasKeyboardHandlerComponents<World> {
  late Fighter player;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Setup Fixed Resolution Viewport
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(GameConfig.resolution.width, GameConfig.resolution.height),
    );
    camera.viewfinder.anchor = Anchor.topLeft;

    // Background
    world.add(
      SpriteComponent(
        sprite: await loadSprite(GameImages.beatEmUpBg),
        size: Vector2(GameConfig.resolution.width, GameConfig.resolution.height),
      ),
    );


    player = Fighter(
      position: Vector2(200, GameConfig.resolution.height - 20), // Anchor is bottomCenter
    );
    world.add(player);

    // --- UI ELEMENTS ---
    camera.viewport.add(HealthBar(position: Vector2(40, 40)));
    camera.viewport.add(HealthBar(position: Vector2(GameConfig.resolution.width - 40, 40), flipped: true));
    
    // Intro Sequence
    camera.viewport.add(FightIntro(onComplete: () => player.isLocked = false));
  }
}

class Fighter extends SpriteAnimationGroupComponent<FighterState>
    with KeyboardHandler, HasGameReference<BeatEmUpGame> {
  Fighter({required super.position}) : super(size: Vector2(120, 180));

  final double _speed = 250.0;
  final double _gravity = 800.0;
  final double _jumpForce = -450.0;

  final Vector2 _velocity = Vector2.zero();
  bool _isGrounded = true;
  bool isLocked = true; // Initially locked for intro
  
  double _attackTimer = 0;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final SpriteAnimation tempAnim = await game.loadSpriteAnimation(
      GameImages.playerRight,
      SpriteAnimationData.sequenced(
        amount: 7,
        stepTime: 0.1,
        textureSize: Vector2(286, 512),
      ),
    );

    animations = <FighterState, SpriteAnimation>{
      FighterState.idle: tempAnim,
      FighterState.walking: tempAnim,
      FighterState.jumping: tempAnim,
      FighterState.crouching: tempAnim,
      FighterState.punching: tempAnim,
      FighterState.kicking: tempAnim,
    };

    current = FighterState.idle;
    anchor = Anchor.bottomCenter;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isLocked) {
      _velocity.x = 0;
    }

    // Apply Gravity
    if (!_isGrounded) {
      _velocity.y += _gravity * dt;
    }

    // Move
    position += _velocity * dt;

    // Screen boundaries
    if (position.x < 60) position.x = 60;
    if (position.x > GameConfig.resolution.width - 60) position.x = GameConfig.resolution.width - 60;

    // Floor collision (Simple)
    final double groundY = GameConfig.resolution.height - 20;
    if (position.y >= groundY) {
      position.y = groundY;
      _velocity.y = 0;
      _isGrounded = true;
      if (current == FighterState.jumping) {
        current = FighterState.idle;
      }
    }

    // Attack timer (Reset state after attack)
    if (_attackTimer > 0) {
      _attackTimer -= dt;
      if (_attackTimer <= 0) {
        if (current == FighterState.punching || current == FighterState.kicking) {
          current = _isGrounded ? FighterState.idle : FighterState.jumping;
        }
      }
    }

    // Update state based on velocity
    if (_isGrounded && _attackTimer <= 0) {
      if (_velocity.x.abs() > 0) {
        current = FighterState.walking;
      } else if (current != FighterState.crouching) {
        current = FighterState.idle;
      }
    }
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (isLocked) return false;

    // Reset horizontal velocity
    _velocity.x = 0;

    if (keysPressed.contains(LogicalKeyboardKey.keyA)) {
      _velocity.x = -_speed;
    } else if (keysPressed.contains(LogicalKeyboardKey.keyD)) {
      _velocity.x = _speed;
    }

    // Crouching
    if (keysPressed.contains(LogicalKeyboardKey.keyS)) {
      if (_isGrounded) {
        current = FighterState.crouching;
        _velocity.x = 0; 
      }
    } else if (current == FighterState.crouching) {
      current = FighterState.idle;
    }

    // Jumping
    if (keysPressed.contains(LogicalKeyboardKey.keyW)) {
      if (_isGrounded) {
        _velocity.y = _jumpForce;
        _isGrounded = false;
        current = FighterState.jumping;
      }
    }

    // Punching (E)
    if (keysPressed.contains(LogicalKeyboardKey.keyE)) {
      if (_attackTimer <= 0) {
        current = FighterState.punching;
        _attackTimer = 0.3; 
      }
    }

    // Kicking (F)
    if (keysPressed.contains(LogicalKeyboardKey.keyF)) {
      if (_attackTimer <= 0) {
        current = FighterState.kicking;
        _attackTimer = 0.4; 
      }
    }

    return super.onKeyEvent(event, keysPressed);
  }
}

class HealthBar extends PositionComponent {
  HealthBar({required super.position, this.flipped = false}) : super(size: Vector2(400, 40));

  final bool flipped;

  @override
  void render(Canvas canvas) {
    // Outer Border
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 4,
    );

    // Inner Background (Red/Empty)
    canvas.drawRect(
      Rect.fromLTWH(2, 2, size.x - 4, size.y - 4),
      Paint()..color = Colors.red,
    );

    // Life (Yellow/Full)
    const double healthPercent = 1.0;
    final double barWidth = (size.x - 4) * healthPercent;
    
    final double xOffset = flipped ? size.x - 4 - barWidth : 2;

    canvas.drawRect(
      Rect.fromLTWH(xOffset, 2, barWidth, size.y - 4),
      Paint()..color = Colors.yellow,
    );
  }

  @override
  void onMount() {
    super.onMount();
    if (flipped) anchor = Anchor.topRight;
  }
}

class FightIntro extends PositionComponent with HasGameReference<BeatEmUpGame> {
  FightIntro({required this.onComplete});
  final VoidCallback onComplete;

  late TextComponent<TextRenderer> roundText;
  late TextComponent<TextRenderer> fightText;

  @override
  Future<void> onLoad() async {
    roundText = TextComponent<TextRenderer>(
      text: 'ROUND 1',
      textRenderer: TextPaint(
        style: GameStyles.statusStyle.copyWith(fontSize: 80, color: Colors.white),
      ),
      anchor: Anchor.center,
      position: Vector2(GameConfig.resolution.width / 2, GameConfig.resolution.height / 2),
      scale: Vector2.all(0),
    );

    fightText = TextComponent<TextRenderer>(
      text: 'FIGHT!',
      textRenderer: TextPaint(
        style: GameStyles.statusStyle.copyWith(fontSize: 120, color: Colors.red, fontWeight: FontWeight.w900),
      ),
      anchor: Anchor.center,
      position: Vector2(GameConfig.resolution.width / 2, GameConfig.resolution.height / 2),
      scale: Vector2.all(0),
    );

    add(roundText);
    add(fightText);

    // Animation Sequence
    roundText.add(
      SequenceEffect(<Effect>[
        ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.5, curve: Curves.easeOutBack)),
        ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 1.0)), // Hold
        ScaleEffect.to(Vector2.all(0.0), EffectController(duration: 0.3, curve: Curves.easeInCirc)),
        RemoveEffect(),
      ]),
    );

    await Future<void>.delayed(const Duration(milliseconds: 2000));

    fightText.add(
      SequenceEffect(<Effect>[
        ScaleEffect.to(Vector2.all(1.2), EffectController(duration: 0.2, curve: Curves.elasticOut)),
        ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.8)), // Hold
        OpacityEffect.to(0.0, EffectController(duration: 0.5)),
        RemoveEffect(),
      ], onComplete: () {
        onComplete();
        removeFromParent();
      }),
    );
  }
}
