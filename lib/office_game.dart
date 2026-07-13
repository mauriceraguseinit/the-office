import 'package:flame/camera.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:the_office/tiled_map_loader.dart';
import 'package:the_office/utils/config.dart';

import 'hendrik.dart';
import 'hud/office_hud.dart';
import 'hud/speech_bubble.dart';
import 'interactiveObjects/interactive_object.dart';
import 'interactiveObjects/inventory_item_catalogue.dart';
import 'lighting_manager.dart';
import 'managers/game_state.dart';
import 'models/inventory_item.dart';

class OfficeGame extends FlameGame<World>
    with
        TiledMapLoader,
        ChangeNotifier,
        HasKeyboardHandlerComponents<World>,
        HasCollisionDetection<Broadphase<ShapeHitbox>>,
        MouseMovementDetector,
        SecondaryTapCallbacks,
        DragCallbacks,
        TapCallbacks,
        DoubleTapCallbacks {
  final GameState state = GameState();
  bool _isZoomedOut = false;
  final ChangeNotifier overlayChangeNotifier = ChangeNotifier();
  final double _normalZoom = 2.5;
  final double _mapViewZoom = 1.5;

  late OfficeHud hud;
  Vector2 mousePosition = Vector2.zero();

  // Convenience getters for GameState
  List<InventoryItem> get ownedItems => state.ownedItems;
  InventoryItem? get selectedItem => state.selectedItem;
  InteractiveObject? get highlightedObject => state.highlightedObject;
  bool get isDeskLocked => state.isDeskLocked;

  late Hendrik player;
  bool _mobileMovementArmed = false;
  bool _isExploring = false;
  bool get isTouchDevice {
    return defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
  }

  void setHighlightedObject(InteractiveObject? object) {
    if (state.highlightedObject == object) {
      return;
    }
    if (state.isPlayerHighlighted) {
      state.isPlayerHighlighted = false;
      player.setHighlighted(false);
    }
    state.highlightedObject?.setHighlighted(false);

    state.highlightedObject = object;
    state.highlightedObject?.setHighlighted(true);

    _refreshInteractionHint();
  }

  late TiledComponent<FlameGame<World>> mapComponent;
  void setPlayerHighlighted(bool highlighted) {
    if (state.isPlayerHighlighted == highlighted) {
      return;
    }

    state.isPlayerHighlighted = highlighted;
    player.setHighlighted(highlighted);

    // Wenn Hendrik hervorgehoben wird, darf nicht gleichzeitig
    // ein anderes Objekt als Ziel markiert sein.
    if (highlighted) {
      state.highlightedObject?.setHighlighted(false);
      state.highlightedObject = null;
    }

    _refreshInteractionHint();
  }

  void showPlayerMessage(String message) {
    state.setPlayerMessage(message);

    if (!overlays.isActive('playerMessage')) {
      overlays.add('playerMessage');
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    overlays.addEntry(
      TriggerZoneDialogs.tooFar.toString(),
      (BuildContext context, Game game) => RetroSpeechBubble(
        text: 'Dafür bin ich zu weit weg.',
        onClose: () => game.overlays.remove(TriggerZoneDialogs.tooFar.toString()),
      ),
    );
    overlays.addEntry(
      'playerMessage',
      (BuildContext context, Game game) => RetroSpeechBubble(
        text: state.playerMessage,
        onClose: () => game.overlays.remove('playerMessage'),
      ),
    );
    // 1. Assets vorab in den Cache laden
    await images.loadAll(<String>[
      'coffeeMachine.png',
      'mate_full.png',
      'mate_empty.png',
      'wall.png',
      'tobi_idle.png',
      'desk_daniel.png',
    ]);

    mapComponent = await TiledComponent.load('office.tmx', Vector2.all(64));
    final RenderableTiledMap tileMap = mapComponent.tileMap;

    // 2. Alle Tiled-Tilesets vorab laden
    for (final Tileset ts in tileMap.map.tilesets) {
      if (ts.image?.source != null) await images.load(ts.image!.source!);
      for (final Tile t in ts.tiles) {
        if (t.image?.source != null) await images.load(t.image!.source!);
      }
    }

    // --- MAP LADEN ÜBER MIXIN ---
    final (Hendrik loadedPlayer, List<Vector2> sources) = await loadTiledMap(world, mapComponent);
    player = loadedPlayer;

    overlays.add('intro');

    state.ownedItems.add(
      InventoryItemCatalogue.itemForId(InventoryItemType.mate),
    );

    //camera configuration
    camera.viewport = FixedResolutionViewport(
      resolution: Vector2(GameConfig.resolution.width, GameConfig.resolution.height),
    );
    camera.follow(player, snap: true);
    camera.viewfinder.zoom = 2.5;

    final CameraComponent rawMinimapCamera = CameraComponent(world: world);
    rawMinimapCamera.viewport = FixedResolutionViewport(
      resolution: Vector2(
        GameConfig.resolution.width,
        GameConfig.resolution.height,
      ),
    );
    rawMinimapCamera.viewfinder.zoom = 0.2;
    rawMinimapCamera.follow(player, snap: true);

    _buildHud(rawMinimapCamera);

    // build lights
    final LightingManager lighting = LightingManager(
      lightSources: sources,
      targetCamera: camera,
    )..priority = 999999;
    world.add(lighting);

    final LightingManager lighting2 = LightingManager(
      lightSources: sources,
      targetCamera: rawMinimapCamera,
    )..priority = 999999;
    world.add(lighting2);
  }

  bool _isInteractiveObjectAtCanvasPosition(Vector2 canvasPosition) {
    // Canvas-/Viewport-Koordinaten korrekt in Weltkoordinaten überführen.
    final Vector2 worldPosition = camera.globalToLocal(canvasPosition);

    return world.children.whereType<InteractiveObject>().any(
      (InteractiveObject object) => object.containsPoint(worldPosition),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    if (isTouchDevice) {
      return;
    }

    if (state.selectedItem == null) {
      return;
    }

    if (overlays.activeOverlays.isNotEmpty) {
      return;
    }

    // Item auf Tobi, Möbel usw. anwenden.
    if (_isInteractiveObjectAtCanvasPosition(event.canvasPosition)) {
      return;
    } // Item auf Hendrik anwenden.
    if (_isPlayerAtCanvasPosition(event.canvasPosition)) {
      player.useSelectedItemOnPlayer();
      return;
    }

    // Freie Fläche angeklickt: Auswahl abbrechen.
    resetSelection();
  }

  bool _isPlayerAtCanvasPosition(Vector2 canvasPosition) {
    final Vector2 worldPosition = camera.globalToLocal(canvasPosition);

    return player.containsPoint(worldPosition);
  }

  void _updateMobileExploration(Vector2 canvasPosition) {
    final Vector2 worldPosition = camera.globalToLocal(canvasPosition);

    InteractiveObject? objectUnderFinger;

    for (final InteractiveObject object in world.children.whereType<InteractiveObject>()) {
      if (object.containsPoint(worldPosition)) {
        objectUnderFinger = object;
        break;
      }
    }

    setHighlightedObject(objectUnderFinger);
  }

  bool tryInteractWithNearestObject() {
    final Iterable<InteractiveObject> interactiveObjects = world.children.whereType<InteractiveObject>();

    InteractiveObject? nearestObject;
    double nearestDistance = double.infinity;

    for (final InteractiveObject object in interactiveObjects) {
      if (!object.isInInteractionRange(player)) {
        continue;
      }

      final double distance = player.absoluteCenter.distanceTo(object.interactionCenter);

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

  @override
  void onMouseMove(PointerHoverInfo info) {
    super.onMouseMove(info);

    mousePositionWidget = camera.viewport.globalToLocal(
      info.eventPosition.widget,
    );
  }

  void selectItem(InventoryItem? item) {
    state.selectItem(item);
    _refreshInteractionHint();
    overlayChangeNotifier.notifyListeners();
  }

  void resetSelection() {
    state.resetSelection();
    _refreshInteractionHint();
    overlayChangeNotifier.notifyListeners();
  }

  String _buildInteractionHint() {
    final String objectName = state.isPlayerHighlighted
        ? 'Hendrik'
        : (state.highlightedObject?.displayName.trim() ?? '');
    final InventoryItem? item = state.selectedItem;

    // Inventar offen: nur Objektname (oder leer), kein Benutze-Text.
    if (overlays.isActive('inventory')) {
      return objectName;
    }

    if (item == null) return objectName;

    final String itemName = item.name.toUpperCase();
    if (objectName.isEmpty) return 'BENUTZE $itemName MIT...';
    return 'BENUTZE $itemName MIT ${objectName.toUpperCase()}';
  }

  void _refreshInteractionHint() {
    hud.updateInteractionHint(_buildInteractionHint());
  }

  @override
  void onSecondaryTapDown(SecondaryTapDownEvent event) {
    super.onSecondaryTapDown(event);
    resetSelection();
  }

  void toggleScreenLock() {
    state.toggleDeskLock();
    hud.updateStatusText(
      state.isDeskLocked ? 'PC-Status: SPERRT 🔒 (Sicher vor Kollegen)' : 'PC-Status: ENTSPERRT 🔓 (Kuchen-Gefahr!)',
    );
  }

  void _toggleCameraZoom() {
    _isZoomedOut = !_isZoomedOut;
    final double targetZoom = _isZoomedOut ? _mapViewZoom : _normalZoom;

    camera.viewfinder.removeAll(camera.viewfinder.children.whereType<ScaleEffect>());
    camera.viewfinder.add(
      ScaleEffect.to(Vector2.all(targetZoom), EffectController(duration: 0.4, curve: Curves.easeInOut)),
    );
  }

  void _buildHud(CameraComponent rawMinimapCamera) {
    hud = OfficeHud();
    camera.viewport.add(hud);
    hud.setupMinimap(rawMinimapCamera, _toggleCameraZoom);
  }

  // --- TOUCH / MAUS GEDRÜCKT HALTEN LOGIK (ECHTE BILDSCHIRMMITTE) ---

  void closeInventory() {
    overlays.remove('inventory');
    _refreshInteractionHint();
  }

  void openInventory() {
    overlays.add('inventory');
    _refreshInteractionHint();
  }

  Vector2 mousePositionWidget = Vector2.zero();
  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);

    // Desktop: bisheriges Verhalten unverändert.
    if (!isTouchDevice) {
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

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);

    // Desktop: bisheriges Verhalten unverändert.
    if (!isTouchDevice) {
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

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);

    player.stopTouchMovement();

    if (isTouchDevice && _isExploring) {
      setHighlightedObject(null);
    }

    _isExploring = false;

    // Ein Doppeltipp schaltet nur genau einen Bewegungs-Swipe frei.
    if (isTouchDevice) {
      _mobileMovementArmed = false;
    }
  }

  @override
  void onDoubleTapDown(DoubleTapDownEvent event) {
    super.onDoubleTapDown(event);

    if (!isTouchDevice || overlays.activeOverlays.isNotEmpty) {
      return;
    }

    // Der nächste Swipe ist Bewegung statt Erkundung.
    _mobileMovementArmed = true;
    _isExploring = false;

    // Alte Hervorhebung entfernen.
    setHighlightedObject(null);
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);

    player.stopTouchMovement();
    setHighlightedObject(null);

    _isExploring = false;
    _mobileMovementArmed = false;
  }

  void _handleTouchInput(Vector2 canvasPosition) {
    if (state.selectedItem != null) return;

    // 1. Die absolute, physikalische Mitte des Fensters/Bildschirms abgreifen
    final Vector2 screenCenter = canvasSize / 2;

    // 2. Richtung berechnen: Wo ist der Finger relativ zur Bildschirmmitte?
    final Vector2 direction = canvasPosition - screenCenter;

    // 3. Den reinen Richtungsvektor direkt an Hendrik übergeben
    player.updateTouchVelocity(direction);
  }
}
