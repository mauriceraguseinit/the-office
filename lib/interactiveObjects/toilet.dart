import 'package:the_office/interactiveObjects/interactive_object.dart';
import 'package:the_office/interactiveObjects/inventory_item_catalogue.dart';
import 'package:the_office/models/interaction_system.dart';

class Toilet extends InteractiveObject {
  Toilet({
    required super.position,
    required super.renderComponent,
    super.size,
    super.priorityOffset,
    required super.displayName,
  });

  @override
  List<InteractionRule> get rules => <InteractionRule>[
    // Fall 1: Kaffee in die Toilette schütten
    InteractionRule(
      requirements: <Requirement>[ItemRequirement('kaffee')],
      actions: <GameAction>[
        RemoveItemAction('kaffee'),
        ShowMessageAction('[b]Toilette:[/b]\n\nSpült dankbar.'),
      ],
    ),
    // Fall 2: Mate trinken (Mate -> Leere Flasche)
    InteractionRule(
      requirements: <Requirement>[ItemRequirement(InventoryItemType.mate.toString())],
      actions: <GameAction>[
        RemoveItemAction(InventoryItemType.mate.toString()),
        AddItemAction(InventoryItemCatalogue.itemForId(InventoryItemType.mateEmpty)),
        ShowMessageAction('[b]Hendrik:[/b]\n\nIch trinke eh lieber einen Kaffee.'),
      ],
    ),
    // Fall 3: Flasche mit Klowasser füllen (Leere Flasche -> Klowasser-Mate)
    InteractionRule(
      requirements: <Requirement>[ItemRequirement(InventoryItemType.mateEmpty.toString())],
      actions: <GameAction>[
        RemoveItemAction(InventoryItemType.mateEmpty.toString()),
        AddItemAction(InventoryItemCatalogue.itemForId(InventoryItemType.mateWater)),
        ShowMessageAction('[b]Hendrik:[/b]\n\nNichts geht über einen erfrischenden Durstlöscher!'),
      ],
    ),
    // Fall 4: Falsches Item (beliebiges anderes Item ausgewählt)
    InteractionRule(
      requirements: <Requirement>[AnyItemRequirement()],
      actions: <GameAction>[
        ShowMessageAction('[b]Toilette:[/b]\n\nDas gehört hier nicht rein.'),
      ],
    ),
    // Fall 5: Einfache Interaktion ohne Item
    InteractionRule(
      requirements: <Requirement>[NoItemRequirement()],
      actions: <GameAction>[
        ShowMessageAction('[b]Toilette:[/b]\n\nBesetzt!'),
      ],
    ),
  ];
}
