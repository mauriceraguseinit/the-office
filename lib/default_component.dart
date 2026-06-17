import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

enum WallElement { wall, window, door }

class DefaultComponent extends SpriteComponent {
  DefaultComponent({
    required super.position,
    required super.size,
    this.hitBox = true,
    this.wallElement = WallElement.wall,
  });

  final bool hitBox;
  final WallElement wallElement;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    sprite = await Sprite.load(switch (wallElement) {
      WallElement.wall => 'wall.png',
      WallElement.window => 'window.png',
      WallElement.door => 'door.png',
    });
    final original = sprite!.srcSize;
    size = Vector2(original.x * 1, original.y * 1);
    if (hitBox) {
      add(RectangleHitbox());
    }
  }
}
