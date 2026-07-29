import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

class ItemFlyComponent extends SpriteComponent {
  ItemFlyComponent({
    required super.sprite,
    required super.position,
    required this.targetPosition,
    required super.size,
    this.onReached,
  }) : super(anchor: Anchor.center, priority: 999999);

  final Vector2 targetPosition;
  final void Function()? onReached;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 1. Der Flugbogen
    add(
      MoveEffect.to(
        targetPosition,
        CurvedEffectController(0.8, Curves.easeInOutCubic),
        onComplete: () {
          onReached?.call();
          removeFromParent();
        },
      ),
    );

    // 2. Skalierung
    add(
      ScaleEffect.to(
        Vector2.all(0.3),
        CurvedEffectController(0.8, Curves.easeInQuad),
      ),
    );

    // 3. Rotation
    add(
      RotateEffect.by(
        6.28,
        CurvedEffectController(0.8, Curves.linear),
      ),
    );

    // 4. Fade Out
    add(
      OpacityEffect.to(
        0.0,
        EffectController(duration: 0.2, startDelay: 0.6),
      ),
    );
  }
}
