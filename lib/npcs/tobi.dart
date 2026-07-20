import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:the_office/hud/speech_bubble.dart';
import 'package:the_office/models/inventory_item.dart';

import '../interactiveObjects/interactive_object.dart';
import '../interactiveObjects/inventory_item_catalogue.dart';

enum TobiDialogs {
  normalAction,
  thanks,
  wrongItem,
  noMate,
  mateWater,
}

class Tobi extends InteractiveObject {
  Tobi({
    required super.position,
    required super.size,
    this.hitBox = true,
    required super.displayName,
    required super.renderComponent,
    super.priorityOffset,
  });

  @override
  Map<String, Widget Function(BuildContext, Game)> get dialogs {
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
            case TobiDialogs.mateWater:
              return RetroSpeechBubble(
                text:
                    '[b]Tobias:[/b]\n\nUuuuh eine neue Geschmackssorte!!!\n\n*trink, trink* *trink*\n\nDa bring ich doch gleich mal die leere Flasche weg.',
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
  void onAction() {
    final InventoryItem? activeItem = game.selectedItem;

    if (activeItem != null) {
      if (activeItem.id == 'kaffee') {
        debugPrint("Tobi: 'Oh danke! Der Kaffee rettet meinen Tag!'");
        game.inventory.remove(activeItem);
      } else if (activeItem.id == InventoryItemType.mate.toString()) {
        game.overlays.add(TobiDialogs.noMate.toString());
      } else if (activeItem.id == InventoryItemType.mateWater.toString()) {
        game.inventory.remove(activeItem);
        game.world.remove(this);
        game.overlays.add(TobiDialogs.mateWater.toString());
      } else {
        game.overlays.add(TobiDialogs.wrongItem.toString());
      }
      game.resetSelection();
    } else {
      game.overlays.add(TobiDialogs.normalAction.toString());
    }
  }
}
