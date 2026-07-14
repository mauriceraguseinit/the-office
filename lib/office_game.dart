import 'package:flame/camera.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:the_office/interactiveObjects/inventory_item_catalogue.dart';
import 'package:the_office/tiled_map_loader.dart';
import 'package:the_office/utils/assets.dart';
import 'package:the_office/utils/config.dart';

import 'hendrik.dart';
import 'hud/office_hud.dart';
import 'hud/speech_bubble.dart';
import 'interactiveObjects/interactive_object.dart';
import 'lighting_manager.dart';
import 'managers/audio_manager.dart';
import 'managers/game_state.dart';
import 'managers/input_manager.dart';
import 'managers/service_locator.dart';
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
  final GameState state = sl<GameState>();
  late final InputManager inputManager;
  bool _isZoomedOut = false;
  final ChangeNotifier overlayChangeNotifier = ChangeNotifier();
  final double _normalZoom = 2.5;
  final double _mapViewZoom = 1.5;
  AudioPlayer? _bgmPlayer;

  late OfficeHud hud;
  Vector2 mousePosition = Vector2.zero();

  // Convenience getters for GameState
  List<InventoryItem> get inventory => state.ownedItems;
  InventoryItem? get selectedItem => state.selectedItem;
  InteractiveObject? get highlightedObject => state.highlightedObject;
  bool get isDeskLocked => state.isDeskLocked;

  late Hendrik player;
  bool get isTouchDevice {
    return defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
  }

  void setHighlightedObject(InteractiveObject? object) {
    final bool playerWasHighlighted = state.isPlayerHighlighted;

    // Nur abbrechen, wenn wirklich bereits exakt dieses Objekt
    // aktiv ist UND Hendrik nicht noch markiert ist.
    if (state.highlightedObject == object && !playerWasHighlighted) {
      return;
    }

    // Hendrik immer deaktivieren, bevor ein Weltobjekt aktiv wird.
    if (playerWasHighlighted) {
      state.isPlayerHighlighted = false;
      player.setHighlighted(false);
    }

    final InteractiveObject? previousObject = state.highlightedObject;

    if (previousObject != object) {
      previousObject?.setHighlighted(false);

      state.highlightedObject = object;
      object?.setHighlighted(true);
    }
  }

  late TiledComponent<FlameGame<World>> mapComponent;
  void setPlayerHighlighted(bool highlighted) {
    final bool samePlayerState = state.isPlayerHighlighted == highlighted;
    final bool hasHighlightedObject = state.highlightedObject != null;

    // Nur beenden, wenn wirklich bereits genau derselbe Zustand aktiv ist.
    if (samePlayerState && !(highlighted && hasHighlightedObject)) {
      return;
    }

    if (highlighted) {
      // Beim Wechsel zu Hendrik muss ein altes Weltobjekt weg.
      state.highlightedObject?.setHighlighted(false);
      state.highlightedObject = null;
    }

    state.isPlayerHighlighted = highlighted;
    player.setHighlighted(highlighted);
  }

  void showPlayerMessage(String message) {
    state.setPlayerMessage(message);

    if (!overlays.isActive('playerMessage')) {
      overlays.add('playerMessage');
    }
  }

  @override
  Future<void> onLoad() async {
    registerGameInstance(this);
    inputManager = InputManager(this);
    super.onLoad();
    debugMode = false;
    _bgmPlayer = await sl<AudioManager>().playBgm(
      GameAudio.background,
      loop: true,
      volume: 0.05,
    );

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
    await images.loadAll(GameImages.preloadList);

    mapComponent = await TiledComponent.load(GameTiles.office, Vector2.all(64));
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

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    inputManager.onTapDown(event);
  }

  bool tryInteractWithNearestObject() => inputManager.tryInteractWithNearestObject();

  @override
  void onMouseMove(PointerHoverInfo info) {
    super.onMouseMove(info);
    inputManager.onMouseMove(info);
  }

  void selectItem(InventoryItem? item) {
    state.selectItem(item);
    overlayChangeNotifier.notifyListeners();
  }

  void resetSelection() {
    state.resetSelection();
    overlayChangeNotifier.notifyListeners();
  }

  @override
  void onSecondaryTapDown(SecondaryTapDownEvent event) {
    super.onSecondaryTapDown(event);
    resetSelection();
  }

  void toggleScreenLock() {
    state.toggleDeskLock();
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
  }

  void openInventory() {
    overlays.add('inventory');
  }

  Vector2 mousePositionWidget = Vector2.zero();
  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    inputManager.onDragStart(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    inputManager.onDragUpdate(event);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    inputManager.onDragEnd(event);
  }

  @override
  void onDoubleTapDown(DoubleTapDownEvent event) {
    super.onDoubleTapDown(event);

    // 1. Klick-Position von Bildschirm- in Weltkoordinaten umrechnen
    final Vector2 targetWorldPos = camera.globalToLocal(event.canvasPosition);

    // 2. Startpunkt sind Hendriks Füße
    final Vector2 playerFeet = Vector2(
      player.position.x,
      player.position.y + (player.size.y * 0.3), // 30% unter der Mitte statt 50%
    );

    // 3. Weg berechnen lassen
    final List<Vector2> path = findPath(playerFeet, targetWorldPos);

    if (path.isNotEmpty) {
      // 4. Hendrik den Pfad zuweisen!
      player.setAutoPath(path);
    } else {
      debugPrint('❌ Kein begehbarer Weg zu diesem Punkt gefunden!');
    }
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    inputManager.onDragCancel(event);
  }

  @override
  void onRemove() {
    _bgmPlayer?.stop();
    _bgmPlayer?.dispose();
    super.onRemove();
  }
}
