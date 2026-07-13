import 'dart:math';

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
import 'package:the_office/utils/config.dart';
import 'package:the_office/utils/util.dart';

import 'hendrik.dart';
import 'hud/clickable_minimap.dart';
import 'hud/mobile_inventory_button.dart';
import 'hud/speech_bubble.dart';
import 'interactiveObjects/interactive_object.dart';
import 'interactiveObjects/interactive_objects_catalogue.dart';
import 'inventory_cursor.dart';
import 'lighting_manager.dart';
import 'models/inventory_item.dart';

class OfficeGame extends FlameGame<World>
    with
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

    highlightedObject?.setHighlighted(false);

    highlightedObject = object;
    highlightedObject?.setHighlighted(true);

    _refreshInteractionHint();
  }

  late ClickableMinimap minimap;
  late TiledComponent<FlameGame<World>> mapComponent;

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

    // --- BODEN MANUELL RENDERN ---
    final Layer? bodenLayer =
        tileMap.renderableLayers
                .where((dynamic layer) => layer.layer is TileLayer && layer.layer.name == 'Boden')
                .firstOrNull
                ?.layer
            as TileLayer?;

    if (bodenLayer != null) {
      final int mapWidth = tileMap.map.width;
      final int mapHeight = tileMap.map.height;

      for (int y = 0; y < mapHeight; y++) {
        for (int x = 0; x < mapWidth; x++) {
          final Gid? tileData = tileMap.getTileData(layerId: bodenLayer.id!, x: x, y: y);

          if (tileData != null && tileData.tile != 0) {
            final int gid = tileData.tile;
            final Tile? tileDefinition = tileMap.map.tileByGid(gid);
            final Tileset ts = tileMap.map.tilesetByTileGId(gid);

            if (tileDefinition == null) continue;

            final PositionComponent tileComponent;

            if (tileDefinition.animation.isNotEmpty) {
              final List<SpriteAnimationFrame> frames = <SpriteAnimationFrame>[];

              for (final Frame frame in tileDefinition.animation) {
                final int frameGid = ts.firstGid! + frame.tileId;

                final Tile? frameTile = tileMap.map.tileByGid(frameGid);
                if (frameTile == null) {
                  continue;
                }

                final Rectangle<num> frameRect = ts.computeDrawRect(frameTile);

                final Sprite frameSprite = Sprite(
                  images.fromCache((frameTile.image ?? ts.image)!.source!),
                  srcPosition: Vector2(
                    frameRect.left.toDouble(),
                    frameRect.top.toDouble(),
                  ),
                  srcSize: Vector2(
                    frameRect.width.toDouble(),
                    frameRect.height.toDouble(),
                  ),
                );

                frames.add(
                  SpriteAnimationFrame(
                    frameSprite,
                    frame.duration / 1000.0,
                  ),
                );
              }

              tileComponent = SpriteAnimationComponent(
                animation: SpriteAnimation(frames),
                position: Vector2(x * 64.0 + 32.0, y * 64.0 + 32.0),
                size: Vector2.all(64.0),
                anchor: Anchor.center,
                priority: -1000,
              );
            } else {
              final String imageSource = (tileDefinition.image ?? ts.image)!.source!;
              final Rectangle<num> rect = ts.computeDrawRect(tileDefinition);

              final Sprite sprite = Sprite(
                images.fromCache(imageSource),
                srcPosition: Vector2(
                  rect.left.toDouble(),
                  rect.top.toDouble(),
                ),
                srcSize: Vector2(
                  rect.width.toDouble(),
                  rect.height.toDouble(),
                ),
              );

              tileComponent = SpriteComponent(
                sprite: sprite,
                position: Vector2(x * 64.0 + 32.0, y * 64.0 + 32.0),
                size: Vector2.all(64.0),
                anchor: Anchor.center,
                priority: -1000,
              );
            }

            world.add(tileComponent);
          }
        }
      }
    }

    // --- KACHEL-LAYER (WÄNDE, MÖBEL ETC.) FÜR Y-SORTING VERARBEITEN ---
    final int totalMapLayers = tileMap.renderableLayers.length;

    for (int layerIndex = 0; layerIndex < totalMapLayers; layerIndex++) {
      final Layer layer = tileMap.renderableLayers[layerIndex].layer;

      if (layer is TileLayer && layer.name != 'Boden' && layer.visible) {
        final TileLayer tileLayer = layer;
        final int mapWidth = tileMap.map.width;
        final int mapHeight = tileMap.map.height;

        for (int y = 0; y < mapHeight; y++) {
          for (int x = 0; x < mapWidth; x++) {
            final Gid? tileData = tileMap.getTileData(layerId: tileLayer.id!, x: x, y: y);

            if (tileData != null && tileData.tile != 0) {
              final int gid = tileData.tile;
              final Tile? tileDefinition = tileMap.map.tileByGid(gid);
              final Tileset ts = tileMap.map.tilesetByTileGId(gid);

              if (tileDefinition == null) continue;

              final String imageSource = (tileDefinition.image ?? ts.image)!.source!;
              PositionComponent tileComponent;

              if (tileDefinition.animation.isNotEmpty) {
                final List<SpriteAnimationFrame> frames = <SpriteAnimationFrame>[];

                for (final Frame frame in tileDefinition.animation) {
                  final int targetGid = ts.firstGid! + frame.tileId;
                  Tile? frameTile = tileMap.map.tileByGid(targetGid);
                  frameTile ??= tileDefinition;

                  final Rectangle<num> frameRect = ts.computeDrawRect(frameTile);

                  final Sprite sprite = Sprite(
                    images.fromCache((frameTile.image ?? ts.image)!.source!),
                    srcPosition: Vector2(frameRect.left.toDouble(), frameRect.top.toDouble()),
                    srcSize: Vector2(frameRect.width.toDouble(), frameRect.height.toDouble()),
                  );

                  final double durationInSeconds = frame.duration / 1000.0;
                  frames.add(SpriteAnimationFrame(sprite, durationInSeconds));
                }

                tileComponent = SpriteAnimationComponent(
                  animation: SpriteAnimation(frames),
                  position: Vector2(x * 64.0 + 32.0, y * 64.0 + 32.0),
                  size: Vector2.all(64.0),
                  anchor: Anchor.center,
                  priority: (y * 64 + 64).toInt(),
                );
              } else {
                final Rectangle<num> rect = ts.computeDrawRect(tileDefinition);
                final Sprite sprite = Sprite(
                  images.fromCache(imageSource),
                  srcPosition: Vector2(rect.left.toDouble(), rect.top.toDouble()),
                  srcSize: Vector2(rect.width.toDouble(), rect.height.toDouble()),
                );

                tileComponent = SpriteComponent(
                  sprite: sprite,
                  position: Vector2(x * 64.0 + 32.0, y * 64.0 + 32.0),
                  size: Vector2.all(64.0),
                  anchor: Anchor.center,
                  priority: (y * 64 + 64).toInt(),
                );
              }

              final bool flipX = tileData.flips.horizontally;
              final bool flipY = tileData.flips.vertically;
              final bool flipDiag = tileData.flips.diagonally;

              if (flipDiag) {
                tileComponent.angle = Units.degree90;
                tileComponent.flipHorizontally();
              }
              if (flipX) tileComponent.flipHorizontally();
              if (flipY) tileComponent.flipVertically();

              world.add(tileComponent);

              final Tile? tileDefinitionForCollision = tileMap.map.tileByGid(gid);

              if (tileDefinitionForCollision != null && tileDefinitionForCollision.objectGroup != null) {
                final ObjectGroup objectGroup = tileDefinitionForCollision.objectGroup as ObjectGroup;
                final double tileX = x * 64.0;
                final double tileY = y * 64.0;

                for (final TiledObject tiledObject in objectGroup.objects) {
                  double objX = tiledObject.x;
                  double objY = tiledObject.y;
                  double objWidth = tiledObject.width;
                  double objHeight = tiledObject.height;

                  if (flipDiag) {
                    objX = 64.0 - tiledObject.y - tiledObject.height;
                    objY = tiledObject.x;
                    objWidth = tiledObject.height;
                    objHeight = tiledObject.width;
                  }

                  if (flipX && !flipDiag) objX = 64.0 - objX - objWidth;
                  if (flipY) objY = 64.0 - objY - objHeight;

                  final PositionComponent obstacle = PositionComponent(
                    position: Vector2(tileX + objX, tileY + objY),
                    size: Vector2(objWidth, objHeight),
                  )..add(RectangleHitbox());

                  obstacle.priority = 1;
                  world.add(obstacle..debugMode = false);
                }
              }
            }
          }
        }
      }
    }

    overlays.add('intro');

    ownedItems.add(
      InventoryItem(
        id: 'mate',
        name: 'Mate',
        assetPath: 'assets/images/mate_full.png',
        combinesWith: 'koffein_pulver',
        onCombineSuccess: (BuildContext context) {},
      ),
    );
    ownedItems.add(InventoryItem(id: 'mate_empty', name: 'leere Mate', assetPath: 'assets/images/mate_empty.png'));

    // collision objects layer
    final ObjectGroup? collisionLayer = mapComponent.tileMap.getLayer<ObjectGroup>('collision');
    collisionLayer?.objects.forEach((TiledObject object) {
      final PositionComponent staticObstacle = PositionComponent(
        position: Vector2(object.x, object.y),
        size: Vector2(object.width, object.height),
      )..add(RectangleHitbox()..debugMode = false);
      staticObstacle.priority = 1;
      world.add(staticObstacle..debugMode = false);
    });

    // interactive objects layers
    final ObjectGroup? interactiveObjects = mapComponent.tileMap.getLayer<ObjectGroup>('interactiveObjects');
    final ObjectGroup? interactiveObjects2 = mapComponent.tileMap.getLayer<ObjectGroup>('interactiveObjects2');
    interactiveObjects?.objects.forEach((TiledObject object) {
      _processInteractiveObject(object, tileMap, priorityOffset: 0);
    });

    interactiveObjects2?.objects.forEach((TiledObject object) {
      _processInteractiveObject(object, tileMap, priorityOffset: 100000);
    });

    // spawn points layer
    final ObjectGroup? spawnPoints = mapComponent.tileMap.getLayer<ObjectGroup>('spawnPoints');
    final TiledObject? playerObject = spawnPoints?.objects.firstWhere(
      (TiledObject element) => element.name == 'playerStart',
    );
    player = Hendrik(position: Vector2(playerObject?.x ?? 0, playerObject?.y ?? 0));
    world.add(player);

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
    final List<TiledObject> lightPoints =
        mapComponent.tileMap.getLayer<ObjectGroup>('lights')?.objects ?? <TiledObject>[];
    final List<Vector2> sources = lightPoints.map((TiledObject obj) => Vector2(obj.x, obj.y)).toList();
    if (sources.isEmpty) {
      debugPrint('⚠️  WARNUNG: Keine Lichter in Tiled gefunden! Nutze Fallback-Licht.');
      sources.add(Vector2(500, 500));
    }
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

    // Auf Mobile steuert der Entdeckungsmodus die Auswahl.
    if (isTouchDevice) {
      return;
    }

    // Ohne aktives Inventar-Item gibt es nichts zurückzusetzen.
    if (selectedItem == null) {
      return;
    }

    // Dialoge und Inventar dürfen die aktuelle Auswahl nicht beeinflussen.
    if (overlays.activeOverlays.isNotEmpty) {
      return;
    }

    // Beim Klick auf ein interaktives Objekt bleibt das Item aktiv.
    // Das Objekt verarbeitet den Klick dann über tryInteract()/onAction().
    if (_isInteractiveObjectAtCanvasPosition(event.canvasPosition)) {
      return;
    }

    // Klick auf freie Welt: Item ablegen bzw. Auswahl beenden.
    resetSelection();
  }

  void _processInteractiveObject(
    TiledObject object,
    RenderableTiledMap tileMap, {
    required int priorityOffset,
  }) {
    if (object.gid == null || object.gid! <= 0) return;

    final int cleanGid = object.gid! & 0x0FFFFFFF;
    final Tile? tile = tileMap.map.tileByGid(cleanGid);

    if (tile == null) return;

    final Vector2 objectSize = Vector2(object.width, object.height);
    final double angle = Units.radFromDegree(object.rotation);

    // 1. Die visuelle Komponente (Sprite oder Animation) vorbereiten
    final PositionComponent renderComp = _createRenderComponent(tile, tileMap, cleanGid, objectSize);

    // 2. Den Katalog delegieren lassen (er kümmert sich um NPCs vs. Objekte)
    final InteractiveObject? interactiveObject = InteractiveObjectsCatalogue.interactiveObjectForClassName(
      className: object.class_,
      displayName: object.name,
      renderComponent: renderComp,
      position: _getTiledObjectCenter(object: object, angle: angle),
      size: objectSize,
      priorityOffset: priorityOffset,
    );

    if (interactiveObject != null) {
      interactiveObject.angle = angle;
      world.add(interactiveObject);
    } else {
      // 3. Fallback: Nur als Deko/Hindernis hinzufügen, wenn es kein interaktives Objekt ist
      _setupAsDecoration(renderComp, object, angle, priorityOffset, cleanGid, tileMap);
    }
  }

  // Extrahiert aus deinem ursprünglichen Code die Erstellung des Sprites/der Animation
  PositionComponent _createRenderComponent(Tile tile, RenderableTiledMap tileMap, int cleanGid, Vector2 size) {
    if (tile.animation.isNotEmpty) {
      final List<SpriteAnimationFrame> frames = tile.animation.map((Frame frame) {
        final Tileset tileset = tileMap.map.tilesetByTileGId(cleanGid);
        final Tile? frameTile = tileMap.map.tileByGid(tileset.firstGid! + frame.tileId);
        final Tile targetTile = frameTile ?? tile;
        final Rectangle<num> rect = tileset.computeDrawRect(targetTile);
        return SpriteAnimationFrame(
          Sprite(
            images.fromCache((targetTile.image ?? tileset.image)!.source!),
            srcPosition: Vector2(rect.left.toDouble(), rect.top.toDouble()),
            srcSize: Vector2(rect.width.toDouble(), rect.height.toDouble()),
          ),
          frame.duration / 1000.0,
        );
      }).toList();

      return SpriteAnimationComponent(animation: SpriteAnimation(frames), size: size, anchor: Anchor.center);
    } else {
      final Tileset tileset = tileMap.map.tilesetByTileGId(cleanGid);
      final Rectangle<num> rect = tileset.computeDrawRect(tile);
      return SpriteComponent(
        sprite: Sprite(
          images.fromCache((tile.image ?? tileset.image)!.source!),
          srcPosition: Vector2(rect.left.toDouble(), rect.top.toDouble()),
          srcSize: Vector2(rect.width.toDouble(), rect.height.toDouble()),
        ),
        size: size,
        anchor: Anchor.center,
      );
    }
  }

  // Übernimmt die Deko-Logik (Kollisionen etc.)
  void _setupAsDecoration(
    PositionComponent renderComp,
    TiledObject object,
    double angle,
    int priorityOffset,
    int cleanGid,
    RenderableTiledMap tileMap,
  ) {
    renderComp
      ..anchor = Anchor.center
      ..position = Vector2(object.x, object.y)
      ..angle = angle
      ..priority = object.y.toInt() + priorityOffset;

    final Tile? tileForCollision = tileMap.map.tileByGid(cleanGid);
    if (tileForCollision?.objectGroup is ObjectGroup) {
      for (final TiledObject collisionObject in (tileForCollision!.objectGroup as ObjectGroup).objects) {
        renderComp.add(
          RectangleHitbox(
            position: Vector2(collisionObject.x, collisionObject.y),
            size: Vector2(collisionObject.width, collisionObject.height),
          ),
        );
      }
    }
    world.add(renderComp);
  }

  Vector2 _getTiledObjectCenter({
    required TiledObject object,
    required double angle,
  }) {
    // Der Mittelpunkt relativ zum in Tiled gespeicherten Ursprung.
    // width/height enthalten bereits die Objekt-Skalierung.
    final Vector2 localCenter = Vector2(
      object.width / 2,
      object.height / 2,
    );

    // Flame und Tiled verwenden beide Bildschirmkoordinaten:
    // X nach rechts, Y nach unten.
    final double cosA = cos(angle);
    final double sinA = sin(angle);

    final Vector2 rotatedCenter = Vector2(
      localCenter.x * cosA - localCenter.y * sinA,
      localCenter.x * sinA + localCenter.y * cosA,
    );

    return Vector2(
      object.x + rotatedCenter.x,
      object.y + rotatedCenter.y,
    );
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
    final String objectName = highlightedObject?.displayName.trim() ?? '';
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
    statusText = TextComponent<TextRenderer>(
      text: 'PC-Status: Entsperrt (Gefahr!)',
      position: Vector2(20, 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'PressStart2P',
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          shadows: <Shadow>[Shadow(color: Colors.black, offset: Offset(2.0, 2.0), blurRadius: 2.0)],
        ),
      ),
    );

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
