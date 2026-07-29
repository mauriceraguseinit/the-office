import 'package:the_office/models/interaction_system.dart';

import 'interactive_object.dart';

class CoffeeMachine extends InteractiveObject {
  CoffeeMachine({
    required super.position,
    required super.renderComponent,
    super.size,
    required super.displayName,
    super.priorityOffset,
    super.interactionPadding = 15,
  });

  @override
  List<InteractionRule> get rules => <InteractionRule>[
    // Fall 1: Kaffee benutzen (vielleicht zum Reinigen?)
    InteractionRule(
      requirements: <Requirement>[ItemRequirement('kaffee')],
      actions: <GameAction>[
        RemoveItemAction('kaffee'),
        ShowMessageAction('[b]Kaffeemaschine:[/b]\n\nSpült dankbar.'),
      ],
    ),
    // Fall 2: Mate benutzen
    InteractionRule(
      requirements: <Requirement>[ItemRequirement('mate')],
      actions: <GameAction>[
        ShowMessageAction('[b]Kaffeemaschine:[/b]\n\nGluckert protestierend.'),
      ],
    ),
    // Fall 3: Falsches Item
    InteractionRule(
      requirements: <Requirement>[AnyItemRequirement()],
      actions: <GameAction>[
        ShowMessageAction('[b]Hendrik:[/b]\n\nDas gehört hier nicht rein.'),
      ],
    ),
    // Fall 4: Einfache Interaktion
    InteractionRule(
      requirements: <Requirement>[NoItemRequirement()],
      actions: <GameAction>[
        ShowMessageAction(
          '[b]Hendrik:[/b]\n\nIch weiß nicht, ob das grüne ungeröstete Kaffeebohnen sind, aber der pelzige Überzug erinnert mich daran, vielleicht etwas magen-schohnenderes zu trinken.!',
        ),
      ],
    ),
  ];
}
