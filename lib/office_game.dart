import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:the_office/interactiveObjects/toilet.dart';
import 'package:the_office/npcs/tobi.dart';
import 'package:the_office/trigger_zone.dart';
import 'package:the_office/utils/map_splitter.dart';
import 'package:the_office/utils/util.dart';

import 'hendrik.dart';
import 'hud/clickable_minimap.dart';
import 'hud/inventory_overlay.dart';
import 'hud/speech_bubble.dart';
import 'inventory_cursor.dart';
import 'lighting_manager.dart';
import 'models/inventory_item.dart';
import 'npcs/desk_daniel.dart';

class OfficeGame extends FlameGame
    with
        ChangeNotifier,
        HasKeyboardHandlerComponents,
        HasCollisionDetection,
        MouseMovementDetector,
        SecondaryTapCallbacks {
  bool _isZoomedOut = false;
  final double _normalZoom = 2.5; // Deine aktuelle Zoomstufe
  final double _mapViewZoom = 1.5; // Die herausgezoomte Übersicht

  late CameraComponent minimapCamera;

  List<InventoryItem> ownedItems = [];
  InventoryItem? selectedItem;
  Vector2 mousePosition = Vector2.zero();
  late TextComponent statusText;
  bool isDeskLocked = false;
  late Hendrik player;
  late ClickableMinimap minimap;
  late TiledComponent mapComponent;

  final ChangeNotifier overlayChangeNotifier = ChangeNotifier();

  Map<String, OverlayWidgetBuilder<OfficeGame>>? overlayBuilderMap = {
    'inventory': (context, OfficeGame game) => InventoryOverlay(game: game),
    'intro': (context, OfficeGame game) => RetroSpeechBubble(
      actions: [RetroAction(title: 'Starten', onTap: () => game.overlays.remove('intro'))],
      text:
          'Willkommen im Büro.\n\nHente wird es wieder sehr heiß!!! Also hol dir ne kalte Mate aus dem Kühlschrank und fang an zu arbeiten.\n\nDas Jira Board mit deinen Aufgaben kannst du dir an deinem PC aufrufen.',
      onClose: () => game.overlays.remove('intro'),
    ),
  };

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // 1. Map ganz normal laden und als EINZIGES Objekt zur World hinzufügen
    mapComponent = await TiledComponent.load('office.tmx', Vector2.all(64));
    // world.add(mapComponent);

    final List<TiledComponent> mapLayers = await MapSplitter.splitMapIntoLayers(
      fileName: 'office.tmx',
      destTileSize: Vector2.all(64),
    );

    // Wir fügen NUR den Boden als statischen Layer im Hintergrund hinzu
    for (final layerComponent in mapLayers) {
      final isBoden = layerComponent.tileMap.renderableLayers.any((rl) => rl.layer.name == 'Boden' && rl.layer.visible);
      if (isBoden) {
        layerComponent.priority = -1000;
        world.add(layerComponent);
      }
    }

    final tileMap = mapComponent.tileMap;

    // 0. Alle Tileset-Bilder vorab laden, damit wir sie synchron für Sprites nutzen können
    for (final ts in tileMap.map.tilesets) {
      if (ts.image?.source != null) await images.load(ts.image!.source!);
      for (final t in ts.tiles) {
        if (t.image?.source != null) await images.load(t.image!.source!);
      }
    }

    // 2. Schleife: Alle anderen Kachel-Layer (Wände, Möbel etc.) für Y-Sorting verarbeiten
    for (final renderableLayer in tileMap.renderableLayers) {
      final layer = renderableLayer.layer;

      if (layer is TileLayer && layer.name != 'Boden' && layer.visible) {
        final tileLayer = layer;
        final mapWidth = tileMap.map.width;
        final mapHeight = tileMap.map.height;

        for (int y = 0; y < mapHeight; y++) {
          for (int x = 0; x < mapWidth; x++) {
            final tileData = tileMap.getTileData(layerId: tileLayer.id!, x: x, y: y);

            if (tileData != null && tileData.tile != 0) {
              final gid = tileData.tile;

              // 1. Hole die Definitionen aus der Map
              final tileDefinition = tileMap.map.tileByGid(gid);
              final ts = tileMap.map.tilesetByTileGId(gid);

              if (tileDefinition == null) continue;

              final imageSource = (tileDefinition.image ?? ts.image)!.source!;
              PositionComponent tileComponent;

              // 2. PRÜFEN: Hat dieses Tile eine Tiled-Animation?
              if (tileDefinition.animation.isNotEmpty) {
                final List<SpriteAnimationFrame> frames = [];

                for (final frame in tileDefinition.animation) {
                  // Berechne die Ziel-ID
                  final targetGid = ts.firstGid! + frame.tileId;

                  // Sicher abfragen, ohne den Absturz mit '!' zu erzwingen
                  var frameTile = tileMap.map.tileByGid(targetGid);

                  // 🔥 DER FALLBACK: Falls Tiled die ID beim Speichern weggeschnitten hat,
                  // nutzen wir einfach das Haupt-Tile als Platzhalter. Das verhindert den Absturz!
                  frameTile ??= tileDefinition;

                  final frameRect = ts.computeDrawRect(frameTile);

                  final sprite = Sprite(
                    images.fromCache((frameTile.image ?? ts.image)!.source!),
                    srcPosition: Vector2(frameRect.left.toDouble(), frameRect.top.toDouble()),
                    srcSize: Vector2(frameRect.width.toDouble(), frameRect.height.toDouble()),
                  );

                  // Dauer von Millisekunden in Sekunden umrechnen
                  final double durationInSeconds = frame.duration / 1000.0;
                  frames.add(SpriteAnimationFrame(sprite, durationInSeconds));
                }

                // Animierte Komponente erstellen
                tileComponent = SpriteAnimationComponent(
                  animation: SpriteAnimation(frames), // Nutzt direkt deine fertige Liste!
                  position: Vector2(x * 64.0 + 32.0, y * 64.0 + 32.0),
                  size: Vector2.all(64.0),
                  anchor: Anchor.center,
                  priority: (y * 64 + 64).toInt(),
                );
              } else {
                // STATISCHES FALLBACK: Normales Sprite erstellen, wenn keine Animation existiert
                final rect = ts.computeDrawRect(tileDefinition);
                final sprite = Sprite(
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

              // Rotations- und Spiegelungszustände aus tileData auslesen
              final bool flipX = tileData.flips.horizontally;
              final bool flipY = tileData.flips.vertically;
              final bool flipDiag = tileData.flips.diagonally;

              // Tiled Rotations-Logik anwenden (Z-Taste im Editor)
              if (flipDiag) {
                tileComponent.angle = Units.degree90;
                tileComponent.flipHorizontally();
              }
              if (flipX) tileComponent.flipHorizontally();
              if (flipY) tileComponent.flipVertically();

              // Kachel der Spielwelt hinzufügen
              world.add(tileComponent);

              // KOLLISION:
              final tileDefinitionForCollision = tileMap.map.tileByGid(gid);

              if (tileDefinitionForCollision != null && tileDefinitionForCollision.objectGroup != null) {
                final objectGroup = tileDefinitionForCollision.objectGroup as ObjectGroup;

                final tileX = x * 64.0;
                final tileY = y * 64.0;

                for (final tiledObject in objectGroup.objects) {
                  double objX = tiledObject.x;
                  double objY = tiledObject.y;
                  double objWidth = tiledObject.width;
                  double objHeight = tiledObject.height;

                  // Wenn die Kachel im Editor mit 'Z' rotiert wurde:
                  if (flipDiag) {
                    objX = 64.0 - tiledObject.y - tiledObject.height;
                    objY = tiledObject.x;

                    // Breite und Höhe tauschen durch die Drehung
                    objWidth = tiledObject.height;
                    objHeight = tiledObject.width;
                  }

                  // Zusätzliche Spiegelungen abfangen
                  if (flipX && !flipDiag) objX = 64.0 - objX - objWidth;
                  if (flipY) objY = 64.0 - objY - objHeight;

                  final obstacle = PositionComponent(
                    position: Vector2(tileX + objX, tileY + objY),
                    size: Vector2(objWidth, objHeight),
                  )..add(RectangleHitbox());

                  // Hitboxen bekommen eine feste Priorität über dem Boden
                  obstacle.priority = 1;
                  world.add(obstacle..debugMode = false);
                }
              }
            }
          }
        }
      }
    }

    ////// Ab hier folgt dein restlicher Code (Overlays, Items, Player-Spawn...)
    overlays.add('intro');

    ownedItems.add(
      InventoryItem(
        id: 'mate',
        name: 'Mate',
        assetPath: 'assets/images/mate_full.png',
        combinesWith: 'koffein_pulver',
        onCombineSuccess: (context) {},
      ),
    );
    ownedItems.add(InventoryItem(id: 'mate_empty', name: 'leere Mate', assetPath: 'assets/images/mate_empty.png'));

    final spawnPoints = mapComponent.tileMap.getLayer<ObjectGroup>('spawnPoints');
    final interactiveObjects = mapComponent.tileMap.getLayer<ObjectGroup>('interactiveObjects');

    interactiveObjects?.objects.forEach((object) {
      if (object.class_ == 'Toilet') {
        final Toilet toilet = Toilet(
          position: Vector2(object.x, object.y),
          size: Vector2(object.size.x, object.size.y),
        );
        world.add(toilet);
        world.add(
          TriggerZone(target: toilet, onAction: () => overlays.add(ToiletDialogs.normalAction.toString()), padding: 5),
        );
      } else if (object.gid != null && object.gid! > 0) {
        final rawGid = object.gid!;
        final cleanGid = rawGid & 0x0FFFFFFF;

        final tile = tileMap.map.tileByGid(cleanGid);
        if (tile == null) return;

        final ts = tileMap.map.tilesetByTileGId(cleanGid);
        if (ts == null) return;

        final imageSource = (tile.image ?? ts.image)!.source!;

        final sprite = tile.image != null
            ? Sprite(images.fromCache(imageSource))
            : () {
                final rect = ts.computeDrawRect(tile);
                return Sprite(
                  images.fromCache(imageSource),
                  srcPosition: Vector2(rect.left.toDouble(), rect.top.toDouble()),
                  srcSize: Vector2(rect.width.toDouble(), rect.height.toDouble()),
                );
              }();

        // 🔥 HIER IST DIE BRUTAL PRÄZISE ROTATIONS-BERECHNUNG:
        final double angle = Units.radFromDegree(object.rotation);

        // Vektor vom Tiled-Pivotpunkt (unten rechts) zur unrotierten Objektmitte:
        // Da der Pivot unten rechts ist, müssen wir nach links (-width/2) und hoch (-height/2) zur Mitte wandern.
        final localCenter = Vector2(-object.width / 2, 0);
        // HINWEIS: Falls ein paar Objekte im Editor doch "bottomLeft" waren, kannst du stattdessen das hier nehmen:
        // final localCenter = Vector2(object.width / 2, -object.height / 2);

        // Wir rotieren diesen Richtungsvektor im Raum mit einer Drehmatrix (Clockwise für Screen-Space)
        final double cosA = cos(angle);
        final double sinA = sin(angle);
        final double rotatedX = localCenter.x * cosA - localCenter.y * sinA;
        final double rotatedY = localCenter.x * sinA + localCenter.y * cosA;

        // Die exakte, mitgeschwungene Center-Position in der Spielwelt
        final centerPosition = Vector2(object.x + rotatedX, object.y + rotatedY);

        final item = SpriteComponent(
          sprite: sprite,
          position: centerPosition, // Nutzt die dynamische Mitte
          size: Vector2(object.width, object.height),
          anchor: Anchor.center, // Bleibt Center, damit Flipping fehlerfrei klappt
          angle: angle,
        );

        // Spiegelungen anwenden (Passiert nun perfekt in-place)
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
          final objectGroup = tile.objectGroup as ObjectGroup;
          for (final collisionObject in objectGroup.objects) {
            // Flame's RectangleHitbox übernimmt automatisch die lokale Position und Größe
            final hitbox = RectangleHitbox(
              position: Vector2(collisionObject.x, collisionObject.y),
              size: Vector2(collisionObject.width, collisionObject.height),
            );

            // Optional: Wenn du visuell im Debug-Modus sehen willst, ob sie richtig sitzen:
            // hitbox.renderShape = true;

            item.add(hitbox);
          }
        } else {
          // Fallback: Falls in Tiled keine Box definiert wurde,
          // machen wir einfach das gesamte Objekt solide.
          item.add(RectangleHitbox());
        }

        // Für das Y-Sorting rechnen wir die echte Unterkante des Objekts im Raum aus
        item.priority = object.y.toInt();

        world.add(item);
      }
    });

    _buildNpcs(spawnPoints);

    // Spawnpoint auslesen
    TiledObject? playerObject = spawnPoints?.objects.firstWhere((element) => element.name == 'playerStart');

    // Spieler erstellen
    player = Hendrik(position: Vector2(playerObject?.x ?? 0, playerObject?.y ?? 0));
    // player.priority wird dynamisch in Hendrik.update gesetzt

    world.add(player);

    // Kamera folgt dem Spieler
    camera.follow(player, snap: true);
    camera.viewfinder.zoom = 2.5;

    final rawMinimapCamera = CameraComponent(world: world);
    rawMinimapCamera.viewfinder.zoom = 0.2;
    rawMinimapCamera.follow(player, snap: true);

    minimap = ClickableMinimap(
      minimapCamera: rawMinimapCamera,
      size: Vector2(200, 200),
      position: Vector2(size.x - 220, size.y - 220),
      onMinimapPressed: _toggleCameraZoom,
    );
    minimap.priority = 1000;
    camera.viewport.add(minimap);

    _buildHud();

    // --- LIGHTING SYSTEM ---
    final lightPoints = mapComponent.tileMap.getLayer<ObjectGroup>('lights')?.objects ?? [];
    final shadowObjects = mapComponent.tileMap.getLayer<ObjectGroup>('shadowCast')?.objects ?? [];

    final sources = lightPoints.map((obj) => Vector2(obj.x, obj.y)).toList();

    if (sources.isEmpty) {
      print('⚠️  WARNUNG: Keine Lichter in Tiled gefunden! Nutze Fallback-Licht.');
      sources.add(Vector2(500, 500));
    }

    final lighting = LightingManager(lightSources: sources, targetCamera: camera)..priority = 500;
    camera.viewport.add(lighting);

    final lighting2 = LightingManager(lightSources: sources, targetCamera: rawMinimapCamera)..priority = 500;
    rawMinimapCamera.viewport.add(lighting2);
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    try {
      minimap.position = Vector2(newSize.x - 220, newSize.y - 220);
    } catch (_) {}
  }

  @override
  void onMouseMove(PointerHoverInfo info) {
    super.onMouseMove(info);
    // Wir holen uns die exakten Pixel-Koordinaten direkt aus Flutter.
    // Das klappt garantiert in jeder Flame-Version!
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
    resetSelection(); // Löscht die Auswahl sofort bei Rechtsklick
  }

  // Methode um den PC-Status zu toggeln
  void toggleScreenLock() {
    isDeskLocked = !isDeskLocked;
    if (isDeskLocked) {
      statusText.text = 'PC-Status: SPERRT 🔒 (Sicher vor Kollegen)';
    } else {
      statusText.text = 'PC-Status: ENTSPERRT 🔓 (Kuchen-Gefahr!)';
    }
  }

  void _toggleCameraZoom() {
    _isZoomedOut = !_isZoomedOut;
    final targetZoom = _isZoomedOut ? _mapViewZoom : _normalZoom;

    // Vorherige Skalierungs-Effekte vom Viewfinder entfernen
    camera.viewfinder.removeAll(camera.viewfinder.children.whereType<ScaleEffect>());

    // Da Zoom im Viewfinder über das 'scale'-Property gesteuert wird,
    // übergeben wir den Zielwert als Vector2(zoom, zoom)
    camera.viewfinder.add(
      ScaleEffect.to(
        Vector2.all(targetZoom),
        EffectController(
          duration: 0.4, // Animationsdauer in Sekunden
          curve: Curves.easeInOut, // Sanfter Übergang
        ),
      ),
    );
  }

  void _buildHud() {
    // 4. UI-Texte erstellen
    statusText = TextComponent(
      text: 'PC-Status: Entsperrt (Gefahr!)',
      position: Vector2(20, 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black, // Dunkler Schatten für maximalen Kontrast
              offset: Offset(2.0, 2.0), // Versatz um 2 Pixel nach rechts und unten
              blurRadius: 2.0, // Leicht weichgezeichnete Kante
            ),
          ],
        ),
      ),
    );

    final infoText = TextComponent(
      text: 'BEWEGUNG: WASD/Pfeiltasten | LEERTASTE: PC Sperren/Entsperren\nAKTION: Taste E\nINVENTAR: Taste I',
      position: Vector2(20, 60),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.orange,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          // HIER FÜGEN WIR DIE SCHATTEN HINZU:
          shadows: [
            Shadow(
              color: Colors.black, // Dunkler Schatten für maximalen Kontrast
              offset: Offset(2.0, 2.0), // Versatz um 2 Pixel nach rechts und unten
              blurRadius: 2.0, // Leicht weichgezeichnete Kante
            ),
          ],
        ),
      ),
    );

    // WICHTIG: Die Texte werden jetzt an das VIEWPORT der Kamera gehängt!
    // Dadurch wandern sie garantiert in den absoluten Vordergrund (HUD)
    // camera.viewport.add(statusText);
    camera.viewport.add(infoText..priority = 1000);
    camera.viewport.add(InventoryCursor());
  }

  void _buildNpcs(ObjectGroup? spawnPoints) {
    TiledObject? positionTobi = spawnPoints?.objects.firstWhere((element) => element.name == 'tobi');

    // 1. Tobi ganz normal erstellen und zur World hinzufügen
    final tobiNpc = Tobi(
      position: Vector2(positionTobi?.x ?? 0, positionTobi?.y ?? 0),
      size: Vector2(Tobi.frameWidth * 0.13, Tobi.pngHeight * 0.13),
    );
    world.add(tobiNpc);

    // TriggerZone als eigenständiges Objekt in die World legen
    final tobiTrigger = TriggerZone(
      target: tobiNpc,
      padding: 25.0,
      onAction: () {
        overlays.add(TobiDialogs.normalAction.toString());
      },
    );
    world.add(tobiTrigger);

    // 2. Daniels Tisch erstellen, rotieren und zur World hinzufügen
    TiledObject? positionDaniel = spawnPoints?.objects.firstWhere((element) => element.name == 'daniel');

    final deskTopRight = DeskDaniel(
      position: Vector2(positionDaniel?.x ?? 0, positionDaniel?.y ?? 0),
      size: Vector2(DeskDaniel.frameWidth * 0.24, DeskDaniel.pngHeight * 0.24),
    )..angle = Units.degree270;
    world.add(deskTopRight);

    // TriggerZone für Daniel ebenfalls in die World legen
    final danielTrigger = TriggerZone(
      target: deskTopRight,
      padding: 35.0, // Bei Tischen gerne etwas mehr Padding, da sie breiter sind
      onAction: () {
        overlays.add(DanielDialogs.normalAction.toString());
      },
    );
    world.add(danielTrigger);
  }
}
