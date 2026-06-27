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
  late TiledComponent mapComponent;

  final ChangeNotifier overlayChangeNotifier = ChangeNotifier();

  final Map<String, OverlayWidgetBuilder<OfficeGame>>? overlayBuilderMap = {
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

    world.addAll(mapLayers);

    // Wir geben der Map die Basis-Priorität 0, damit sie ganz unten liegt
    mapComponent.priority = 0;

    final tileMap = mapComponent.tileMap;

    // 2. Schleife: Wir gehen durch alle Kachel-Layer für die Kollisionen
    for (final renderableLayer in tileMap.renderableLayers) {
      final layer = renderableLayer.layer;

      if (layer is TileLayer) {
        final tileLayer = layer;
        final mapWidth = tileMap.map.width;
        final mapHeight = tileMap.map.height;

        for (int y = 0; y < mapHeight; y++) {
          for (int x = 0; x < mapWidth; x++) {
            // HIER wird tileData definiert!
            final tileData = tileMap.getTileData(layerId: tileLayer.id!, x: x, y: y);

            if (tileData != null && tileData.tile != 0) {
              final tileDefinition = tileMap.map.tileByGid(tileData.tile);

              if (tileDefinition != null && tileDefinition.objectGroup != null) {
                final objectGroup = tileDefinition.objectGroup as ObjectGroup;

                final tileX = x * 64.0;
                final tileY = y * 64.0;

                // Rotationszustände direkt aus tileData ablesen (korrekte Properties)
                final bool flipX = tileData.flips.horizontally;
                final bool flipY = tileData.flips.vertically;
                final bool flipDiag = tileData.flips.diagonally;

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
      }
    });

    _buildNpcs(spawnPoints);

    // Spawnpoint auslesen
    TiledObject? playerObject = spawnPoints?.objects.firstWhere((element) => element.name == 'playerStart');

    // Spieler erstellen und ihm eine höhere Priorität als der Map geben
    player = Hendrik(position: Vector2(playerObject?.x ?? 0, playerObject?.y ?? 0));
    player.priority = 0; // Läuft über dem Boden

    world.add(player);

    // Kamera folgt dem Spieler
    camera.follow(player, snap: true);
    camera.viewfinder.zoom = 2.5;

    // Am Ende deiner onLoad()-Methode:

    final rawMinimapCamera = CameraComponent(world: world);
    rawMinimapCamera.viewfinder.zoom = 0.2;
    rawMinimapCamera.follow(player, snap: true);

    final minimap = ClickableMinimap(
      minimapCamera: rawMinimapCamera,
      size: Vector2(200, 200),
      position: Vector2(size.x - 220, size.y - 220),
      onMinimapPressed: _toggleCameraZoom,
    );

    camera.viewport.add(minimap);

    _buildHud();
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
    camera.viewport.add(statusText);
    camera.viewport.add(infoText);
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
