import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart';
import 'package:the_office/utils/util.dart';

import 'hendrik.dart';
import 'interactiveObjects/interactive_object.dart';
import 'interactiveObjects/interactive_objects_catalogue.dart';

mixin TiledMapLoader on FlameGame<World> {
  Future<(Hendrik player, List<Vector2> lightSources)> loadTiledMap(
    World world,
    TiledComponent<FlameGame<World>> mapComponent,
  ) async {
    final RenderableTiledMap tileMap = mapComponent.tileMap;

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
      _processInteractiveObject(world, object, tileMap, priorityOffset: 0);
    });

    interactiveObjects2?.objects.forEach((TiledObject object) {
      _processInteractiveObject(world, object, tileMap, priorityOffset: 100000);
    });

    // spawn points layer
    final ObjectGroup? spawnPoints = mapComponent.tileMap.getLayer<ObjectGroup>('spawnPoints');
    final TiledObject? playerObject = spawnPoints?.objects.firstWhere(
      (TiledObject element) => element.name == 'playerStart',
    );
    final Hendrik player = Hendrik(position: Vector2(playerObject?.x ?? 0, playerObject?.y ?? 0));
    world.add(player);

    // light points
    final List<TiledObject> lightPoints =
        mapComponent.tileMap.getLayer<ObjectGroup>('lights')?.objects ?? <TiledObject>[];
    final List<Vector2> sources = lightPoints.map((TiledObject obj) => Vector2(obj.x, obj.y)).toList();
    if (sources.isEmpty) {
      debugPrint('⚠️  WARNUNG: Keine Lichter in Tiled gefunden! Nutze Fallback-Licht.');
      sources.add(Vector2(500, 500));
    }

    return (player, sources);
  }

  void _processInteractiveObject(
    World world,
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
      _addTileCollisionHitboxes(interactiveObject, tile, objectSize);
      world.add(interactiveObject);
    } else {
      // 3. Fallback: Nur als Deko/Hindernis hinzufügen, wenn es kein interaktives Objekt ist
      _setupAsDecoration(world, renderComp, object, angle, priorityOffset, tile);
    }
  }

  void _addTileCollisionHitboxes(PositionComponent component, Tile tile, Vector2 size) {
    if (tile.objectGroup != null && tile.objectGroup is ObjectGroup) {
      final ObjectGroup objectGroup = tile.objectGroup as ObjectGroup;
      for (final TiledObject tiledObject in objectGroup.objects) {
        // Tiled-Koordinaten sind relativ zum Top-Left (0,0) des Tiles.
        // Da unsere Komponenten Anchor.center nutzen, müssen wir den Offset berechnen.
        final Vector2 hitboxPos = Vector2(
          tiledObject.x - size.x / 2,
          tiledObject.y - size.y / 2,
        );

        component.add(
          RectangleHitbox(
            position: hitboxPos,
            size: Vector2(tiledObject.width, tiledObject.height),
            collisionType: CollisionType.active, // Active, damit Hendrik blockiert wird
          )..debugMode = false,
        );
      }
    }
  }

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

  void _setupAsDecoration(
    World world,
    PositionComponent renderComp,
    TiledObject object,
    double angle,
    int priorityOffset,
    Tile tile,
  ) {
    renderComp
      ..anchor = Anchor.center
      ..position = Vector2(object.x, object.y)
      ..angle = angle
      ..priority = object.y.toInt() + priorityOffset;

    _addTileCollisionHitboxes(renderComp, tile, renderComp.size);
    world.add(renderComp);
  }

  Vector2 _getTiledObjectCenter({
    required TiledObject object,
    required double angle,
  }) {
    final Vector2 localCenter = Vector2(
      object.width / 2,
      object.height / 2,
    );

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
}
