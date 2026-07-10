import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:the_office/hud/speech_bubble.dart';
import 'package:the_office/models/inventory_item.dart';

import 'interactive_object.dart';

enum FridgeDialogs { normalAction, thanks, wrongItem, noMate }

class Fridge extends InteractiveObject {
  Fridge({
    required super.position,
    required super.sprite,
    super.size,
    super.priorityOffset,
  });

  @override
  Map<String, Widget Function(BuildContext, Game)> get dialogs {
    return <String, Widget Function(BuildContext, Game)>{
      for (final FridgeDialogs value in FridgeDialogs.values)
        value.toString(): (BuildContext context, Game game) {
          switch (value) {
            case FridgeDialogs.normalAction:
              return RetroSpeechBubble(
                text: '[b]Kühlschrank:[/b]\n\nDefekt!',
                onClose: () => game.overlays.remove(value.toString()),
              );
            case FridgeDialogs.wrongItem:
              return RetroSpeechBubble(
                text: '[b]Kühlschrank:[/b]\n\nDas gehört hier nicht rein.',
                onClose: () => game.overlays.remove(value.toString()),
              );
            case FridgeDialogs.noMate:
              return RetroSpeechBubble(
                text: '[b]Kühlschrank:[/b]\n\nGluckert protestierend.',
                onClose: () => game.overlays.remove(value.toString()),
              );
            case FridgeDialogs.thanks:
              return RetroSpeechBubble(
                text: '[b]Kühlschrank:[/b]\n\nSpült dankbar.',
                onClose: () => game.overlays.remove(value.toString()),
              );
          }
        },
    };
  }

  @override
  void onTapDown(TapDownEvent event) {
    final InventoryItem? activeItem = game.selectedItem;

    if (activeItem != null) {
      if (activeItem.id == 'kaffee') {
        game.ownedItems.remove(activeItem);
        game.overlays.add(FridgeDialogs.thanks.toString());
      } else if (activeItem.id == 'mate') {
        game.overlays.add(FridgeDialogs.noMate.toString());
      } else {
        game.overlays.add(FridgeDialogs.wrongItem.toString());
      }
      game.resetSelection();
    } else {
      game.overlays.add(FridgeDialogs.normalAction.toString());
    }
  }
}
