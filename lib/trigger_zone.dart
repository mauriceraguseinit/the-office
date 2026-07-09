import 'package:flame/camera.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/cupertino.dart';
import 'package:the_office/hud/speech_bubble.dart';

import 'hendrik.dart';
import 'office_game.dart';

enum TriggerZoneDialogs { tooFar }

class TriggerZone extends PositionComponent with CollisionCallbacks, TapCallbacks, HasGameReference<OfficeGame> {
  TriggerZone({required this.target, required this.onAction, this.padding = 35.0});
  final Map<String, Widget Function(BuildContext, Game)> _dialogs = <String, Widget Function(BuildContext, Game)>{
    TriggerZoneDialogs.tooFar.toString(): (BuildContext context, Game game) => RetroSpeechBubble(
      text: 'Dafür bin ich zu weit weg.',
      onClose: () => game.overlays.remove(TriggerZoneDialogs.tooFar.toString()),
    ),
  };

  final PositionComponent target;
  final double padding;
  final VoidCallback onAction;

  bool _playerInside = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    debugMode = false;

    for (String key in _dialogs.keys) {
      game.overlays.addEntry(key, _dialogs[key]!);
    }

    final bool isRotated = target.angle == 1.5707963267948966 || target.angle == 4.71238898038469;

    if (isRotated) {
      size = Vector2(target.size.y, target.size.x) + Vector2(padding * 2, padding * 2);
    } else {
      size = target.size + Vector2(padding * 2, padding * 2);
    }

    anchor = Anchor.center;
    position = target.absoluteCenter;

    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Hendrik) {
      _playerInside = true;
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is Hendrik) {
      _playerInside = false;
    }
  }

  /// Der Clou: Wenn Hendrik 'E' drückt, verpassen wir der Abfrage ein Sicherheitsnetz.
  bool checkInteraction(Hendrik player) {
    // 1. Check: Erkennt Flame die Kollision ganz normal?
    if (_playerInside) return _executeAction();

    // 2. Sicherheitsnetz: Wenn der Spieler die innere Box rammt,
    // messen wir einfach den direkten Abstand zwischen den Mittelpunkten.
    final double distance = (player.absoluteCenter - target.absoluteCenter).length;

    // Wir berechnen die maximale Reichweite (halbe Diagonale der Trigger-Zone)
    final double maxAllowedDistance = size.length / 2;

    if (distance <= maxAllowedDistance) {
      return _executeAction();
    }

    return false;
  }

  bool _executeAction() {
    onAction();
    return true;
  }

  @override
  void onTapDown(TapDownEvent event) {
    // --- MINIMAP SCHUTZSCHILD START ---
    // Wandelt den echten Klick in die virtuellen 1280x720 Koordinaten um
    final Vector2 virtualPosition = (game.camera.viewport as FixedResolutionViewport).globalToLocal(
      event.canvasPosition,
    );
    // Feste Platzierung der Minimap auf der virtuellen Auflösung
    final double minimapLeft = 1280 - 220;
    final double minimapTop = 720 - 220;

    // Wenn der Klick innerhalb des Minimap-Quadrats gelandet ist, ignorieren wir ihn komplett!
    if (virtualPosition.x >= minimapLeft && virtualPosition.y >= minimapTop) {
      return;
    }
    // --- MINIMAP SCHUTZSCHILD ENDE ---

    final double distance = game.player.absoluteCenter.distanceTo(absoluteCenter);
    if (distance > 120) {
      // Nutzt den zentral registrierten String-Key aus deiner Hauptdatei
      game.overlays.add('TriggerZoneDialogs.tooFar');
      game.resetSelection();
      return;
    }

    if (target is Interactable) {
      (target as Interactable).onTapDown(event);
    }
  }
}

mixin Interactable on PositionComponent {
  void onTapDown(TapDownEvent event);

  bool isHovered = false;

  // Wir erstellen ein Paint-Objekt, das das Sprite komplett mit einer Farbe einfärbt
  static final Paint _outlinePaint = Paint()
    ..color =
        const Color(0xFFFFFFAA) // Deine Leucht-Farbe (z.B. helles Gelb/Weiß)
    ..colorFilter = const ColorFilter.mode(
      Color(0xFFFFFFAA),
      BlendMode.srcIn, // TRICK: Färbt alle deckenden Pixel des Sprites komplett ein
    );

  bool onHoverEnter() {
    isHovered = true;
    return true;
  }

  bool onHoverExit() {
    isHovered = false;
    return true;
  }

  @override
  void render(Canvas canvas) {
    if (isHovered) {
      // 1. Wir holen uns das passende Sprite, je nachdem ob animiert oder statisch
      Sprite? activeSprite;

      if (this is SpriteAnimationGroupComponent) {
        final SpriteAnimationGroupComponent<dynamic> group = this as SpriteAnimationGroupComponent<String>;
        final SpriteAnimation? currentAnim = group.animations?[group.current];
        if (currentAnim != null) {
          final SpriteAnimationTicker? ticker = group.animationTickers?[group.current];
          activeSprite = ticker?.getSprite() ?? currentAnim.frames.first.sprite;
        }
      } else if (this is SpriteComponent) {
        activeSprite = (this as SpriteComponent).sprite;
      }

      // 2. Wenn wir ein Sprite haben, malen wir den Rand
      if (activeSprite != null) {
        // Die Dicke des Randes in Pixeln (2-3 Pixel sieht bei Pixel Art meist am besten aus)
        final double thickness = 2.0;

        // Wir zeichnen das eingefärbte Sprite leicht versetzt in alle 4 Richtungen
        // (Für einen noch dickeren/runderen Rand kannst du auch die Diagonalen ergänzen)
        activeSprite.render(canvas, position: Vector2(-thickness, 0), size: size, overridePaint: _outlinePaint);
        activeSprite.render(canvas, position: Vector2(thickness, 0), size: size, overridePaint: _outlinePaint);
        activeSprite.render(canvas, position: Vector2(0, -thickness), size: size, overridePaint: _outlinePaint);
        activeSprite.render(canvas, position: Vector2(0, thickness), size: size, overridePaint: _outlinePaint);
      }
    }

    // 3. Das originale, unveränderte Sprite im Vordergrund zeichnen
    super.render(canvas);
  }
}
