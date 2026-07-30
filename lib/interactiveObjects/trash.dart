import 'package:the_office/interactiveObjects/inventory_item_catalogue.dart';
import 'package:the_office/models/interaction_system.dart';

import 'interactive_object.dart';

class Trash extends InteractiveObject {
  Trash({
    required super.position,
    required super.renderComponent,
    super.size,
    super.priorityOffset,
    required super.displayName,
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
        ShowRandomMessageAction([
          '[b]Hendrik:[/b]\n\nWir trennen im Büro unseren Müll jetzt vorbildlich nach Papier, Plastik und den unerledigten Aufgaben, die direkt im Schredder landen.',
          '[b]Hendrik:[/b]\n\nIst das dieser "Garbage Collector" von dem ich in der Uni gehört habe?',
          '[b]Hendrik:[/b]\n\nErst sortiere ich hier Plastik von Papier, und danach trenne ich Spaghetti-Code von meiner Rest-Motivation.',
          '[b]Hendrik:[/b]\n\nEndlich mal ein Prozess in dieser Firma, der einer klaren Logik folgt … und nicht fünfmal umgestoßen wird.',
        ]),
      ],
    ),
  ];
}
