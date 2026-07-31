import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:the_office/office_game.dart';

import '../hendrik.dart';
import '../models/interaction_system.dart';

enum TriggerZoneDialogs { tooFar }

abstract class InteractiveObject extends PositionComponent
    with HasGameReference<OfficeGame>, TapCallbacks, CollisionCallbacks {
  InteractiveObject({
    required super.position,
    required PositionComponent renderComponent,
    super.size,
    required this.displayName,
    this.priorityOffset = 0,
    this.interactionPadding = 10,
  }) : _renderComponent = renderComponent {
    add(renderComponent);
  }

  final PositionComponent _renderComponent;
  final String displayName;

  OfficeGame get officeGame => game;

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

  List<InteractionRule> get rules => <InteractionRule>[];

  void onAction() {
    // Nachricht vor der Ausführung leeren und Overlay schließen
    officeGame.overlays.remove('playerMessage');
    officeGame.state.setPlayerMessage('');

    final InteractionRule activeRule = rules.firstWhere(
      (InteractionRule rule) => rule.canExecute(officeGame.state, officeGame.selectedItem),
      orElse: () => InteractionRule(
        actions: <GameAction>[
          ShowMessageAction('Ich weiß nicht, was ich damit tun soll.'),
        ],
      ),
    );

    activeRule.execute(officeGame.state);

    // Spezial-Aktionen behandeln
    for (final GameAction action in activeRule.actions) {
      if (action is AddItemAction) {
        officeGame.playAddItemAnimation(
          item: action.item,
          startWorldPosition: interactionCenter,
        );
      } else if (action is PeeAction) {
        officeGame.player.startPeeing(interactionCenter);
      } else if (action is RemoveObjectAction) {
        removeFromParent();
      }
    }

    if (officeGame.state.playerMessage.isNotEmpty) {
      officeGame.showPlayerMessage(officeGame.state.playerMessage);
    }

    if (activeRule.overlayToOpen != null) {
      officeGame.openOverlay(activeRule.overlayToOpen!);
    }
  }

  Map<String, Widget Function(BuildContext, Game)> get dialogs => <String, Widget Function(BuildContext, Game)>{};

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    anchor = Anchor.center;
    _renderComponent
      ..anchor = Anchor.center
      ..position = size / 2;

    priority = y.toInt() + priorityOffset;

    add(
      _InteractionZone(
        position: _renderComponent.position.clone(),
        size: _renderComponent.size + Vector2.all(interactionPadding * 2),
        anchor: _renderComponent.anchor,
        onPlayerEnter: () => _playerInside = true,
        onPlayerLeave: () => _playerInside = false,
      )..debugMode = false,
    );

    for (final MapEntry<String, Widget Function(BuildContext, Game)> entry in dialogs.entries) {
      game.overlays.addEntry(entry.key, entry.value);
    }
  }

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

  bool tryInteract({bool showTooFar = true}) {
    final Hendrik player = game.player;

    if (!isInInteractionRange(player)) {
      if (showTooFar) {
        game.openOverlay(TriggerZoneDialogs.tooFar.toString());
      }

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
      tryInteract();
      return;
    }

    tryInteract();
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
  void onRemove() {
    game.removeInteractiveObjectFromNavMesh(this);
    super.onRemove();
  }
}

/// Hilfsklasse für die Interaktions-Zone.
/// Sie dient nur dazu, Hendrik zu erkennen, ohne ihn physikalisch zu blockieren.
class _InteractionZone extends PositionComponent with CollisionCallbacks {
  _InteractionZone({
    required super.position,
    required super.size,
    required super.anchor,
    required this.onPlayerEnter,
    required this.onPlayerLeave,
  });

  final VoidCallback onPlayerEnter;
  final VoidCallback onPlayerLeave;

  @override
  Future<void> onLoad() async {
    add(
      RectangleHitbox(
        collisionType: CollisionType.passive,
      ),
    );
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Hendrik) {
      onPlayerEnter();
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is Hendrik) {
      onPlayerLeave();
    }
  }
}
