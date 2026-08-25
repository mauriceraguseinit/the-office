import 'package:flame/components.dart';
import 'package:the_office/models/interaction_system.dart';

import '../managers/game_state.dart';
import '../utils/assets.dart';
import 'interactive_object.dart';
import 'inventory_item_catalogue.dart';

class HendrikDesk extends InteractiveObject {
  HendrikDesk({
    required super.position,
    required super.renderComponent,
    super.size,
    required super.displayName,
    super.priorityOffset,
    super.interactionPadding = 15,
  });

  Sprite? _deskSprite;
  Sprite? _deskEmptySprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Sprites laden
    _deskSprite = await game.loadSprite(GameImages.desk);
    _deskEmptySprite = await game.loadSprite(GameImages.deskEmpty);

    // Initiales Bild setzen
    _updateVisuals();

    // Auf Änderungen im GameState hören
    officeGame.state.addListener(_updateVisuals);
  }

  @override
  void onRemove() {
    officeGame.state.removeListener(_updateVisuals);
    super.onRemove();
  }

  void _updateVisuals() {
    if (_deskSprite == null || _deskEmptySprite == null) return;

    if (renderComponent is SpriteComponent) {
      final SpriteComponent spriteComp = renderComponent as SpriteComponent;
      final bool hasNotebook = officeGame.state.hasFlag(Flags.notebookOnDesk.name);
      spriteComp.sprite = hasNotebook ? _deskSprite : _deskEmptySprite;
    }
  }

  @override
  List<InteractionRule> get rules => <InteractionRule>[
    // Fall 1: Kaffee benutzen (vielleicht zum Reinigen?)
    InteractionRule(
      requirements: <Requirement>[ItemRequirement(InventoryItemType.notebook.toString())],
      actions: <GameAction>[
        RemoveItemAction(InventoryItemType.notebook.toString()),
        SetFlagAction(Flags.notebookOnDesk.name),

        ShowMessageAction(
          '[b]Hendrik:[/b]\n\nJetzt kann die Arbeit los gehen. Mir kribbelts regelrecht in den Fingern... \n\nVielleicht sollte ich das mal untersuchen lassen.',
        ),
      ],
    ),
    // Fall 2: Mate benutzen
    InteractionRule(
      requirements: <Requirement>[ItemRequirement('mate')],
      actions: <GameAction>[
        ShowMessageAction(
          '[b]Hendrik:[/b]\n\nIch habe Monate gebraucht ein neues neue Notebook zu bekommen. Da sollte ich es nicht gleich kaputt machen.',
        ),
      ],
    ),
    // Fall 3: Falsches Item
    InteractionRule(
      requirements: <Requirement>[AnyItemRequirement()],
      actions: <GameAction>[
        ShowMessageAction('[b]Hendrik:[/b]\n\nDas passt irgendwie nicht zusammen.'),
      ],
    ),
    // Fall 4: Einfache Interaktion
    InteractionRule(
      requirements: <Requirement>[
        NoItemRequirement(),
        FlagRequirement(Flags.notebookOnDesk.name, requiredValue: false),
      ],
      actions: <GameAction>[
        ShowMessageAction(
          '[b]Hendrik:[/b]\n\nOhne Notebook kann ich zwar so tun als würde ich arbeiten, aber wie soll ich dann Youtube Videos schauen?',
        ),
      ],
    ),
    InteractionRule(
      requirements: <Requirement>[
        NoItemRequirement(),
        FlagRequirement(Flags.notebookOnDesk.name),
      ],
      actions: <GameAction>[
        CustomAction((GameState state) {
          officeGame.openOverlay('desk_menu');
        }),
      ],
    ),
  ];
}
