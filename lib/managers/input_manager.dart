import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:the_office/interactiveObjects/interactive_object.dart';
import 'package:the_office/office_game.dart';

class InputManager {
  InputManager(this.game);
  final OfficeGame game;

  bool _mobileMovementArmed = false;
  bool _isExploring = false;

  void onTapDown(TapDownEvent event) {
    if (game.isTouchDevice) {
      return;
    }

    if (game.state.selectedItem == null) {
      return;
    }

    if (game.hasActiveBlockingOverlay) {
      return;
    }

    // Item auf Tobi, Möbel usw. anwenden.
    if (_isInteractiveObjectAtCanvasPosition(event.canvasPosition)) {
      return;
    }

    // Item auf Hendrik anwenden.
    if (_isPlayerAtCanvasPosition(event.canvasPosition)) {
      game.player.useSelectedItemOnPlayer();
      return;
    }

    // Freie Fläche angeklickt: Auswahl abbrechen.
    game.resetSelection();
  }

  void clearHoverTarget() {
    final InteractiveObject? previousObject = game.state.highlightedObject;

    if (previousObject != null) {
      previousObject.setHighlighted(false);
      game.state.highlightedObject = null;
    }

    if (game.state.isPlayerHighlighted) {
      game.state.isPlayerHighlighted = false;
      game.player.setHighlighted(false);
    }
  }

  void _updateDesktopHover(Vector2 worldPosition) {
    InteractiveObject? hoveredObject;

    // Falls sich mehrere Interaktionsflächen überlappen:
    // Das Objekt mit der höchsten Render-Priorität gewinnt.
    for (final InteractiveObject object in game.world.children.whereType<InteractiveObject>()) {
      if (!object.containsPoint(worldPosition)) {
        continue;
      }

      if (hoveredObject == null || object.priority >= hoveredObject.priority) {
        hoveredObject = object;
      }
    }

    // Interaktive Objekte haben Vorrang vor Hendrik.
    // Das ist sinnvoll, wenn Hendrik direkt neben oder vor einer Toilette,
    // einem Schreibtisch oder Tobi steht.
    if (hoveredObject != null) {
      game.setHighlightedObject(hoveredObject);
      return;
    }

    // Nur wenn kein interaktives Objekt getroffen wurde,
    // darf Hendrik das aktuelle Ziel sein.
    if (game.player.containsPoint(worldPosition)) {
      game.setPlayerHighlighted(true);
      return;
    }

    // Cursor ist auf freier Fläche.
    clearHoverTarget();
  }

  void onMouseMove(PointerHoverInfo info) {
    final Vector2 widgetPosition = info.eventPosition.widget;

    // Position für das am Cursor hängende Inventar-Item.
    game.mousePositionWidget = game.camera.viewport.globalToLocal(
      widgetPosition,
    );

    // Während Dialogen oder Inventar soll kein Ziel in der Welt leuchten.
    if (game.hasActiveBlockingOverlay) {
      clearHoverTarget();
      return;
    }

    // Die Mausposition aus dem Widget-/Canvas-Raum in Weltkoordinaten
    // umrechnen und bei jeder Mausbewegung das Ziel neu bestimmen.
    final Vector2 worldPosition = game.camera.globalToLocal(widgetPosition);

    _updateDesktopHover(worldPosition);
  }

  void onSecondaryTapDown(SecondaryTapDownEvent event) {
    game.resetSelection();
  }

  void onDragStart(DragStartEvent event) {
    // Desktop: bisheriges Verhalten unverändert.
    if (!game.isTouchDevice) {
      _handleTouchInput(event.canvasPosition);
      return;
    }

    // Mobile: Nach Doppeltipp bewegt der nächste Swipe Hendrik.
    if (_mobileMovementArmed) {
      _isExploring = false;
      _handleTouchInput(event.canvasPosition);
      return;
    }

    // Mobile: normaler Swipe ist der Entdeckungsmodus.
    _isExploring = true;
    _updateMobileExploration(event.canvasPosition);
  }

