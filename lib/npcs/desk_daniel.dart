import 'package:the_office/models/interaction_system.dart';

import '../interactiveObjects/interactive_object.dart';

class DeskDaniel extends InteractiveObject {
  DeskDaniel({
    required super.position,
    required super.size,
    this.hitBox = true,
    required super.renderComponent,
    required super.displayName,
    super.priorityOffset,
  });

  final bool hitBox;

  @override
  List<InteractionRule> get rules => <InteractionRule>[
    // Fall 1: Kaffee geben
    InteractionRule(
      requirements: <Requirement>[ItemRequirement('kaffee')],
      actions: <GameAction>[
        RemoveItemAction('kaffee'),
        ShowMessageAction('[b]Daniel:[/b]\n\nOh danke! Der Kaffee rettet meinen Tag!'),
      ],
    ),
    // Fall 2: Mate geben
    InteractionRule(
      requirements: <Requirement>[ItemRequirement('mate')],
      actions: <GameAction>[
        ShowMessageAction('[b]Daniel:[/b]\n\nIch trinke eigentlich nur Fritz Cola und dann auch nur Zero.'),
      ],
    ),
    // Fall 3: Falsches Item
    InteractionRule(
      requirements: <Requirement>[AnyItemRequirement()],
      actions: <GameAction>[
        ShowMessageAction('[b]Daniel:[/b]\n\nWas soll ich damit?'),
      ],
    ),
    // Fall 4: Einfache Interaktion
    InteractionRule(
      requirements: <Requirement>[NoItemRequirement()],
      actions: <GameAction>[
        ShowMessageAction(
          '[b]Daniel:[/b]\n\nHmm...\n\nIrgendwie habe ich hunger glaube ich. Mal sehen ob ich noch ne Dose Tuhnfisch finde, die ich zu meinem Joghurt essen kann.',
        ),
      ],
    ),
  ];
}
