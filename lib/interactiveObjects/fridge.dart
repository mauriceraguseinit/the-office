import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:the_office/hud/speech_bubble.dart';
import 'package:the_office/models/inventory_item.dart';

import 'interactive_object.dart';
import 'inventory_item_catalogue.dart';

enum FridgeDialogs { normalAction, wrongItem }

class Fridge extends InteractiveObject {
  Fridge({
    required super.position,
    required super.renderComponent,
    super.size,
    super.priorityOffset,
    required super.displayName,
  });

  @override
  Map<String, Widget Function(BuildContext, Game)> get dialogs {
    return <String, Widget Function(BuildContext, Game)>{
      for (final FridgeDialogs value in FridgeDialogs.values)
        value.toString(): (BuildContext context, Game game) {
          switch (value) {
            case FridgeDialogs.normalAction:
              {
                String returnText = '[b]Hendrik:[/b]\n\nUuhhh eine kalte Mate!';

                if (this.game.inventory
                    .where((InventoryItem item) => item.id == InventoryItemType.mate.toString())
                    .isNotEmpty) {
                  returnText = '[b]Hendrik:[/b]\n\nmmhh... nichts was ich nicht schon habe.';
                } else {
                  this.game.inventory.add(InventoryItemCatalogue.itemForId(InventoryItemType.mate));
                }
                return RetroSpeechBubble(
                  text: returnText,
                  onClose: () => game.overlays.remove(value.toString()),
                );
              }
            case FridgeDialogs.wrongItem:
              return RetroSpeechBubble(
                text: '[b]Kühlschrank:[/b]\n\nDas gehört hier nicht rein.',
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
      {
        game.overlays.add(FridgeDialogs.wrongItem.toString());
      }
      game.resetSelection();
    } else {
      game.overlays.add(FridgeDialogs.normalAction.toString());
    }
  }
}
