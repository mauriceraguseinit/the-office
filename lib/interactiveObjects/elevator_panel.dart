import 'package:the_office/interactiveObjects/inventory_item_catalogue.dart';
import 'package:the_office/models/interaction_system.dart';

import 'interactive_object.dart';

class ElevatorPanel extends InteractiveObject {
  ElevatorPanel({
    required super.position,
    required super.renderComponent,
    super.size,
    super.priorityOffset,
    required super.displayName,
    super.interactionPadding = 15,
  });

  @override
  List<InteractionRule> get rules => <InteractionRule>[
    // Fall 1: Leere Mate-Flasche (Pfand) wegwerfen wollen
    InteractionRule(
      requirements: <Requirement>[ItemRequirement(InventoryItemType.mateEmpty.toString())],
      actions: <GameAction>[
        ShowMessageAction('[b]Hendrik:[/b]\n\nLeere Pfand Flaschen gehören hier nicht rein.'),
      ],
    ),
    // Fall 2: Falsches Item
    InteractionRule(
      requirements: <Requirement>[AnyItemRequirement()],
      actions: <GameAction>[
        ShowMessageAction('[b]Hendrik:[/b]\n\nDas gehört hier nicht rein.'),
      ],
    ),
    // Fall 3: Einfache Interaktion
    InteractionRule(
      requirements: <Requirement>[NoItemRequirement()],
      actions: <GameAction>[
        ShowRandomMessageAction(
          <String>[
            '[b]Hendrik:[/b]\n\nIch bin doch gerade erst angekommen.',
            '[b]Hendrik:[/b]\n\nIch glaube ich sollte wenigsten so tun als würde ich arbeiten.',
          ],
        ),
      ],
    ),
  ];
}
