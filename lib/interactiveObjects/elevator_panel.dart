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
    // Fall 1: Falsches Item
    InteractionRule(
      requirements: <Requirement>[AnyItemRequirement()],
      actions: <GameAction>[
        ShowMessageAction('[b]Hendrik:[/b]\n\nDas gehört hier nicht rein.'),
      ],
    ),
    // Fall 2: Einfache Interaktion
    InteractionRule(
      requirements: <Requirement>[NoItemRequirement()],
      actions: <GameAction>[
        CustomAction((state) {
          officeGame.openOverlay('elevator');
        }),
      ],
    ),
  ];
}
