import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:the_office/npcs/tobi.dart';
import 'package:the_office/trigger_zone.dart';
import 'package:the_office/util.dart';

import 'hendrik.dart';
import 'inventory_cursor.dart';
import 'inventory_item.dart';
import 'npcs/desk_daniel.dart';

class OfficeGame extends FlameGame
    with
        ChangeNotifier,
        HasKeyboardHandlerComponents,
        HasCollisionDetection,
        MouseMovementDetector,
        SecondaryTapCallbacks {
  List<InventoryItem> ownedItems = [];
  InventoryItem? selectedItem;
  Vector2 mousePosition = Vector2.zero();
  late TextComponent statusText;
  bool isDeskLocked = false;
  late Hendrik player;
  late TiledComponent mapComponent;

  final ChangeNotifier overlayChangeNotifier = ChangeNotifier();

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // 1. Map ganz normal laden und als EINZIGES Objekt zur World hinzufügen
    mapComponent = await TiledComponent.load('office.tmx', Vector2.all(64));
    world.add(mapComponent);

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

                  final obstacle = TileObstacle(
                    position: Vector2(tileX + objX, tileY + objY),
                    size: Vector2(objWidth, objHeight),
                  );

                  // Hitboxen bekommen eine feste Priorität über dem Boden
                  obstacle.priority = 1;
                  world.add(obstacle..debugMode = true);
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

    // Spawnpoint auslesen
    final spawnPoints = mapComponent.tileMap.getLayer<ObjectGroup>('spawnPoints');
    TiledObject? playerObject = spawnPoints?.objects.firstWhere((element) => element.name == 'playerStart');

    // Spieler erstellen und ihm eine höhere Priorität als der Map geben
    player = Hendrik(position: Vector2(playerObject?.x ?? 0, playerObject?.y ?? 0), size: Vector2(40, 75));
    player.priority = 2; // Läuft über dem Boden

    world.add(player);

    // Kamera folgt dem Spieler
    camera.follow(player, snap: true);

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

  void _buildNpcs() {
    // 1. Tobi ganz normal erstellen und zur World hinzufügen
    final tobiNpc = Tobi(position: Vector2(520, 100), size: Vector2(Tobi.frameWidth * 0.15, Tobi.pngHeight * 0.15));
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
    final deskTopRight = DeskDaniel(
      position: Vector2(300, 220),
      size: Vector2(DeskDaniel.frameWidth * 0.28, DeskDaniel.pngHeight * 0.28),
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

class TileObstacle extends PositionComponent {
  TileObstacle({required Vector2 position, required Vector2 size}) : super(position: position, size: size) {
    // Das Aktiviert die Hitbox für diese Box
    add(RectangleHitbox());
  }
}

// Falls dein Editor 'RenderableLayer' nicht kennt, deklarieren wir den Parameter
// in der Komponente einfach als 'dynamic' oder nutzen den exakten Typ aus der Schleife.
class MyTiledLayerComponent extends PositionComponent {
  final dynamic renderLayer; // dynamic fängt alle internen Paket-Namensänderungen ab

  MyTiledLayerComponent(this.renderLayer);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Ruft die originale Render-Methode des flame_tiled Layers auf
    renderLayer.render(canvas);
  }
}
