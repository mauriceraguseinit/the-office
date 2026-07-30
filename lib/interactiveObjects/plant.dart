import 'package:the_office/interactiveObjects/inventory_item_catalogue.dart';
import 'package:the_office/managers/game_state.dart';
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
    // Fall 1: Mit Klo-Wasser gießen
    InteractionRule(
      requirements: <Requirement>[ItemRequirement(InventoryItemType.mateWater.toString())],
      actions: <GameAction>[
        RemoveItemAction(InventoryItemType.mateWater.toString()),
        AddItemAction(InventoryItemCatalogue.itemForId(InventoryItemType.mateEmpty)),
        SetFlagAction(Flags.plantHasWaterMateFlag.name),
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
        SetFlagAction(Flags.plantHasMate.name),
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
      requirements: <Requirement>[
        NoItemRequirement(),
        FlagRequirement(Flags.plantHasMate.name, requiredValue: false),
        FlagRequirement(Flags.plantHasWaterMateFlag.name, requiredValue: false),
      ],
      actions: <GameAction>[
        ShowMessageAction(
          '[b]Hendrik:[/b]\n\nDie Blätter hängen ziemlich durch. Ich glaube, sie braucht dringend ein Firmware-Update. Oder Wasser.',
        ),
      ],
    ),
    InteractionRule(
      requirements: <Requirement>[
        NoItemRequirement(),
        FlagRequirement(Flags.plantHasMate.name, requiredValue: true),
        FlagRequirement(Flags.plantHasWaterMateFlag.name, requiredValue: false),
      ],
      actions: <GameAction>[
        ShowMessageAction(
          '[b]Hendrik:[/b]\n\nFit und vital, genauso so wie ich... *zwinker*',
        ),
      ],
    ),
    InteractionRule(
      requirements: <Requirement>[
        NoItemRequirement(),
        FlagRequirement(Flags.plantHasMate.name, requiredValue: false),
        FlagRequirement(Flags.plantHasWaterMateFlag.name, requiredValue: true),
      ],
      actions: <GameAction>[
        ShowMessageAction(
          '[b]Hendrik:[/b]\n\nAuf den ersten Blick sieht sie mittlerweile wieder gut aus, aber ein gewisser übelriechender Dunstnebel umgibt sie jetzt. Vielleicht ist das die Cloud, von der alle reden?!',
        ),
      ],
    ),
    InteractionRule(
      requirements: <Requirement>[
        NoItemRequirement(),
        FlagRequirement(Flags.plantHasMate.name),
        FlagRequirement(Flags.plantHasWaterMateFlag.name),
      ],
      actions: <GameAction>[
        ShowMessageAction(
          '[b]Hendrik:[/b]\n\nSieht aus, als hätte ich neues Leben geschaffen. Das Gemisch aus Mate und Klowasser hat Chuck auf eine neue Stufe der Evolution gebracht. Vielleicht ist das diese künstliche Intelligenz, von der alle reden?!',
        ),
      ],
    ),
  ];
}
