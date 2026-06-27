import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:the_office/hud/speech_bubble.dart';

import 'hendrik.dart';
import 'office_game.dart';

enum TriggerZoneDialogs { tooFar }

class TriggerZone extends PositionComponent with CollisionCallbacks, TapCallbacks, HasGameReference<OfficeGame> {
  final Map<String, OverlayWidgetBuilder<OfficeGame>> _dialogs = {
    TriggerZoneDialogs.tooFar.toString(): (context, OfficeGame game) => RetroSpeechBubble(
      text: 'Dafür bin ich zu weit weg.',
      onClose: () => game.overlays.remove(TriggerZoneDialogs.tooFar.toString()),
    ),
  };

  final PositionComponent target;
  final double padding;
  final VoidCallback onAction;

  bool _playerInside = false;

  TriggerZone({required this.target, required this.onAction, this.padding = 35.0});

  @override
  Future<void> onLoad() async {
    super.onLoad();

    debugMode = false;

    game.overlayBuilderMap?.addAll(_dialogs);

    final isRotated = target.angle == 1.5707963267948966 || target.angle == 4.71238898038469;

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
    final distance = (player.absoluteCenter - target.absoluteCenter).length;

    // Wir berechnen die maximale Reichweite (halbe Diagonale der Trigger-Zone)
    final maxAllowedDistance = size.length / 2;

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
    // Wir holen uns die Klick-Position in echten Bildschirm-Pixeln
    final screenPosition = event.canvasPosition;
    final gameSize = game.size;

    // Deine Minimap ist 200x200 Pixel groß und sitzt unten rechts mit 20px Abstand (220)
    final minimapLeft = gameSize.x - 220;
    final minimapTop = gameSize.y - 220;

    // Wenn der Klick innerhalb des Minimap-Quadrats gelandet ist, ignorieren wir ihn komplett!
    if (screenPosition.x >= minimapLeft && screenPosition.y >= minimapTop) {
      return;
    }
    // --- MINIMAP SCHUTZSCHILD ENDE ---

    // Dein bestehender Code:
    final distance = game.player.absoluteCenter.distanceTo(absoluteCenter);
    if (distance > 120) {
      game.overlays.add(TriggerZoneDialogs.tooFar.toString());
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
        final group = this as SpriteAnimationGroupComponent;
        final currentAnim = group.animations?[group.current];
        if (currentAnim != null) {
          final ticker = group.animationTickers?[group.current];
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
