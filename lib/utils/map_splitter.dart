import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';

class MapSplitter {
  static Future<List<TiledComponent<FlameGame<World>>>> splitMapIntoLayers({
    required String fileName,
    required Vector2 destTileSize,
  }) async {
    final List<TiledComponent<FlameGame<World>>> splitComponents = <TiledComponent<FlameGame<World>>>[];

    // Temporäre Instanz laden, um die Layer-Struktur zu analysieren
    final TiledComponent<FlameGame<World>> baseMap = await TiledComponent.load(fileName, destTileSize);
    final int totalLayers = baseMap.tileMap.renderableLayers.length;

    final List<String> layerNames = <String>[];
    for (int i = 0; i < totalLayers; i++) {
      layerNames.add(baseMap.tileMap.renderableLayers[i].layer.name);
    }

    // Für jeden Layer eine eigene, isolierte TiledComponent erstellen
    for (int i = 0; i < totalLayers; i++) {
      final String currentLayerName = layerNames[i];

      final TiledComponent<FlameGame<World>> layerComponent = await TiledComponent.load(
        fileName,
        destTileSize,
        priority: i, // Standard-Priorität entspricht dem Tiled-Layer-Index
      );

      _isolateSingleLayer(layerComponent.tileMap, targetLayerName: currentLayerName);
      splitComponents.add(layerComponent);
    }

    return splitComponents;
  }

  static void _isolateSingleLayer(RenderableTiledMap tileMap, {required String targetLayerName}) {
    for (int i = 0; i < tileMap.renderableLayers.length; i++) {
      final String layerName = tileMap.renderableLayers[i].layer.name;

      if (layerName == targetLayerName) {
        tileMap.setLayerVisibility(i, visible: true);
      } else {
        tileMap.setLayerVisibility(i, visible: false);
      }
    }
  }
}