  void onDragUpdate(DragUpdateEvent event) {
    // Desktop: bisheriges Verhalten unverändert.
    if (!game.isTouchDevice) {
      _handleTouchInput(event.canvasEndPosition);
      return;
    }

    // Mobile: Nach Doppeltipp bewegt der Swipe Hendrik.
    if (_mobileMovementArmed) {
      _isExploring = false;
      _handleTouchInput(event.canvasEndPosition);
      return;
    }

    // Mobile: Finger bewegt sich über die Welt und markiert Objekte.
    _isExploring = true;
    _updateMobileExploration(event.canvasEndPosition);
  }

  void onDragEnd(DragEndEvent event) {
    game.player.stopTouchMovement();

    if (game.isTouchDevice && _isExploring) {
      game.setHighlightedObject(null);
    }

    _isExploring = false;

    // Ein Doppeltipp schaltet nur genau einen Bewegungs-Swipe frei.
    if (game.isTouchDevice) {
      _mobileMovementArmed = false;
    }
  }

  void onDoubleTapDown(DoubleTapDownEvent event) {
    if (!game.isTouchDevice || game.hasActiveBlockingOverlay) {
      return;
    }

    // Der nächste Swipe ist Bewegung statt Erkundung.
    _mobileMovementArmed = true;
    _isExploring = false;

    // Alte Hervorhebung entfernen.
    game.setHighlightedObject(null);
  }

  void onDragCancel(DragCancelEvent event) {
    game.player.stopTouchMovement();
    game.setHighlightedObject(null);

    _isExploring = false;
    _mobileMovementArmed = false;
  }

  bool tryInteractWithNearestObject() {
    final Iterable<InteractiveObject> interactiveObjects = game.world.children.whereType<InteractiveObject>();

    InteractiveObject? nearestObject;
    double nearestDistance = double.infinity;

    for (final InteractiveObject object in interactiveObjects) {
      if (!object.isInInteractionRange(game.player)) {
        continue;
      }

      final double distance = game.player.absoluteCenter.distanceTo(object.interactionCenter);

      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestObject = object;
      }
    }

    if (nearestObject == null) {
      return false;
    }

    nearestObject.tryInteract(showTooFar: false);
    return true;
  }

  void _handleTouchInput(Vector2 canvasPosition) {
    if (game.state.selectedItem != null) return;

    // 1. Die absolute, physikalische Mitte des Fensters/Bildschirms abgreifen
    final Vector2 screenCenter = game.canvasSize / 2;

    // 2. Richtung berechnen: Wo ist der Finger relativ zur Bildschirmmitte?
    final Vector2 direction = canvasPosition - screenCenter;

    // 3. Den reinen Richtungsvektor direkt an Hendrik übergeben
    game.player.updateTouchVelocity(direction);
  }

  void _updateMobileExploration(Vector2 canvasPosition) {
    final Vector2 worldPosition = game.camera.globalToLocal(canvasPosition);

    InteractiveObject? objectUnderFinger;

    for (final InteractiveObject object in game.world.children.whereType<InteractiveObject>()) {
      if (object.containsPoint(worldPosition)) {
        objectUnderFinger = object;
        break;
      }
    }

    game.setHighlightedObject(objectUnderFinger);
  }

  bool _isInteractiveObjectAtCanvasPosition(Vector2 canvasPosition) {
    // Canvas-/Viewport-Koordinaten korrekt in Weltkoordinaten überführen.
    final Vector2 worldPosition = game.camera.globalToLocal(canvasPosition);

    return game.world.children.whereType<InteractiveObject>().any(
      (InteractiveObject object) => object.containsPoint(worldPosition),
    );
  }

  bool _isPlayerAtCanvasPosition(Vector2 canvasPosition) {
    final Vector2 worldPosition = game.camera.globalToLocal(canvasPosition);

    return game.player.containsPoint(worldPosition);
  }
}
