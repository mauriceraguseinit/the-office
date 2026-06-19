import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:the_office/speech_bubble.dart';
import 'package:the_office/trigger_zone.dart';

import 'office_game.dart';

enum DanielDialogs { normalAction, mate }

class DeskDaniel extends SpriteAnimationGroupComponent with HasGameReference<OfficeGame>, HoverCallbacks, Interactable {
  DeskDaniel({required super.position, required super.size, this.hitBox = true});
  static Map<String, OverlayWidgetBuilder<OfficeGame>> dialogs = {
    DanielDialogs.normalAction.toString(): (context, OfficeGame game) => RetroSpeechBubble(
      text:
          '[b]Daniel:[/b]\n\nHmm...\n\nIrgendwie habe ich hunger glaube ich. Mal sehen ob ich noch ne Dose Tuhnfisch finde, die ich zu meinem Joghurt essen kann.',
      onClose: () => game.overlays.remove(DanielDialogs.normalAction.toString()),
    ),
    DanielDialogs.normalAction.toString(): (context, OfficeGame game) => RetroSpeechBubble(
      text: '[b]Daniel:[/b]\n\nIch trinke eigentlich nur Fritz Cola und dann auch nur Zero.',
      onClose: () => game.overlays.remove(DanielDialogs.normalAction.toString()),
    ),
  };

  final bool hitBox;

  static double pngWidth = 2152;
  static double frame = 4;
  static double pngHeight = 404;
  static double get frameWidth => pngWidth / frame;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    priority = 10;
    final anim = await game.loadSpriteAnimation(
      'desk_daniel.png',
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.915, textureSize: Vector2(frameWidth, pngHeight)),
    );

    // Jetzt übergeben wir die Animationen an die Komponente
    animations = {'idle': anim};
    current = 'idle';

    if (hitBox) {
      add(RectangleHitbox());
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    // 2. Welches Item hat der Spieler an der Maus ausgewählt?
    final activeItem = game.selectedItem;

    if (activeItem != null) {
      // 3. Fall: Ein Item wurde auf Tobi geklickt!
      if (activeItem.id == 'kaffee') {
        print("Daniel: 'Oh danke! Der Kaffee rettet meinen Tag!'");

        // Item aus dem Inventar löschen und Auswahl zurücksetzen
        game.ownedItems.remove(activeItem);
        game.resetSelection();
      } else if (activeItem.id == 'mate') {
        game.overlays.add(DanielDialogs.mate.toString());

        // game.ownedItems.remove(activeItem);
        game.resetSelection();
      } else {
        // Falsches Item erwischt
        print("Daniel schaut das Item an: 'Was soll ich damit?'");
      }
    } else {
      // 4. Fall: Klick auf Tobi OHNE Item (Normales Ansprechen)
      game.overlays.add(DanielDialogs.normalAction.toString());
    }
  }
}
