// tobi.dart
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:the_office/speech_bubble.dart';
import 'package:the_office/trigger_zone.dart';

import 'office_game.dart';

enum TobiDialogs { normalAction, thanks }

class Tobi extends SpriteAnimationGroupComponent with HasGameReference<OfficeGame>, Interactable {
  static Map<String, OverlayWidgetBuilder<OfficeGame>> dialogs = {
    TobiDialogs.normalAction.toString(): (context, OfficeGame game) => RetroSpeechBubble(
      text: '[b]Tobias:[/b]\n\nNerv mich nicht. Ich bereite gerade meinen nächsten Zahnarzttermin vor.',
      onClose: () => game.overlays.remove(TobiDialogs.normalAction.toString()),
    ),

    TobiDialogs.thanks.toString(): (context, OfficeGame game) => RetroSpeechBubble(
      text: '[b]Tobias:[/b]\n\nDanke',
      onClose: () => game.overlays.remove(TobiDialogs.thanks.toString()),
    ),
  };
  Tobi({required super.position, required super.size, this.hitBox = true});

  final bool hitBox;
  static double pngWidth = 1488;
  static double frame = 4;
  static double pngHeight = 495;
  static double get frameWidth => pngWidth / frame;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    priority = 10;

    final anim = await game.loadSpriteAnimation(
      'tobi_idle.png',
      SpriteAnimationData.sequenced(amount: 4, stepTime: 0.15, textureSize: Vector2(frameWidth, pngHeight)),
    );
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
        print("Tobi: 'Oh danke! Der Kaffee rettet meinen Tag!'");

        // Item aus dem Inventar löschen und Auswahl zurücksetzen
        game.ownedItems.remove(activeItem);
        game.resetSelection();
      } else if (activeItem.id == 'kuendigung') {
        print("Tobi: 'Das ist jetzt ein schlechter Scherz, oder?!'");

        game.ownedItems.remove(activeItem);
        game.resetSelection();
      } else {
        // Falsches Item erwischt
        print("Tobi schaut das Item an: 'Was soll ich damit?'");
      }
    } else {
      // 4. Fall: Klick auf Tobi OHNE Item (Normales Ansprechen)
      game.overlays.add(TobiDialogs.normalAction.toString());
    }
  }
}
