import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';

class MapSplitter {
  /// Lädt eine Tiled-Map und splittet sie in eine Liste von TiledComponents auf.
  /// Jede Komponente enthält genau einen Layer und die Priorität entspricht dem Index.
  static Future<List<TiledComponent>> splitMapIntoLayers({
    required String fileName,
    required Vector2 destTileSize,
  }) async {
    List<TiledComponent> splitComponents = [];

    // 1. Wir laden eine temporäre Instanz, um die Anzahl und Namen der Layer zu ermitteln
    final baseMap = await TiledComponent.load(fileName, destTileSize);
    final totalLayers = baseMap.tileMap.renderableLayers.length;

    // Wir merken uns die Namen der Layer in der korrekten Reihenfolge aus Tiled
    List<String> layerNames = baseMap.tileMap.renderableLayers.map((renderable) => renderable.layer.name).toList();

    // 2. Jetzt erstellen wir für jeden Layer eine eigene TiledComponent
    for (int i = 0; i < totalLayers; i++) {
      final currentLayerName = layerNames[i];

      // Wir laden die Map erneut (Flame nutzt hier das Asset-Caching, das ist performant!)
      final layerComponent = await TiledComponent.load(
        fileName,
        destTileSize,
        priority: i, // Automatische Priorität nach Tiled-Reihenfolge (Index)
      );

      // Nur diesen einen spezifischen Layer sichtbar lassen
      _isolateSingleLayer(layerComponent.tileMap, targetLayerName: currentLayerName);

      splitComponents.add(layerComponent);
    }

    return splitComponents;
  }

  /// Schaltet alle Layer bis auf den Ziel-Layer unsichtbar
  static void _isolateSingleLayer(RenderableTiledMap tileMap, {required String targetLayerName}) {
    for (var i = 0; i < tileMap.renderableLayers.length; i++) {
      final layerName = tileMap.renderableLayers[i].layer.name;
      if (layerName == targetLayerName) {
        tileMap.setLayerVisibility(i, visible: true);
      } else {
        tileMap.setLayerVisibility(i, visible: false);
      }
    }
  }
}
