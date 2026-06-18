import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:the_office/speech_bubble.dart';

import 'main.dart';

enum DanielDialogs { normalAction, tooFar }

class DeskDaniel extends SpriteAnimationGroupComponent with HasGameReference<OfficeGame>, TapCallbacks {
  DeskDaniel({required super.position, required super.size, this.hitBox = true});
  static Map<String, OverlayWidgetBuilder<OfficeGame>> dialogs = {
    DanielDialogs.normalAction.toString(): (context, OfficeGame game) => RetroSpeechBubble(
      text:
          '[b]Daniel:[/b]\n\nHmm...\n\nIrgendwie habe ich hunger glaube ich. Mal sehen ob ich noch ne Dose Tuhnfisch finde, die ich zu meinem Joghurt essen kann.',
      onClose: () => game.overlays.remove(DanielDialogs.normalAction.toString()),
    ),
    DanielDialogs.tooFar.toString(): (context, OfficeGame game) => RetroSpeechBubble(
      text: 'Ich bin zu weit weg, um Daniel zu erreichen.',
      onClose: () => game.overlays.remove(DanielDialogs.tooFar.toString()),
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
    super.onTapDown(event);

    // 1. Reichweiten-Check: Ist der Spieler nah genug an Tobi dran?
    // (Misst den Abstand zwischen der Spielerposition und Tobis Position)
    final distance = game.player.position.distanceTo(absoluteCenter);
    if (distance > 120) {
      game.overlays.add(DanielDialogs.tooFar.toString());
      return;
    }

    // 2. Welches Item hat der Spieler an der Maus ausgewählt?
    final activeItem = game.selectedItem;

    if (activeItem != null) {
      // 3. Fall: Ein Item wurde auf Tobi geklickt!
      if (activeItem.id == 'kaffee') {
        print("Daniel: 'Oh danke! Der Kaffee rettet meinen Tag!'");

        // Item aus dem Inventar löschen und Auswahl zurücksetzen
        game.ownedItems.remove(activeItem);
        game.resetSelection();
      } else if (activeItem.id == 'kuendigung') {
        print("Daniel: 'Das ist jetzt ein schlechter Scherz, oder?!'");

        game.ownedItems.remove(activeItem);
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
