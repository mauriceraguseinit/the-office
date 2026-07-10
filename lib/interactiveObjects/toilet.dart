import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:the_office/hud/speech_bubble.dart';
import 'package:the_office/models/inventory_item.dart';
import 'package:the_office/trigger_zone.dart';

import '../../office_game.dart';

enum ToiletDialogs { normalAction, thanks, wrongItem, noMate }

class Toilet extends SpriteComponent with HasGameReference<OfficeGame>, HoverCallbacks, Interactable {
  Toilet({required super.position, super.size, this.hitBox = true});

  Map<String, Widget Function(BuildContext, Game)> get _dialogs {
    return <String, Widget Function(BuildContext, Game)>{
      for (final ToiletDialogs value in ToiletDialogs.values)
        value.toString(): (BuildContext context, Game game) {
          switch (value) {
            case ToiletDialogs.normalAction:
              return RetroSpeechBubble(
                text: '[b]Toilette:[/b]\n\nBesetzt!',
                onClose: () => game.overlays.remove(value.toString()),
              );
            case ToiletDialogs.wrongItem:
              return RetroSpeechBubble(
                text: '[b]Toilette:[/b]\n\nDas gehört hier nicht rein.',
                onClose: () => game.overlays.remove(value.toString()),
              );
            case ToiletDialogs.noMate:
              return RetroSpeechBubble(
                text: '[b]Toilette:[/b]\n\nGluckert protestierend.',
                onClose: () => game.overlays.remove(value.toString()),
              );
            case ToiletDialogs.thanks:
              return RetroSpeechBubble(
                text: '[b]Toilette:[/b]\n\nSpült dankbar.',
                onClose: () => game.overlays.remove(value.toString()),
              );
          }
        },
    };
  }

  final bool hitBox;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    for (String key in _dialogs.keys) {
      game.overlays.addEntry(key, _dialogs[key]!);
    }

    priority = (y + height / 2).toInt();
    debugMode = false;
    anchor = Anchor.centerRight;

    sprite = await game.loadSprite('toilet.png');

    if (hitBox) {
      add(RectangleHitbox(size: Vector2(size.x, (size.y) / 2)));
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    final InventoryItem? activeItem = game.selectedItem;

    if (activeItem != null) {
      if (activeItem.id == 'kaffee') {
        game.ownedItems.remove(activeItem);
        game.overlays.add(ToiletDialogs.thanks.toString());
      } else if (activeItem.id == 'mate') {
        game.overlays.add(ToiletDialogs.noMate.toString());
      } else {
        game.overlays.add(ToiletDialogs.wrongItem.toString());
      }
      game.resetSelection();
    } else {
      game.overlays.add(ToiletDialogs.normalAction.toString());
    }
  }
}
