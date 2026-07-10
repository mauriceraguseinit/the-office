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
import 'package:flutter/material.dart';
import 'package:the_office/interactiveObjects/fridge.dart';
import 'package:the_office/interactiveObjects/toilet.dart';
import 'package:the_office/npcs/tobi.dart';
import 'package:the_office/trigger_zone.dart';
import 'package:the_office/utils/config.dart';
import 'package:the_office/utils/util.dart';

import 'hendrik.dart';
import 'hud/clickable_minimap.dart';
import 'interactiveObjects/coffee_machine.dart';
import 'inventory_cursor.dart';
import 'lighting_manager.dart';
import 'models/inventory_item.dart';
import 'npcs/desk_daniel.dart';

class OfficeGame extends FlameGame<World>
    with
        ChangeNotifier,
        HasKeyboardHandlerComponents<World>,
        HasCollisionDetection<Broadphase<ShapeHitbox>>,
        MouseMovementDetector,
        SecondaryTapCallbacks,
        DragCallbacks, // Ermöglicht das Gedrückthalten und Ziehen auf Touch/Maus
        TapCallbacks {
  bool _isZoomedOut = false;
  final double _normalZoom = 2.5;
  final double _mapViewZoom = 1.5;

  late CameraComponent minimapCamera;

  List<InventoryItem> ownedItems = <InventoryItem>[];
  InventoryItem? selectedItem;
  Vector2 mousePosition = Vector2.zero();
  late TextComponent<TextRenderer> statusText;
  bool isDeskLocked = false;
  late Hendrik player;
  late ClickableMinimap minimap;
  late TiledComponent<FlameGame<World>> mapComponent;

  final ChangeNotifier overlayChangeNotifier = ChangeNotifier();

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // 1. Assets vorab in den Cache laden
    await images.loadAll(<String>[
      'coffeeMachine.png',
      'mate_full.png',
      'mate_empty.png',
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

            final String imageSource = (tileDefinition.image ?? ts.image)!.source!;
            final Rectangle<num> rect = ts.computeDrawRect(tileDefinition);
            final Sprite sprite = Sprite(
              images.fromCache(imageSource),
              srcPosition: Vector2(rect.left.toDouble(), rect.top.toDouble()),
              srcSize: Vector2(rect.width.toDouble(), rect.height.toDouble()),
            );

            final SpriteComponent tileComponent = SpriteComponent(
              sprite: sprite,
              position: Vector2(x * 64.0, y * 64.0),
              size: Vector2.all(64.5),
              anchor: Anchor.topLeft,
              priority: -1000,
            );

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

    final ObjectGroup? spawnPoints = mapComponent.tileMap.getLayer<ObjectGroup>('spawnPoints');
    final ObjectGroup? interactiveObjects = mapComponent.tileMap.getLayer<ObjectGroup>('interactiveObjects');
    final ObjectGroup? interactiveObjects2 = mapComponent.tileMap.getLayer<ObjectGroup>('interactiveObjects2');

    final ObjectGroup? collisionLayer = mapComponent.tileMap.getLayer<ObjectGroup>('collision');
    collisionLayer?.objects.forEach((TiledObject object) {
      final PositionComponent staticobstacle = PositionComponent(
        position: Vector2(object.x, object.y),
        size: Vector2(object.width, object.height),
      )..add(RectangleHitbox()..debugMode = false);

      staticobstacle.priority = 1;
      world.add(staticobstacle..debugMode = false);
    });

    interactiveObjects?.objects.forEach((TiledObject object) {
      _processInteractiveObject(object, tileMap, priorityOffset: 0);
    });

    interactiveObjects2?.objects.forEach((TiledObject object) {
      _processInteractiveObject(object, tileMap, priorityOffset: 100000);
    });

    _buildNpcs(spawnPoints);

    final TiledObject? playerObject = spawnPoints?.objects.firstWhere(
      (TiledObject element) => element.name == 'playerStart',
    );

    player = Hendrik(position: Vector2(playerObject?.x ?? 0, playerObject?.y ?? 0));
    world.add(player);

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

    _buildHud(
      GameConfig.resolution.width,
      GameConfig.resolution.height,
    );

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

  void _processInteractiveObject(TiledObject object, RenderableTiledMap tileMap, {required int priorityOffset}) {
    if (object.gid == null || object.gid! <= 0) return;

    final int rawGid = object.gid!;
    final int cleanGid = rawGid & 0x0FFFFFFF;

    final Tile? tile = tileMap.map.tileByGid(cleanGid);
    if (tile == null) return;

    final Tileset ts = tileMap.map.tilesetByTileGId(cleanGid);
    final String imageSource = (tile.image ?? ts.image)!.source!;

    final Sprite tiledSprite = tile.image != null
        ? Sprite(images.fromCache(imageSource))
        : () {
            final Rectangle<num> rect = ts.computeDrawRect(tile);
            return Sprite(
              images.fromCache(imageSource),
              srcPosition: Vector2(rect.left.toDouble(), rect.top.toDouble()),
              srcSize: Vector2(rect.width.toDouble(), rect.height.toDouble()),
            );
          }();

    if (object.class_ == 'Toilet') {
      final Toilet toilet = Toilet(
        sprite: tiledSprite,
        position: Vector2(object.x, object.y),
        size: Vector2(object.size.x, object.size.y),
      );
      world.add(toilet);
      world.add(
        TriggerZone(target: toilet, onAction: () => overlays.add(ToiletDialogs.normalAction.toString()), padding: 5),
      );
      return;
    }

    if (object.class_ == 'Fridge') {
      final Fridge fridge = Fridge(
        sprite: tiledSprite,
        position: Vector2(object.x, object.y),
        size: Vector2(object.size.x, object.size.y),
      );
      world.add(fridge);
      world.add(
        TriggerZone(target: fridge, onAction: () => overlays.add(FridgeDialogs.normalAction.toString()), padding: 5),
      );
      return;
    }

    if (object.class_ == 'CoffeeMachine') {
      final CoffeeMachine coffeeMachine = CoffeeMachine(
        sprite: tiledSprite,
        position: Vector2(object.x, object.y),
        size: Vector2(object.size.x, object.size.y),
        priorityOffset: priorityOffset,
      );
      world.add(coffeeMachine);
      world.add(
        TriggerZone(
          target: coffeeMachine,
          onAction: () => overlays.add(CoffeeMachineDialogs.normalAction.toString()),
          padding: 5,
        ),
      );
      return;
    }

    final double angle = Units.radFromDegree(object.rotation);
    final Vector2 localCenter = Vector2(-object.width / 2, 0);

    final double cosA = cos(angle);
    final double sinA = sin(angle);
    final double rotatedX = localCenter.x * cosA - localCenter.y * sinA;
    final double rotatedY = localCenter.x * sinA + localCenter.y * cosA;

    final Vector2 centerPosition = Vector2(object.x + rotatedX, object.y + rotatedY);

    final SpriteComponent item = SpriteComponent(
      sprite: tiledSprite,
      position: centerPosition,
      size: Vector2(object.width, object.height),
      anchor: Anchor.center,
      angle: angle,
    );

    final bool flipX = (rawGid & 0x80000000) != 0;
    final bool flipY = (rawGid & 0x40000000) != 0;
    final bool flipDiag = (rawGid & 0x20000000) != 0;

    if (flipDiag) {
      item.angle += Units.degree90;
      item.flipHorizontally();
    }
    if (flipX) item.flipHorizontally();
    if (flipY) item.flipVertically();

    if (tile.objectGroup != null && tile.objectGroup is ObjectGroup) {
      final ObjectGroup objectGroup = tile.objectGroup as ObjectGroup;
      for (final TiledObject collisionObject in objectGroup.objects) {
        final RectangleHitbox hitbox = RectangleHitbox(
          position: Vector2(collisionObject.x, collisionObject.y),
          size: Vector2(collisionObject.width, collisionObject.height),
        );
        item.add(hitbox);
      }
    }

    item.priority = object.y.toInt() + priorityOffset;
    world.add(item);
  }

  @override
  void onMouseMove(PointerHoverInfo info) {
    super.onMouseMove(info);
    mousePosition = Vector2(info.raw.localPosition.dx, info.raw.localPosition.dy);
  }

  void selectItem(InventoryItem item) {
    selectedItem = item;
    overlayChangeNotifier.notifyListeners();
  }

  void resetSelection() {
    selectedItem = null;
    overlayChangeNotifier.notifyListeners();
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

  void _buildHud(double virtualWidth, double virtualHeight) {
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

    final _MobileInventoryButton mobileBagButton = _MobileInventoryButton(
      position: Vector2(virtualWidth / 2, virtualHeight - 80),
      onPressed: () {
        overlays.add('inventory');
      },
    );

    camera.viewport.add(mobileBagButton..priority = 1000);
  }

  void _buildNpcs(ObjectGroup? spawnPoints) {
    final TiledObject? positionTobi = spawnPoints?.objects.firstWhere((TiledObject element) => element.name == 'tobi');

    final Tobi tobiNpc = Tobi(
      position: Vector2(positionTobi?.x ?? 0, positionTobi?.y ?? 0),
      size: Vector2(Tobi.frameWidth * 0.13, Tobi.pngHeight * 0.13),
    );
    world.add(tobiNpc);

    final TriggerZone tobiTrigger = TriggerZone(
      target: tobiNpc,
      padding: 25.0,
      onAction: () => overlays.add(TobiDialogs.normalAction.toString()),
    );
    world.add(tobiTrigger);

    final TiledObject? positionDaniel = spawnPoints?.objects.firstWhere(
      (TiledObject element) => element.name == 'daniel',
    );

    final DeskDaniel deskTopRight = DeskDaniel(
      position: Vector2(positionDaniel?.x ?? 0, positionDaniel?.y ?? 0),
      size: Vector2(DeskDaniel.frameWidth * 0.24, DeskDaniel.pngHeight * 0.24),
    )..angle = Units.degree270;
    world.add(deskTopRight);

    final TriggerZone danielTrigger = TriggerZone(
      target: deskTopRight,
      padding: 35.0,
      onAction: () => overlays.add(DanielDialogs.normalAction.toString()),
    );
    world.add(danielTrigger);
  }

  // --- TOUCH / MAUS GEDRÜCKT HALTEN LOGIK (ECHTE BILDSCHIRMMITTE) ---

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _handleTouchInput(event.canvasPosition);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    _handleTouchInput(event.canvasEndPosition);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    player.stopTouchMovement();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    player.stopTouchMovement();
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

/// Ein reiner Touch-Button für die mobile Steuerung unten in der Mitte
/// Ein robuster Pixel-Look Touch-Button, der den Rucksack manuell zeichnet (kein Emoji-Fehler!)
/// Ein Button, der einen gefüllten Kreis als Hintergrund hat und das Rucksack-Sprite zentriert.
/// Ein Button im groben 8-Bit-Pixel-Stil (kantig, kein perfekter Kreis)
class _MobileInventoryButton extends PositionComponent with TapCallbacks {
  final VoidCallback _onPressed;

  _MobileInventoryButton({
    required super.position,
    required VoidCallback onPressed,
  }) : _onPressed = onPressed,
       super(size: Vector2(70, 70), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // Das Icon laden
    final sprite = await Sprite.load('backpack.png');
    add(
      SpriteComponent(
        sprite: sprite,
        size: Vector2(70, 70),
        anchor: Anchor.center,
        position: size / 2,
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    // 1. Hintergrund-Box (dunkles Anthrazit)
    final Paint bgPaint = Paint()..color = const Color(0xFF2C3E50);

    // 2. Rahmen-Paint (Weiß, Pixel-Stil)
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Wir zeichnen ein Quadrat mit einer kleinen "Einbuchtung" an den Ecken,
    // um den Pixel-Look zu erzeugen:
    final Rect rect = Rect.fromLTWH(0, 0, size.x, size.y);

    // Hintergrund zeichnen
    canvas.drawRect(rect, bgPaint);

    // Rahmen zeichnen (einfaches Quadrat wirkt hier pixeliger als ein Kreis)
    canvas.drawRect(rect.deflate(2), borderPaint);

    // Ecken "abrunden" durch Überzeichnen (Pixel-Art-Stil)
    final Paint clearPaint = Paint()
      ..color = const Color(0x00000000)
      ..blendMode = BlendMode.clear;
    canvas.drawRect(Rect.fromLTWH(0, 0, 4, 4), clearPaint); // Ecke oben links weg
    canvas.drawRect(Rect.fromLTWH(size.x - 4, 0, 4, 4), clearPaint); // Oben rechts
    canvas.drawRect(Rect.fromLTWH(0, size.y - 4, 4, 4), clearPaint); // Unten links
    canvas.drawRect(Rect.fromLTWH(size.x - 4, size.y - 4, 4, 4), clearPaint); // Unten rechts
  }

  @override
  void onTapDown(TapDownEvent event) => scale = Vector2.all(0.9);

  @override
  void onTapUp(TapUpEvent event) {
    scale = Vector2.all(1.0);
    _onPressed();
  }

  @override
  void onTapCancel(TapCancelEvent event) => scale = Vector2.all(1.0);
}
