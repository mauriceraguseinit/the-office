import 'package:the_office/models/interaction_system.dart';

import '../interactiveObjects/interactive_object.dart';

class Kim extends InteractiveObject {
  Kim({
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
    // Fall Mate geben
    InteractionRule(
      requirements: <Requirement>[ItemRequirement('mate')],
      actions: <GameAction>[
        ShowMessageAction('[b]Kim:[/b]\n\nHab noch... danke!'),
      ],
    ),
    // Fall Falsches Item
    InteractionRule(
      requirements: <Requirement>[AnyItemRequirement()],
      actions: <GameAction>[
        ShowMessageAction('[b]Kim:[/b]\n\nWas soll ich damit?'),
      ],
    ),
    // Fall Einfache Interaktion
    InteractionRule(
      requirements: <Requirement>[NoItemRequirement()],
      actions: <GameAction>[
        ShowMessageAction(
          '[b]Kim:[/b]\n\nAh, Hendrik. Ich habe deine Fahrt im Fahrstuhl bereits in den Strömen des internen Netzwerks flüstern hören, lange bevor die Türen sich öffneten. Du suchst nach Antworten, nicht wahr? Die Mysterien des Universums liegen mir zu Füßen. Ich kenne jeden ungedachten Gedanken, jedes vergessene Passwort, den exakten Timestamp deines letzten Git-Commits um 03:14 Uhr nachts – und ja, ich weiß auch, dass du heute Morgen deinen Kaffeelöffel in den Müll geworfen und die Tasse in die Spüle getan hast. Ich sehe alles, Hendrik. Weil ich das Orakel der init AG bin... oder zumindest der Typ, den init hier unten abgestellt hat mit genug Mate um nie schlafen zu müssen."',
        ),
      ],
    ),
  ];
}
