import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:the_office/office_game.dart';

import '../hendrik.dart';

enum TriggerZoneDialogs { tooFar }

abstract class InteractiveObject extends PositionComponent
    with HasGameReference<OfficeGame>, HoverCallbacks, TapCallbacks, CollisionCallbacks {
  InteractiveObject({
    required super.position,
    required PositionComponent renderComponent,
    super.size,
    required this.displayName,
    this.priorityOffset = 0,
    this.interactionPadding = 5,
  }) : _renderComponent = renderComponent {
    add(renderComponent);
  }

  final PositionComponent _renderComponent;
  final String displayName;

  final int priorityOffset;
  final double interactionPadding;

  bool _playerInside = false;
  bool _isHovered = false;

  PositionComponent get renderComponent => _renderComponent;

  /// Der Mittelpunkt des tatsächlich gerenderten Sprites.
  ///
  /// Wichtig: Nicht [absoluteCenter] des Wrapper-Components verwenden,
  /// da Tiled-Sprites mit Anchor.center innerhalb des Wrappers liegen.
  Vector2 get interactionCenter => _renderComponent.absoluteCenter;

  void onAction();

  Map<String, Widget Function(BuildContext, Game)> get dialogs;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    anchor = Anchor.center;
    _renderComponent.anchor = Anchor.center;
    priority = y.toInt() + priorityOffset;

    // Diese Hitbox ist nur für die Spieler-Nähe/Kollision zuständig.
    // Sie liegt exakt über dem sichtbaren Sprite.
    add(
      RectangleHitbox(
        position: _renderComponent.position.clone(),
        size: _renderComponent.size + Vector2.all(interactionPadding * 2),
        anchor: _renderComponent.anchor,
        collisionType: CollisionType.passive,
      )..debugMode = false,
    );

    for (final MapEntry<String, Widget Function(BuildContext, Game)> entry in dialogs.entries) {
      game.overlays.addEntry(entry.key, entry.value);
    }
  }

  /// Flame nutzt für Tap- und Hover-Events nicht die Collision-Hitbox,
  /// sondern standardmäßig die Bounds des Parent-Components.
  ///
  /// Der Sprite ist bei uns aber relativ zum Parent verschoben. Deshalb
  /// berechnen wir hier explizit die sichtbare Rechteckfläche des Sprites.
  @override
  bool containsLocalPoint(Vector2 point) {
    final Vector2 center = _renderComponent.position;
    final Vector2 halfSize = _renderComponent.size / 2;

    return point.x >= center.x - halfSize.x - interactionPadding &&
        point.x <= center.x + halfSize.x + interactionPadding &&
        point.y >= center.y - halfSize.y - interactionPadding &&
        point.y <= center.y + halfSize.y + interactionPadding;
  }

  bool isInInteractionRange(Hendrik player) {
    if (_playerInside) {
      return true;
    }

    final double distance = player.absoluteCenter.distanceTo(interactionCenter);
    final double maxDistance = _renderComponent.size.length / 2 + interactionPadding;

    return distance <= maxDistance;
  }

  /// Gibt zurück, ob die Aktion tatsächlich ausgeführt wurde.
  bool tryInteract({bool showTooFar = true}) {
    final Hendrik player = game.player;

    if (!isInInteractionRange(player)) {
      if (showTooFar) {
        game.overlays.add(TriggerZoneDialogs.tooFar.toString());
      }

      // Klick auf ein Objekt – auch zu weit entfernt –
      // beendet die aktuell gehaltene Inventar-Auswahl.
      if (game.selectedItem != null) {
        game.resetSelection();
      }

      return false;
    }

    final bool usedInventoryItem = game.selectedItem != null;

    player.lookAt(interactionCenter);
    onAction();

    if (usedInventoryItem) {
      game.resetSelection();
    }

    return true;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (game.isTouchDevice) {
      game.setHighlightedObject(this);
      return;
    }

    tryInteract();
  }

  @override
  void onHoverEnter() {
    if (!game.isTouchDevice) {
      game.setHighlightedObject(this);
    }
  }

  @override
  void onHoverExit() {
    if (!game.isTouchDevice && game.highlightedObject == this) {
      game.setHighlightedObject(null);
    }
  }

  void setHighlighted(bool highlighted) {
    _isHovered = highlighted;
  }

  Sprite? _currentSprite() {
    final PositionComponent child = _renderComponent;

    if (child is SpriteComponent) {
      return child.sprite;
    }

    if (child is SpriteAnimationComponent) {
      return child.animationTicker?.getSprite();
    }

    if (child is SpriteAnimationGroupComponent) {
      return child.animationTicker?.getSprite();
    }

    return null;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (!_isHovered) {
      return;
    }

    final Sprite? sprite = _currentSprite();
    if (sprite == null) {
      return;
    }

    final Paint outlinePaint = Paint()
      ..colorFilter = const ColorFilter.mode(
        Color(0xFFFFFFAA),
        BlendMode.srcIn,
      );

    const List<Offset> offsets = <Offset>[
      Offset(-1, 0),
      Offset(1, 0),
      Offset(0, -1),
      Offset(0, 1),
    ];

    for (final Offset offset in offsets) {
      sprite.render(
        canvas,
        position: _renderComponent.position + Vector2(offset.dx, offset.dy),
        size: _renderComponent.size,
        anchor: _renderComponent.anchor,
        overridePaint: outlinePaint,
      );
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
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
}
