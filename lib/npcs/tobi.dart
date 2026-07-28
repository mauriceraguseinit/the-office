import 'package:the_office/interactiveObjects/interactive_object.dart';
import 'package:the_office/interactiveObjects/inventory_item_catalogue.dart';
import 'package:the_office/models/interaction_system.dart';

class Tobi extends InteractiveObject {
  Tobi({
    required super.position,
    required super.size,
    this.hitBox = true,
    required super.displayName,
    required super.renderComponent,
    super.priorityOffset,
  });

  final bool hitBox;
  static double pngWidth = 1488;
  static double frame = 4;
  static double pngHeight = 495;
  static double get frameWidth => pngWidth / frame;

  @override
  List<InteractionRule> get rules => <InteractionRule>[
    // Fall 1: Mate-Wasser geben (Tobi verschwindet)
    InteractionRule(
      requirements: <Requirement>[ItemRequirement(InventoryItemType.mateWater.toString())],
      actions: <GameAction>[
        RemoveItemAction(InventoryItemType.mateWater.toString()),
        SetFlagAction('tobi_gone'),
        CustomAction((_) => removeFromParent()),
        ShowMessageAction(
          '[b]Tobias:[/b]\n\nUuuuh eine neue Geschmackssorte!!!\n\n*trink, trink* *trink*\n\nDa bring ich doch gleich mal die leere Flasche weg.',
        ),
      ],
    ),
    // Fall 2: Normale Mate geben
    InteractionRule(
      requirements: <Requirement>[ItemRequirement(InventoryItemType.mate.toString())],
      actions: <GameAction>[
        ShowMessageAction(
          '[b]Tobias:[/b]\n\nIch trinke seit 345,3 Tagen keine Mate mehr und gehe regelmäßig zu den Treffen der anonymen Mateholiker.\n\nLass mich in Ruhe!',
        ),
      ],
    ),
    // Fall 3: Kaffee geben
    InteractionRule(
      requirements: <Requirement>[ItemRequirement('kaffee')],
      actions: <GameAction>[
        RemoveItemAction('kaffee'),
        ShowMessageAction('[b]Tobias:[/b]\n\nOh danke! Der Kaffee rettet meinen Tag!'),
      ],
    ),
    // Fall 4: Falsches Item
    InteractionRule(
      requirements: <Requirement>[AnyItemRequirement()],
      actions: <GameAction>[
        ShowMessageAction('[b]Tobias:[/b]\n\nWas soll ich damit?'),
      ],
    ),
    // Fall 5: Einfache Interaktion
    InteractionRule(
      requirements: <Requirement>[NoItemRequirement()],
      actions: <GameAction>[
        ShowMessageAction('[b]Tobias:[/b]\n\nNerv mich nicht. Ich bereite gerade meinen nächsten Zahnarzttermin vor.'),
      ],
    ),
  ];

  @override
  Future<void> onLoad() async {
    if (officeGame.state.hasFlag('tobi_gone')) {
      removeFromParent();
      return;
    }
    await super.onLoad();
  }
}
