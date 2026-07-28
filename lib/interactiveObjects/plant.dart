import 'package:the_office/interactiveObjects/inventory_item_catalogue.dart';
import 'package:the_office/models/interaction_system.dart';

import 'interactive_object.dart';

class Plant extends InteractiveObject {
  Plant({
    required super.position,
    required super.renderComponent,
    super.size,
    super.priorityOffset,
    required super.displayName,
  });

  @override
  List<InteractionRule> get rules => <InteractionRule>[
    // Fall 1: Mit Mate-Wasser gießen
    InteractionRule(
      requirements: <Requirement>[ItemRequirement(InventoryItemType.mateWater.toString())],
      actions: <GameAction>[
        RemoveItemAction(InventoryItemType.mateWater.toString()),
        AddItemAction(InventoryItemCatalogue.itemForId(InventoryItemType.mateEmpty)),
        ShowMessageAction(
          '[b]Hendrik:[/b]\n\nPuh... Jetzt riecht die Pflanze nach einer Mischung aus feuchter Erde, Chlor und dem, was die Backend-Entwickler nach dem gestrigen "Scharfe-Tacos-Dienstag" hinterlassen haben. Ein echtes Dufterlebnis..',
        ),
      ],
    ),
    // Fall 2: Mit normaler Mate gießen
    InteractionRule(
      requirements: <Requirement>[ItemRequirement(InventoryItemType.mate.toString())],
      actions: <GameAction>[
        RemoveItemAction(InventoryItemType.mate.toString()),
        AddItemAction(InventoryItemCatalogue.itemForId(InventoryItemType.mateEmpty)),
        ShowMessageAction(
          '[b]Hendrik:[/b]\n\nPerfekt. Jetzt hat sie genug Koffein, um den Release heute Abend durchzustehen.',
        ),
      ],
    ),
    // Fall 3: Falsches Item
    InteractionRule(
      requirements: <Requirement>[AnyItemRequirement()],
      actions: <GameAction>[
        ShowMessageAction('[b]Hendrik:[/b]\n\nDas gehört hier nicht rein.'),
      ],
    ),
    // Fall 4: Anschauen / Interaktion ohne Item
    InteractionRule(
      requirements: <Requirement>[NoItemRequirement()],
      actions: <GameAction>[
        ShowMessageAction(
          '[b]Hendrik:[/b]\n\nDie Blätter hängen ziemlich durch. Ich glaube, sie braucht dringend ein Firmware-Update. Oder Wasser.',
        ),
      ],
    ),
  ];
}
