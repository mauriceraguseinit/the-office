import 'package:flame/camera.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/text.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:the_office/tiled_map_loader.dart';
import 'package:the_office/utils/config.dart';

import 'hendrik.dart';
import 'hud/clickable_minimap.dart';
import 'hud/mobile_inventory_button.dart';
import 'hud/speech_bubble.dart';
import 'interactiveObjects/interactive_object.dart';
import 'interactiveObjects/inventory_item_catalogue.dart';
import 'inventory_cursor.dart';
import 'lighting_manager.dart';
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
  bool _isZoomedOut = false;
  final ChangeNotifier overlayChangeNotifier = ChangeNotifier();
  final double _normalZoom = 2.5;
  final double _mapViewZoom = 1.5;

  late CameraComponent minimapCamera;
  late TextComponent<TextRenderer> interactionNameText;
  String _playerMessage = '';
  List<InventoryItem> ownedItems = <InventoryItem>[];
  InventoryItem? selectedItem;
  Vector2 mousePosition = Vector2.zero();
  late TextComponent<TextRenderer> statusText;
  bool isDeskLocked = false;
  late Hendrik player;
  InteractiveObject? highlightedObject;
  bool _mobileMovementArmed = false;
  bool _isExploring = false;
  bool get isTouchDevice {
    return defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
  }

  void setHighlightedObject(InteractiveObject? object) {
    if (highlightedObject == object) {
      return;
    }
    if (_isPlayerHighlighted) {
      _isPlayerHighlighted = false;
      player.setHighlighted(false);
    }
    highlightedObject?.setHighlighted(false);

    highlightedObject = object;
    highlightedObject?.setHighlighted(true);

    _refreshInteractionHint();
  }

  late ClickableMinimap minimap;
  late TiledComponent<FlameGame<World>> mapComponent;
  bool _isPlayerHighlighted = false;
  void setPlayerHighlighted(bool highlighted) {
    if (_isPlayerHighlighted == highlighted) {
      return;
    }

    _isPlayerHighlighted = highlighted;
    player.setHighlighted(highlighted);

    // Wenn Hendrik hervorgehoben wird, darf nicht gleichzeitig
    // ein anderes Objekt als Ziel markiert sein.
    if (highlighted) {
      highlightedObject?.setHighlighted(false);
      highlightedObject = null;
    }

    _refreshInteractionHint();
  }

  void showPlayerMessage(String message) {
    _playerMessage = message;

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
        text: _playerMessage,
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

    ownedItems.add(
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

    minimap = ClickableMinimap(
      minimapCamera: rawMinimapCamera,
      size: Vector2(200, 200),
      position: Vector2(
        GameConfig.resolution.width - 220,
        GameConfig.resolution.height - 220,
      ),
      onMinimapPressed: _toggleCameraZoom,
    );
    minimap.priority = 1000;
    camera.viewport.add(minimap);

    _buildHud();

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

    if (selectedItem == null) {
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
    selectedItem = item;
    _refreshInteractionHint();
    overlayChangeNotifier.notifyListeners();
  }

  void resetSelection() {
    selectedItem = null;
    _refreshInteractionHint();
    overlayChangeNotifier.notifyListeners();
  }

  String _buildInteractionHint() {
    final String objectName = _isPlayerHighlighted ? 'Hendrik' : (highlightedObject?.displayName.trim() ?? '');
    final InventoryItem? item = selectedItem;

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
    interactionNameText.text = _buildInteractionHint();
  }

  @override
  void onSecondaryTapDown(SecondaryTapDownEvent event) {
    super.onSecondaryTapDown(event);
    resetSelection();
  }

  void toggleScreenLock() {
    isDeskLocked = !isDeskLocked;
    statusText.text = isDeskLocked
        ? 'PC-Status: SPERRT 🔒 (Sicher vor Kollegen)'
        : 'PC-Status: ENTSPERRT 🔓 (Kuchen-Gefahr!)';
  }

  void _toggleCameraZoom() {
    _isZoomedOut = !_isZoomedOut;
    final double targetZoom = _isZoomedOut ? _mapViewZoom : _normalZoom;

    camera.viewfinder.removeAll(camera.viewfinder.children.whereType<ScaleEffect>());
    camera.viewfinder.add(
      ScaleEffect.to(Vector2.all(targetZoom), EffectController(duration: 0.4, curve: Curves.easeInOut)),
    );
  }

  void _buildHud() {
    // statusText = TextComponent<TextRenderer>(
    //   text: 'PC-Status: Entsperrt (Gefahr!)',
    //   position: Vector2(20, 20),
    //   textRenderer: TextPaint(
    //     style: const TextStyle(
    //       fontFamily: 'PressStart2P',
    //       color: Colors.white,
    //       fontSize: 24,
    //       fontWeight: FontWeight.bold,
    //       shadows: <Shadow>[Shadow(color: Colors.black, offset: Offset(2.0, 2.0), blurRadius: 2.0)],
    //     ),
    //   ),
    // );
    // camera.viewport.add(statusText..priority = 1000);
    final TextComponent<TextPaint> infoText = TextComponent<TextPaint>(
      text: 'BEWEGUNG: WASD / Touch (Gedrückthalten)\nAKTION: Taste E\nINVENTAR: Taste I',
      position: Vector2(20, 60),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.orange,
          fontFamily: 'PressStart2P',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          shadows: <Shadow>[Shadow(color: Colors.black, offset: Offset(2.0, 2.0), blurRadius: 2.0)],
        ),
      ),
    );

    camera.viewport.add(infoText..priority = 1000);
    camera.viewport.add(InventoryCursor());

    interactionNameText = TextComponent<TextRenderer>(
      text: '',
      position: Vector2(
        GameConfig.resolution.width / 2,
        GameConfig.resolution.height - 140,
      ),
      anchor: Anchor.center,
      priority: 1001,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'PressStart2P',
          color: Color(0xFFFFFFAA),
          fontSize: 18,
          fontWeight: FontWeight.bold,
          shadows: <Shadow>[
            Shadow(
              color: Colors.black,
              offset: Offset(2, 2),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );

    camera.viewport.add(interactionNameText);

    final MobileInventoryButton mobileBagButton = MobileInventoryButton(
      position: Vector2(GameConfig.resolution.width / 2, GameConfig.resolution.height - 80),
      onPressed: () {
        openInventory();
      },
    );

    camera.viewport.add(mobileBagButton..priority = 1000);
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
    if (selectedItem != null) return;

    // 1. Die absolute, physikalische Mitte des Fensters/Bildschirms abgreifen
    final Vector2 screenCenter = canvasSize / 2;

    // 2. Richtung berechnen: Wo ist der Finger relativ zur Bildschirmmitte?
    final Vector2 direction = canvasPosition - screenCenter;

    // 3. Den reinen Richtungsvektor direkt an Hendrik übergeben
    player.updateTouchVelocity(direction);
  }
}
