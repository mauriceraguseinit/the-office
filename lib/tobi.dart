import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'main.dart';

class Tobi extends SpriteAnimationGroupComponent with HasGameReference<OfficeGame> {
  Tobi({required super.position, required super.size, this.hitBox = true});

  final bool hitBox;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    priority = 10;
    final anim = await game.loadSpriteAnimation(
      'tobi_idle.png',
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.15, textureSize: Vector2(1488 / 4, 495)),
    );

    // Jetzt übergeben wir die Animationen an die Komponente
    animations = {'idle': anim};
    current = 'idle';

    if (hitBox) {
      add(RectangleHitbox());
    }
  }
}
