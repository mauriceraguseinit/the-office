import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:the_office/hud/speech_bubble.dart';
import 'package:the_office/models/inventory_item.dart';

import 'interactive_object.dart';

enum ToiletDialogs { normalAction, thanks, wrongItem, noMate }

class Toilet extends InteractiveObject {
  Toilet({
    required super.position,
    required super.renderComponent,
    super.size,
    super.priorityOffset,
    required super.displayName,
  });

  @override
  Map<String, Widget Function(BuildContext, Game)> get dialogs {
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

  @override
  void onAction() {
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
