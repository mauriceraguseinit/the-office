import 'package:the_office/interactiveObjects/inventory_item_catalogue.dart';
import 'package:the_office/models/interaction_system.dart';

import 'interactive_object.dart';

class Fridge extends InteractiveObject {
  Fridge({
    required super.position,
    required super.renderComponent,
    super.size,
    super.priorityOffset,
    required super.displayName,
  });

  @override
  List<InteractionRule> get rules => <InteractionRule>[
    // Fall 1: Falsches Item ausgewählt
    InteractionRule(
      requirements: <Requirement>[AnyItemRequirement()],
      actions: <GameAction>[
        ShowMessageAction('[b]Hendrik:[/b]\n\nDas gehört hier nicht rein.'),
      ],
    ),
    // Fall 2: Keine Mate im Inventar -> Mate nehmen
    InteractionRule(
      requirements: <Requirement>[
        NoItemRequirement(),
        HasNoItemRequirement(InventoryItemType.mate.toString()),
        FlagRequirement('mate_in_fridge', requiredValue: false), // Optional, falls wir mal leeren Kühlschrank wollen
      ],
      actions: <GameAction>[
        AddItemAction(InventoryItemCatalogue.itemForId(InventoryItemType.mate)),
        ShowMessageAction('[b]Hendrik:[/b]\n\nUuhhh eine kalte Mate!'),
      ],
    ),
    InteractionRule(
      requirements: <Requirement>[
        NoItemRequirement(),
        HasItemRequirement(InventoryItemType.mate.toString()),
        FlagRequirement('mate_in_fridge', requiredValue: false), // Optional, falls wir mal leeren Kühlschrank wollen
      ],
      actions: <GameAction>[
        ShowMessageAction('[b]Hendrik:[/b]\n\nmmhh... nichts was ich nicht schon habe.'),
      ],
    ),
    // Fall 3: Fallback (Eigentlich durch CustomAction abgedeckt, aber der Vollständigkeit halber)
    InteractionRule(
      requirements: <Requirement>[NoItemRequirement()],
      actions: <GameAction>[
        ShowMessageAction('[b]Hendrik:[/b]\n\nmmhh... nichts was ich nicht schon habe.'),
      ],
    ),
  ];
}
