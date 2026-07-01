import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:the_office/hud/speech_bubble.dart';
import 'package:the_office/trigger_zone.dart';

import '../../office_game.dart';

enum ToiletDialogs { normalAction, thanks, wrongItem, noMate }

class Toilet extends SpriteComponent with HasGameReference<OfficeGame>, HoverCallbacks, Interactable {
  Map<String, OverlayWidgetBuilder<OfficeGame>> get _dialogs {
    return {
      for (final value in ToiletDialogs.values)
        value.toString(): (context, OfficeGame game) {
          switch (value) {
            case ToiletDialogs.normalAction:
              return RetroSpeechBubble(
                text: '[b]Toilette:[/b]\n\nNerv mich nicht. Ich bereite gerade meinen nächsten Zahnarzttermin vor.',
                onClose: () => game.overlays.remove(value.toString()),
              );
            case ToiletDialogs.wrongItem:
              return RetroSpeechBubble(
                text: '[b]Toilette:[/b]\n\nWas soll ich damit?',
                onClose: () => game.overlays.remove(value.toString()),
              );
            case ToiletDialogs.noMate:
              return RetroSpeechBubble(
                text:
                    '[b]Toilette:[/b]\n\nIch trinke seit 345,3 Tagen keine Mate mehr und gehe regelmäßig zu den Treffen der anonymen Mateholiker.\n\nLass mich in Ruhe!',
                onClose: () => game.overlays.remove(value.toString()),
              );
            case ToiletDialogs.thanks:
              return RetroSpeechBubble(
                text: '[b]Toilette:[/b]\n\nDanke',
                onClose: () => game.overlays.remove(value.toString()),
              );
          }
        },
    };
  }

  Toilet({required super.position, super.size, this.hitBox = true});

  final bool hitBox;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    game.overlayBuilderMap?.addAll(_dialogs);

    priority = (y + height / 2).toInt();
    debugMode = false;
    anchor = Anchor.centerRight;

    sprite = await .load('toilet.png');

    if (hitBox) {
      add(RectangleHitbox(size: Vector2(size.x, (size.y) / 2)));
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
      } else if (activeItem.id == 'mate') {
        game.overlays.add(ToiletDialogs.noMate.toString());
      } else {
        game.overlays.add(ToiletDialogs.wrongItem.toString());
      }
      game.resetSelection();
    } else {
      // 4. Fall: Klick auf Tobi OHNE Item (Normales Ansprechen)
      game.overlays.add(ToiletDialogs.normalAction.toString());
    }
  }
}
