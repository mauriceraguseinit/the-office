import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:the_office/hud/speech_bubble.dart';
import 'package:the_office/models/inventory_item.dart';
import 'package:the_office/trigger_zone.dart';

import '../office_game.dart';

enum TobiDialogs { normalAction, thanks, wrongItem, noMate }

class Tobi extends SpriteAnimationGroupComponent<String>
    with HasGameReference<OfficeGame>, HoverCallbacks, Interactable {
  Tobi({required super.position, required super.size, this.hitBox = true});

  Map<String, Widget Function(BuildContext, Game)> get _dialogs {
    return <String, Widget Function(BuildContext, Game)>{
      for (final TobiDialogs value in TobiDialogs.values)
        value.toString(): (_, _) {
          switch (value) {
            case TobiDialogs.normalAction:
              return RetroSpeechBubble(
                text: '[b]Tobias:[/b]\n\nNerv mich nicht. Ich bereite gerade meinen nächsten Zahnarzttermin vor.',
                onClose: () => game.overlays.remove(value.toString()),
              );
            case TobiDialogs.wrongItem:
              return RetroSpeechBubble(
                text: '[b]Tobias:[/b]\n\nWas soll ich damit?',
                onClose: () => game.overlays.remove(value.toString()),
              );
            case TobiDialogs.noMate:
              return RetroSpeechBubble(
                text:
                    '[b]Tobias:[/b]\n\nIch trinke seit 345,3 Tagen keine Mate mehr und gehe regelmäßig zu den Treffen der anonymen Mateholiker.\n\nLass mich in Ruhe!',
                onClose: () => game.overlays.remove(value.toString()),
              );
            case TobiDialogs.thanks:
              return RetroSpeechBubble(
                text: '[b]Tobias:[/b]\n\nDanke',
                onClose: () => game.overlays.remove(value.toString()),
              );
          }
        },
    };
  }

  final bool hitBox;
  static double pngWidth = 1488;
  static double frame = 4;
  static double pngHeight = 495;
  static double get frameWidth => pngWidth / frame;

  @override
  void render(Canvas canvas) {
    // Fake-Schatten unter dem NPC zeichnen
    final Paint shadowPaint = Paint()
      ..color = const Color(0x66000000)
      ..style = PaintingStyle.fill;

    final double shadowWidth = 40;
    final double shadowHeight = 14;
    final double shadowX = 4;
    final double shadowY = 56;

    canvas.drawOval(Rect.fromLTWH(shadowX, shadowY, shadowWidth, shadowHeight), shadowPaint);

    super.render(canvas);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    for (String key in _dialogs.keys) {
      game.overlays.addEntry(key, _dialogs[key]!);
    }

    priority = (y + height).toInt();

    final SpriteAnimation anim = await game.loadSpriteAnimation(
      'tobi_idle.png',
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.15, textureSize: Vector2(frameWidth, pngHeight)),
    );
    animations = <String, SpriteAnimation>{'idle': anim};
    current = 'idle';

    if (hitBox) {
      add(RectangleHitbox(size: Vector2(Tobi.frameWidth * 0.13, (Tobi.pngHeight * 0.13) / 2)));
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    final InventoryItem? activeItem = game.selectedItem;

    if (activeItem != null) {
      if (activeItem.id == 'kaffee') {
        debugPrint("Tobi: 'Oh danke! Der Kaffee rettet meinen Tag!'");
        game.ownedItems.remove(activeItem);
      } else if (activeItem.id == 'mate') {
        game.overlays.add(TobiDialogs.noMate.toString());
      } else {
        game.overlays.add(TobiDialogs.wrongItem.toString());
      }
      game.resetSelection();
    } else {
      game.overlays.add(TobiDialogs.normalAction.toString());
    }
  }
}
