import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

/// Der Schreibtisch (Desk)
class DeskComponent extends SpriteComponent {
  DeskComponent({required super.position, required super.size});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    sprite = await Sprite.load('desk.png');
    final original = sprite!.srcSize;
    size = Vector2(original.x * 0.5, original.y * 0.5);

    add(RectangleHitbox());
  }
}
