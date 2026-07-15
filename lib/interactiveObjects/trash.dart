import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:the_office/hud/speech_bubble.dart';
import 'package:the_office/interactiveObjects/inventory_item_catalogue.dart';
import 'package:the_office/models/inventory_item.dart';

import 'interactive_object.dart';

enum TrashDialogs {
  normalAction,
  wrongItem,
  emptyMate,
}

class Trash extends InteractiveObject {
  Trash({
    required super.position,
    required super.renderComponent,
    super.size,
    super.priorityOffset,
    required super.displayName,
  });

  @override
  Map<String, Widget Function(BuildContext, Game)> get dialogs {
    return <String, Widget Function(BuildContext, Game)>{
      for (final TrashDialogs value in TrashDialogs.values)
        value.toString(): (BuildContext context, Game game) {
          switch (value) {
            case TrashDialogs.normalAction:
              {
                return RetroSpeechBubble(
                  text:
                      '[b]Hendrik:[/b]\n\nWir trennen im Büro unseren Müll jetzt vorbildlich nach Papier, Plastik und den unerledigten Aufgaben, die direkt im Schredder landen.',
                  onClose: () => game.overlays.remove(value.toString()),
                );
              }
            case TrashDialogs.wrongItem:
              return RetroSpeechBubble(
                text: '[b]Hendrik:[/b]\n\nDas gehört hier nicht rein.',
                onClose: () => game.overlays.remove(value.toString()),
              );
            case TrashDialogs.emptyMate:
              return RetroSpeechBubble(
                text: '[b]Hendrik:[/b]\n\nLeere Pfand Flaschen gehören hier nicht rein.',
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
      if (activeItem.id == InventoryItemType.mateEmpty.toString()) {
        game.overlays.add(TrashDialogs.emptyMate.toString());
      } else {
        game.overlays.add(TrashDialogs.wrongItem.toString());
      }

      game.resetSelection();
    } else {
      game.overlays.add(TrashDialogs.normalAction.toString());
    }
  }
}
