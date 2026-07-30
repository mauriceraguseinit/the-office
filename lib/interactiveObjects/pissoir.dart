import 'package:the_office/interactiveObjects/interactive_object.dart';
import 'package:the_office/models/interaction_system.dart';

import '../managers/game_state.dart';

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
      requirements: <Requirement>[
        NoItemRequirement(),
        FlagRequirement(Flags.fullBladder.name),
      ],
      actions: <GameAction>[
        PeeAction(),
        SetFlagAction(Flags.fullBladder.name, value: false),
      ],
    ),
    InteractionRule(
      requirements: <Requirement>[
        NoItemRequirement(),
      ],
      actions: <GameAction>[
        ShowMessageAction('[b]Hendrik:[/b]\n\nIch muss gerade nicht. Vielleicht sollte ich erstmal was trinken.'),
      ],
    ),
  ];
}
