import 'package:the_office/interactiveObjects/inventory_item_catalogue.dart';
import 'package:the_office/models/interaction_system.dart';

import '../managers/game_state.dart';
import 'interactive_object.dart';

class FishCan extends InteractiveObject {
  FishCan({
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
        ShowMessageAction('[b]Hendrik:[/b]\n\nDas lässt sich damit nicht kombinieren.'),
      ],
    ),
    // Fall 2: Einfache Interaktion
    InteractionRule(
      requirements: <Requirement>[NoItemRequirement()],
      actions: <GameAction>[
        AddItemAction(InventoryItemCatalogue.itemForId(InventoryItemType.fishCan)),
        SetFlagAction(Flags.fishCanGone.name),
        RemoveObjectAction(),
        ShowMessageAction(
          '[b]Hendrik:[/b]\n\nNa die pack ich doch glatt mal ein. Die wird sicherlich noch nützlich sein.',
        ),
      ],
    ),
  ];

  @override
  Future<void> onLoad() async {
    if (officeGame.state.hasFlag(Flags.fishCanGone.name)) {
      removeFromParent();
      return;
    }
    await super.onLoad();
  }
}
