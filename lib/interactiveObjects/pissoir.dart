import 'package:the_office/interactiveObjects/interactive_object.dart';
import 'package:the_office/models/interaction_system.dart';

class Pissoir extends InteractiveObject {
  Pissoir({
    required super.position,
    required super.renderComponent,
    super.size,
    super.priorityOffset,
    required super.displayName,
  });

  @override
  List<InteractionRule> get rules => <InteractionRule>[
    // Fall 1: Falsches Item (beliebiges anderes Item ausgewählt)
    InteractionRule(
      requirements: <Requirement>[AnyItemRequirement()],
      actions: <GameAction>[
        ShowMessageAction('[b]Hendrik:[/b]\n\nDas gehört hier nicht rein.'),
      ],
    ),
    // Fall 2: Einfache Interaktion ohne Item
    InteractionRule(
      requirements: <Requirement>[NoItemRequirement()],
      actions: <GameAction>[
        PeeAction(),
      ],
    ),
  ];
}
