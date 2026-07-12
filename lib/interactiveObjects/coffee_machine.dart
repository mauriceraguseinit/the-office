import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:the_office/hud/speech_bubble.dart';
import 'package:the_office/models/inventory_item.dart';

import 'interactive_object.dart';

enum CoffeeMachineDialogs { normalAction, thanks, wrongItem, noMate }

class CoffeeMachine extends InteractiveObject {
  CoffeeMachine({
    required super.position,
    required super.renderComponent,
    super.size,
    required super.displayName,
    super.priorityOffset,
  });

  @override
  Map<String, Widget Function(BuildContext, Game)> get dialogs {
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
  void onAction() {
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
