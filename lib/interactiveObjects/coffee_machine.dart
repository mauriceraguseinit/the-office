import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:the_office/hud/speech_bubble.dart';
import 'package:the_office/models/inventory_item.dart';
import 'package:the_office/trigger_zone.dart';

import '../../office_game.dart';

enum CoffeeMachineDialogs { normalAction, thanks, wrongItem, noMate }

class CoffeeMachine extends SpriteComponent with HasGameReference<OfficeGame>, HoverCallbacks, Interactable {
  CoffeeMachine({
    required super.position,
    super.size,
    this.hitBox = true,
    this.priorityOffset = 0,
  });
  final bool hitBox;
  final int priorityOffset;

  Map<String, Widget Function(BuildContext, Game)> get _dialogs {
    return <String, Widget Function(BuildContext, Game)>{
      for (final CoffeeMachineDialogs value in CoffeeMachineDialogs.values)
        value.toString(): (BuildContext context, Game game) {
          switch (value) {
            case CoffeeMachineDialogs.normalAction:
              return RetroSpeechBubble(
                text: '[b]Kaffeemaschine:[/b]\n\nDefekt!',
                onClose: () => game.overlays.remove(value.toString()),
              );
            case CoffeeMachineDialogs.wrongItem:
              return RetroSpeechBubble(
                text: '[b]Kaffeemaschine:[/b]\n\nDas gehört hier nicht rein.',
                onClose: () => game.overlays.remove(value.toString()),
              );
            case CoffeeMachineDialogs.noMate:
              return RetroSpeechBubble(
                text: '[b]Kaffeemaschine:[/b]\n\nGluckert protestierend.',
                onClose: () => game.overlays.remove(value.toString()),
              );
            case CoffeeMachineDialogs.thanks:
              return RetroSpeechBubble(
                text: '[b]Kaffeemaschine:[/b]\n\nSpült dankbar.',
                onClose: () => game.overlays.remove(value.toString()),
              );
          }
        },
    };
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    for (String key in _dialogs.keys) {
      game.overlays.addEntry(key, _dialogs[key]!);
    }

    // Y-Sorting + Layer-Offset zusammenrechnen
    priority = (y + height / 2).toInt() + priorityOffset;

    debugMode = false;
    anchor = Anchor.centerRight;

    sprite = await game.loadSprite('coffeyMaschine.png');

    if (hitBox) {
      add(RectangleHitbox(size: Vector2(size.x, size.y / 2)));
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    final InventoryItem? activeItem = game.selectedItem;

    if (activeItem != null) {
      if (activeItem.id == 'kaffee') {
        game.ownedItems.remove(activeItem);
        game.overlays.add(CoffeeMachineDialogs.thanks.toString());
      } else if (activeItem.id == 'mate') {
        game.overlays.add(CoffeeMachineDialogs.noMate.toString());
      } else {
        game.overlays.add(CoffeeMachineDialogs.wrongItem.toString());
      }
      game.resetSelection();
    } else {
      game.overlays.add(CoffeeMachineDialogs.normalAction.toString());
    }
  }
}
