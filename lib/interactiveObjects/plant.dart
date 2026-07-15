import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:the_office/hud/speech_bubble.dart';
import 'package:the_office/interactiveObjects/inventory_item_catalogue.dart';
import 'package:the_office/models/inventory_item.dart';

import 'interactive_object.dart';

enum PlantDialogs {
  normalAction,
  wrongItem,
  mate,
  waterMate,
}

class Plant extends InteractiveObject {
  Plant({
    required super.position,
    required super.renderComponent,
    super.size,
    super.priorityOffset,
    required super.displayName,
  });

  @override
  Map<String, Widget Function(BuildContext, Game)> get dialogs {
    return <String, Widget Function(BuildContext, Game)>{
      for (final PlantDialogs value in PlantDialogs.values)
        value.toString(): (BuildContext context, Game game) {
          switch (value) {
            case PlantDialogs.normalAction:
              {
                return RetroSpeechBubble(
                  text:
                      '[b]Hendrik:[/b]\n\nDie Blätter hängen ziemlich durch. Ich glaube, sie braucht dringend ein Firmware-Update. Oder Wasser.',
                  onClose: () => game.overlays.remove(value.toString()),
                );
              }
            case PlantDialogs.wrongItem:
              return RetroSpeechBubble(
                text: '[b]Hendrik:[/b]\n\nDas gehört hier nicht rein.',
                onClose: () => game.overlays.remove(value.toString()),
              );
            case PlantDialogs.mate:
              return RetroSpeechBubble(
                text:
                    '[b]Hendrik:[/b]\n\nPerfekt. Jetzt hat sie genug Koffein, um den Release heute Abend durchzustehen.',
                onClose: () => game.overlays.remove(value.toString()),
              );
            case PlantDialogs.waterMate:
              {
                return RetroSpeechBubble(
                  text:
                      '[b]Hendrik:[/b]\n\nPuh... Jetzt riecht die Pflanze nach einer Mischung aus feuchter Erde, Chlor und dem, was die Backend-Entwickler nach dem gestrigen "Scharfe-Tacos-Dienstag" hinterlassen haben. Ein echtes Dufterlebnis..',
                  onClose: () => game.overlays.remove(value.toString()),
                );
              }
          }
        },
    };
  }

  @override
  void onAction() {
    final InventoryItem? activeItem = game.selectedItem;

    if (activeItem != null) {
      if (activeItem.id == InventoryItemType.mateWater.toString()) {
        officeGame.inventory.remove(activeItem);
        officeGame.inventory.add(InventoryItemCatalogue.itemForId(InventoryItemType.mateEmpty));
        game.overlays.add(PlantDialogs.waterMate.toString());
      } else if (activeItem.id == InventoryItemType.mate.toString()) {
        officeGame.inventory.remove(activeItem);
        officeGame.inventory.add(InventoryItemCatalogue.itemForId(InventoryItemType.mateEmpty));
        game.overlays.add(PlantDialogs.mate.toString());
      } else {
        game.overlays.add(PlantDialogs.wrongItem.toString());
      }

      game.resetSelection();
    } else {
      game.overlays.add(PlantDialogs.normalAction.toString());
    }
  }
}
