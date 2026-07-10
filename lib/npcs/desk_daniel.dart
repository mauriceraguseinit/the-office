import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:the_office/hud/speech_bubble.dart';
import 'package:the_office/models/inventory_item.dart';
import 'package:the_office/trigger_zone.dart';

import '../office_game.dart';

enum DanielDialogs { normalAction, mate, wrongItem }

class DeskDaniel extends SpriteAnimationGroupComponent<String>
    with HasGameReference<OfficeGame>, HoverCallbacks, Interactable {
  DeskDaniel({required super.position, required super.size, this.hitBox = true});

  Map<String, Widget Function(BuildContext, Game)> get _dialogs {
    return <String, Widget Function(BuildContext, Game)>{
      for (final DanielDialogs value in DanielDialogs.values)
        value.toString(): (BuildContext context, Game game) {
          switch (value) {
            case DanielDialogs.normalAction:
              return RetroSpeechBubble(
                text:
                    '[b]Daniel:[/b]\n\nHmm...\n\nIrgendwie habe ich hunger glaube ich. Mal sehen ob ich noch ne Dose Tuhnfisch finde, die ich zu meinem Joghurt essen kann.',
                onClose: () => game.overlays.remove(value.toString()),
              );
            case DanielDialogs.mate:
              return RetroSpeechBubble(
                text: '[b]Daniel:[/b]\n\nIch trinke eigentlich nur Fritz Cola und dann auch nur Zero.',
                onClose: () => game.overlays.remove(value.toString()),
              );
            case DanielDialogs.wrongItem:
              return RetroSpeechBubble(
                text: '[b]Daniel:[/b]\n\nWas soll ich damit?',
                onClose: () => game.overlays.remove(value.toString()),
              );
          }
        },
    };
  }

  final bool hitBox;

  static double pngWidth = 2152;
  static double frame = 4;
  static double pngHeight = 404;
  static double get frameWidth => pngWidth / frame;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    for (String key in _dialogs.keys) {
      game.overlays.addEntry(key, _dialogs[key]!);
    }

    priority = (y + height).toInt();

    final SpriteAnimation anim = await game.loadSpriteAnimation(
      'desk_daniel.png',
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.915, textureSize: Vector2(frameWidth, pngHeight)),
    );

    animations = <String, SpriteAnimation>{'idle': anim};
    current = 'idle';

    if (hitBox) {
      add(RectangleHitbox());
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    final InventoryItem? activeItem = game.selectedItem;

    if (activeItem != null) {
      if (activeItem.id == 'kaffee') {
        debugPrint("Daniel: 'Oh danke! Der Kaffee rettet meinen Tag!'");
        game.ownedItems.remove(activeItem);
      } else if (activeItem.id == 'mate') {
        game.overlays.add(DanielDialogs.mate.toString());
      } else {
        game.overlays.add(DanielDialogs.wrongItem.toString());
      }
      game.resetSelection();
    } else {
      game.overlays.add(DanielDialogs.normalAction.toString());
    }
  }
}
