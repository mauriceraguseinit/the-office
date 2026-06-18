import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import 'main.dart';

class DeskDaniel extends SpriteAnimationGroupComponent with HasGameReference<OfficeGame> {
  DeskDaniel({required super.position, required super.size, this.hitBox = true});

  final bool hitBox;

  static double pngWidth = 2152;
  static double frame = 4;
  static double pngHeight = 404;
  static double get frameWidth => pngWidth / frame;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    priority = 10;
    final anim = await game.loadSpriteAnimation(
      'desk_daniel.png',
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.915, textureSize: Vector2(frameWidth, pngHeight)),
    );

    // Jetzt übergeben wir die Animationen an die Komponente
    animations = {'idle': anim};
    current = 'idle';

    if (hitBox) {
      add(RectangleHitbox());
    }
  }
}
