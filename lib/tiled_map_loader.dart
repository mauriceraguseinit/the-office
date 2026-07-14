import 'dart:math';
import 'dart:ui';

import 'package:clipper2/clipper2.dart';
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
  // Speichert das berechnete, begehbare NavMesh
  Paths64? _walkableNavMesh;

  // Jedes Hindernis ist ein Polygon. Dadurch bleiben auch Rotationen erhalten.
  Paths64 _navigationBlockers = Paths64.of(<Path64>[]);

  double _mapPixelWidth = 0;
  double _mapPixelHeight = 0;

  // Speichere die ursprünglichen statischen Kollider (Wände, feste Möbel)
  final List<Path64> _baseStaticColliders = <Path64>[];
  NavMeshVisualizer? _activeVisualizer;
  final Map<PositionComponent, TiledObject> _interactiveTiledObjects = <PositionComponent, TiledObject>{};
  // Referenz auf die geladene Map für den Rebuild-Prozess
  RenderableTiledMap? _cachedTileMap;

  /// Hilfsmethode für die Punkt-in-Polygon-Prüfung (Ray-Casting-Algorithmus).
  /// Verhindert Compiler-Probleme mit Clipper-Extensions komplett.
  bool _isPointInPolygon(Point64 point, Path64 path) {
    if (path.isEmpty) return false;

    bool inside = false;
    final int nVert = path.length;
    final int testX = point.x;
    final int testY = point.y;

    for (int i = 0, j = nVert - 1; i < nVert; j = i++) {
      final Point64 vi = path[i];
      final Point64 vj = path[j];

      // Strahl-Schnittprüfung (Ray-Casting)
      if (((vi.y > testY) != (vj.y > testY)) && (testX < (vj.x - vi.x) * (testY - vi.y) / (vj.y - vi.y) + vi.x)) {
        inside = !inside;
      }
    }
    return inside;
  }

  /// Prüft, ob eine Weltkoordinate innerhalb des berechneten NavMeshes liegt.
  bool isPositionWalkable(Vector2 feetPosition) {
    if (feetPosition.x < 0 ||
        feetPosition.y < 0 ||
        feetPosition.x > _mapPixelWidth ||
        feetPosition.y > _mapPixelHeight) {
      return false;
    }

    final Point64 point = Point64(
      feetPosition.x.round(),
      feetPosition.y.round(),
    );

    // Sobald der Fußpunkt in einem beliebigen Hindernis-Polygon liegt,
    // ist die Position nicht begehbar.
    for (final Path64 blocker in _navigationBlockers) {
      if (_isPointInPolygon(point, blocker)) {
        return false;
      }
    }

    return true;
  }

  /// Erstellt ein gedrehtes Rechteck als Clipper-Polygon.
  ///
  /// Tiled speichert die Rotation in Grad. Der Drehpunkt eines
  /// Collision-Rechtecks liegt bei dessen linker oberer Ecke.
  Path64 _createRotatedColliderPath({
    required double left,
    required double top,
    required double width,
    required double height,
    required double rotationDegrees,
    double padding = 0.0,
  }) {
    // Der Drehpunkt ist die originale linke obere Ecke des Tiled-Rechtecks.
    final Vector2 pivot = Vector2(left, top);

    final double angle = Units.radFromDegree(rotationDegrees);
    final double cosAngle = cos(angle);
    final double sinAngle = sin(angle);

    Vector2 rotatePoint(Vector2 point) {
      final double dx = point.x - pivot.x;
      final double dy = point.y - pivot.y;

      return Vector2(
        pivot.x + (dx * cosAngle) - (dy * sinAngle),
        pivot.y + (dx * sinAngle) + (dy * cosAngle),
      );
    }

    // Padding ist wichtig, damit Hendriks Fuß-/Hitbox nicht exakt
    // an der Collision-Kante entlanglaufen kann.
    final List<Vector2> corners = <Vector2>[
      Vector2(left - padding, top - padding),
      Vector2(left + width + padding, top - padding),
      Vector2(left + width + padding, top + height + padding),
      Vector2(left - padding, top + height + padding),
    ];

    final List<Vector2> rotatedCorners = corners.map(rotatePoint).toList();

    return Path64Ext.from(<int>[
      rotatedCorners[0].x.round(),
      rotatedCorners[0].y.round(),
      rotatedCorners[1].x.round(),
      rotatedCorners[1].y.round(),
      rotatedCorners[2].x.round(),
      rotatedCorners[2].y.round(),
      rotatedCorners[3].x.round(),
      rotatedCorners[3].y.round(),
    ]);
  }

  Future<(Hendrik player, List<Vector2> lightSources)> loadTiledMap(
    World world,
    TiledComponent<FlameGame<World>> mapComponent,
  ) async {
    final RenderableTiledMap tileMap = mapComponent.tileMap;
    _cachedTileMap = tileMap; // Map für spätere Rebuilds cachen

    // --- Liste für die Clipper-Berechnung permanent säubern ---
    _baseStaticColliders.clear();

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

                  if (flipX && !flipDiag) {
                    objX = 64.0 - objX - objWidth;
                  }

                  if (flipY) {
                    objY = 64.0 - objY - objHeight;
                  }

                  // Wand-Kollider kommen in die permanente Basis-Liste
                  _baseStaticColliders.add(
                    _createTileCollisionPath(
                      tileX: tileX,
                      tileY: tileY,
                      collider: tiledObject,
                      flipX: flipX,
                      flipY: flipY,
                      flipDiagonal: flipDiag,
                      padding: 20.0,
                    ),
                  );

                  final PositionComponent obstacle =
                      PositionComponent(
                        position: Vector2(tileX + objX, tileY + objY),
                        size: Vector2(objWidth, objHeight),
                      )..add(
                        RectangleHitbox(
                          collisionType: CollisionType.active,
                        ),
                      );

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
      // Permanente Kollisions-Zonen der Map abspeichern
      _baseStaticColliders.add(
        _createRotatedColliderPath(
          left: object.x,
          top: object.y,
          width: object.width,
          height: object.height,
          rotationDegrees: object.rotation,
          padding: 5.0,
        ),
      );

      final PositionComponent staticObstacle = PositionComponent(
        position: Vector2(object.x, object.y),
        size: Vector2(object.width, object.height),
        anchor: Anchor.topLeft,
        priority: 1,
      );

      staticObstacle.add(
        RectangleHitbox(
          position: Vector2.zero(),
          size: staticObstacle.size,
          anchor: Anchor.topLeft,
          collisionType: CollisionType.active,
        )..debugMode = false,
      );

      world.add(staticObstacle);
    });

    // interactive objects layers instanziieren und zur Welt hinzufügen
    final ObjectGroup? interactiveObjects = mapComponent.tileMap.getLayer<ObjectGroup>('interactiveObjects');
    final ObjectGroup? interactiveObjects2 = mapComponent.tileMap.getLayer<ObjectGroup>('interactiveObjects2');

    _interactiveTiledObjects.clear(); // Map leeren vor dem Neubefüllen

    interactiveObjects?.objects.forEach((TiledObject object) {
      // Alle Objekte speichern - auch reine Dekorationen.

      final PositionComponent? comp = _processInteractiveObject(
        world,
        object,
        tileMap,
        priorityOffset: 0,
      );

      if (comp != null) {
        _interactiveTiledObjects[comp] = object;
      }
    });

    interactiveObjects2?.objects.forEach((TiledObject object) {
      // Alle Objekte speichern - auch reine Dekorationen.

      final PositionComponent? comp = _processInteractiveObject(
        world,
        object,
        tileMap,
        priorityOffset: 100000,
      );

      if (comp != null) {
        _interactiveTiledObjects[comp] = object;
      }
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

    // --- NavMesh initial dynamisch backen ---
    rebuildNavMesh();

    return (player, sources);
  }

  void rebuildNavMesh() {
    if (_cachedTileMap == null) return;

    _navigationBlockers = Paths64.of(<Path64>[]);
    final double padding = 20.0;

    // 1. Statische Wände & Kachel-Kollider aus der Map hinzufügen
    for (final Path64 path in _baseStaticColliders) {
      _navigationBlockers.add(path);
    }

    // 2. Entferne alle Objekte, die gerade gelöscht werden oder gelöscht wurden
    _interactiveTiledObjects.removeWhere(
      (PositionComponent comp, _) => comp.isRemoving,
    );

    // 3. Berechne die Live-Kollider für alle verbliebenen interaktiven Objekte
    _interactiveTiledObjects.forEach(
      (PositionComponent comp, TiledObject tiledData) {
        _addInteractiveTileCollisionPaths(
          comp: comp,
          tiledData: tiledData,
          padding: padding,
        );
      },
    );

    // 4. Backe das NavMesh neu mit allen Blockern
    _bakeNavMesh(_cachedTileMap!, _navigationBlockers);
  }

  void _addInteractiveTileCollisionPaths({
    required PositionComponent comp,
    required TiledObject tiledData,
    required double padding,
  }) {
    if (tiledData.gid == null || tiledData.gid! <= 0) {
      return;
    }

    final int cleanGid = tiledData.gid! & 0x0FFFFFFF;
    final Tile? tile = _cachedTileMap?.map.tileByGid(cleanGid);

    // Kein Collision-Rechteck im Tile Editor:
    // Dann wird absichtlich nichts ausgestanzt.
    if (tile == null || tile.objectGroup is! ObjectGroup) {
      return;
    }

    final ObjectGroup collisionObjects = tile.objectGroup as ObjectGroup;
    final Tileset tileset = _cachedTileMap!.map.tilesetByTileGId(cleanGid);
    final Vector2 sourceTileSize = _getSourceTileSize(tile, tileset);

    final double scaleX = comp.size.x / sourceTileSize.x;
    final double scaleY = comp.size.y / sourceTileSize.y;

    final double parentCos = cos(comp.angle);
    final double parentSin = sin(comp.angle);

    // Da InteractiveObject Anchor.center hat, ist der lokale Ursprung
    // fuer die Umrechnung die linke obere Ecke relativ zum Mittelpunkt.
    final double localLeft = -comp.size.x / 2;
    final double localTop = -comp.size.y / 2;

    Vector2 rotateAroundObjectCenter(Vector2 localPoint) {
      return Vector2(
        comp.position.x + (localPoint.x * parentCos) - (localPoint.y * parentSin),
        comp.position.y + (localPoint.x * parentSin) + (localPoint.y * parentCos),
      );
    }

    for (final TiledObject collision in collisionObjects.objects) {
      // Collision-Rechteck lokal im zentrierten Parent.
      final double boxLeft = localLeft + (collision.x * scaleX);
      final double boxTop = localTop + (collision.y * scaleY);
      final double boxRight = boxLeft + (collision.width * scaleX);
      final double boxBottom = boxTop + (collision.height * scaleY);

      // Tiled rotiert ein Collision-Rechteck um dessen linke obere Ecke.
      final Vector2 collisionPivot = Vector2(boxLeft, boxTop);
      final double collisionAngle = Units.radFromDegree(collision.rotation);
      final double collisionCos = cos(collisionAngle);
      final double collisionSin = sin(collisionAngle);

      Vector2 rotateCollisionBox(Vector2 point) {
        final double dx = point.x - collisionPivot.x;
        final double dy = point.y - collisionPivot.y;

        return Vector2(
          collisionPivot.x + (dx * collisionCos) - (dy * collisionSin),
          collisionPivot.y + (dx * collisionSin) + (dy * collisionCos),
        );
      }

      final List<Vector2> localCorners = <Vector2>[
        Vector2(boxLeft - padding, boxTop - padding),
        Vector2(boxRight + padding, boxTop - padding),
        Vector2(boxRight + padding, boxBottom + padding),
        Vector2(boxLeft - padding, boxBottom + padding),
      ];

      // 1. Rotation der Collision-Box im Tile Editor.
      // 2. Rotation des Object-Layer-Objekts.
      // 3. Position des zentrierten InteractiveObjects.
      final List<Vector2> worldCorners = localCorners.map(rotateCollisionBox).map(rotateAroundObjectCenter).toList();

      _navigationBlockers.add(
        Path64Ext.from(<int>[
          worldCorners[0].x.round(),
          worldCorners[0].y.round(),
          worldCorners[1].x.round(),
          worldCorners[1].y.round(),
          worldCorners[2].x.round(),
          worldCorners[2].y.round(),
          worldCorners[3].x.round(),
          worldCorners[3].y.round(),
        ]),
      );
    }
  }

  PositionComponent? _processInteractiveObject(
    World world,
    TiledObject object,
    RenderableTiledMap tileMap, {
    int priorityOffset = 0,
  }) {
    if (object.gid == null || object.gid! <= 0) return null;

    final int cleanGid = object.gid! & 0x0FFFFFFF;
    final Tile? tile = tileMap.map.tileByGid(cleanGid);

    if (tile == null) {
      return null;
    }

    final Tileset tileset = tileMap.map.tilesetByTileGId(cleanGid);
    final Vector2 sourceTileSize = _getSourceTileSize(tile, tileset);

    final Vector2 objectSize = Vector2(object.width, object.height);
    final double angle = Units.radFromDegree(object.rotation);

    final PositionComponent renderComp = _createRenderComponent(tile, tileMap, cleanGid, objectSize);

    final InteractiveObject? interactiveObject = InteractiveObjectsCatalogue.interactiveObjectForClassName(
      className: object.class_,
      displayName: object.name,
      renderComponent: renderComp,
      position: _getTiledObjectCenter(object: object),
      size: objectSize,
      priorityOffset: priorityOffset,
    );

    if (interactiveObject != null) {
      interactiveObject.angle = angle;

      _addTileCollisionHitboxes(
        interactiveObject,
        tile,
        sourceTileSize,
      );

      world.add(interactiveObject);
      return interactiveObject;
    } else {
      return _setupAsDecoration(
        world,
        renderComp,
        object,
        angle,
        priorityOffset,
        tile,
        sourceTileSize,
      );
    }
  }

  void removeInteractiveObjectFromNavMesh(InteractiveObject object) {
    _interactiveTiledObjects.remove(object);
    rebuildNavMesh();
  }

  void _addTileCollisionHitboxes(
    PositionComponent component,
    Tile tile,
    Vector2 sourceTileSize,
  ) {
    if (tile.objectGroup is! ObjectGroup) {
      return;
    }

    final ObjectGroup objectGroup = tile.objectGroup as ObjectGroup;

    final double scaleX = component.size.x / sourceTileSize.x;
    final double scaleY = component.size.y / sourceTileSize.y;

    for (final TiledObject tiledObject in objectGroup.objects) {
      final Vector2 hitboxPosition = Vector2(
        tiledObject.x * scaleX,
        tiledObject.y * scaleY,
      );

      final Vector2 hitboxSize = Vector2(
        tiledObject.width * scaleX,
        tiledObject.height * scaleY,
      );

      component.add(
        RectangleHitbox(
          position: hitboxPosition,
          size: hitboxSize,
          collisionType: CollisionType.active,
        )..debugMode = false,
      );
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

  PositionComponent _setupAsDecoration(
    World world,
    PositionComponent renderComp,
    TiledObject object,
    double angle,
    int priorityOffset,
    Tile tile,
    Vector2 sourceTileSize,
  ) {
    renderComp
      ..anchor = Anchor.center
      ..position = Vector2(object.x, object.y)
      ..angle = angle
      ..priority = object.y.toInt() + priorityOffset;

    _addTileCollisionHitboxes(
      renderComp,
      tile,
      sourceTileSize,
    );

    world.add(renderComp);
    return renderComp;
  }

  Vector2 _getSourceTileSize(Tile tile, Tileset tileset) {
    final dynamic image = tile.image;

    if (image != null) {
      return Vector2(
        image.width.toDouble(),
        image.height.toDouble(),
      );
    }

    return Vector2(
      tileset.tileWidth!.toDouble(),
      tileset.tileHeight!.toDouble(),
    );
  }

  Vector2 _getTiledObjectCenter({
    required TiledObject object,
  }) {
    return Vector2(object.x, object.y);
  }

  /// Erstellt aus einem Collision-Objekt des Tile Collision Editors
  /// ein korrekt gedrehtes Polygon in Weltkoordinaten.
  ///
  /// Wichtig:
  /// - [collider.x]/[collider.y] sind lokal im 64x64-Tile.
  /// - Tiled rotiert um die linke obere Ecke des Collision-Objekts.
  /// - Tile-Flips werden anschließend auf jeden einzelnen Punkt angewendet.
  Path64 _createTileCollisionPath({
    required double tileX,
    required double tileY,
    required TiledObject collider,
    required bool flipX,
    required bool flipY,
    required bool flipDiagonal,
    double padding = 0.0,
  }) {
    const double tileSize = 64.0;

    final Vector2 pivot = Vector2(collider.x, collider.y);

    // Tiled verwendet Grad; in Flame/Canvas gilt bei Y nach unten:
    // positive Winkel drehen im Uhrzeigersinn.
    final double radians = Units.radFromDegree(collider.rotation);
    final double cosAngle = cos(radians);
    final double sinAngle = sin(radians);

    Vector2 rotateAroundCollisionOrigin(Vector2 point) {
      final double dx = point.x - pivot.x;
      final double dy = point.y - pivot.y;

      return Vector2(
        pivot.x + (dx * cosAngle) - (dy * sinAngle),
        pivot.y + (dx * sinAngle) + (dy * cosAngle),
      );
    }

    Vector2 applyTileFlip(Vector2 point) {
      double x = point.x;
      double y = point.y;

      // Das entspricht der Transformation aus deinem alten,
      // korrekt positionierten Code - nur jetzt pro Eckpunkt.
      if (flipDiagonal) {
        final double transformedX = tileSize - y;
        final double transformedY = x;
        x = transformedX;
        y = transformedY;
      }

      // Bei diagonal geflippten Tiles entspricht das dem Verhalten
      // deines bisherigen Render-/Collision-Codes.
      if (flipX && !flipDiagonal) {
        x = tileSize - x;
      }

      if (flipY) {
        y = tileSize - y;
      }

      return Vector2(x, y);
    }

    // Die vier lokalen Ecken des ursprünglichen Collision-Rechtecks.
    final List<Vector2> localCorners = <Vector2>[
      Vector2(
        collider.x - padding,
        collider.y - padding,
      ),
      Vector2(
        collider.x + collider.width + padding,
        collider.y - padding,
      ),
      Vector2(
        collider.x + collider.width + padding,
        collider.y + collider.height + padding,
      ),
      Vector2(
        collider.x - padding,
        collider.y + collider.height + padding,
      ),
    ];

    // Reihenfolge ist wichtig:
    // 1. Collision-Rechteck um seinen Tiled-Ursprung drehen.
    // 2. Tile-Flip auf die gedrehten Punkte anwenden.
    // 3. Tile-Weltposition addieren.
    final List<Vector2> worldCorners = localCorners.map((Vector2 corner) {
      final Vector2 rotated = rotateAroundCollisionOrigin(corner);
      final Vector2 flipped = applyTileFlip(rotated);

      return Vector2(
        tileX + flipped.x,
        tileY + flipped.y,
      );
    }).toList();

    return Path64Ext.from(<int>[
      worldCorners[0].x.round(),
      worldCorners[0].y.round(),
      worldCorners[1].x.round(),
      worldCorners[1].y.round(),
      worldCorners[2].x.round(),
      worldCorners[2].y.round(),
      worldCorners[3].x.round(),
      worldCorners[3].y.round(),
    ]);
  }

  /// Sucht einen Pfad zum Klickziel.
  /// Ist das Klickziel blockiert, wird der nächstgelegene erreichbare
  /// Rasterpunkt um das Hindernis herum verwendet.
  List<Vector2> findPath(Vector2 start, Vector2 end) {
    const double nodeSize = 32.0;
    const int maxSearchRadius = 24;

    final int targetX = (end.x / nodeSize).round();
    final int targetY = (end.y / nodeSize).round();

    // Zuerst versuchen wir das normale Ziel.
    final List<Vector2> directPath = _findPathToWalkableTarget(start, end);

    if (directPath.isNotEmpty) {
      return directPath;
    }

    // Das Ziel liegt vermutlich in einem Objekt oder einer Wand.
    // Wir suchen ringförmig die nächstgelegenen begehbaren Rasterpunkte.
    for (int radius = 1; radius <= maxSearchRadius; radius++) {
      final List<Vector2> candidates = <Vector2>[];

      for (int dx = -radius; dx <= radius; dx++) {
        for (int dy = -radius; dy <= radius; dy++) {
          // Nur den äußeren Ring prüfen.
          if (max(dx.abs(), dy.abs()) != radius) {
            continue;
          }

          final Vector2 candidate = Vector2(
            (targetX + dx) * nodeSize,
            (targetY + dy) * nodeSize,
          );

          if (isPositionWalkable(candidate)) {
            candidates.add(candidate);
          }
        }
      }

      // Von den Kandidaten dieses Rings zuerst denjenigen testen,
      // der geometrisch am nächsten an der Klickposition liegt.
      candidates.sort(
        (Vector2 a, Vector2 b) => a.distanceTo(end).compareTo(b.distanceTo(end)),
      );

      for (final Vector2 candidate in candidates) {
        final List<Vector2> path = _findPathToWalkableTarget(
          start,
          candidate,
        );

        if (path.isNotEmpty) {
          return path;
        }
      }
    }

    return <Vector2>[];
  }

  /// Berechnet das NavMesh beim Laden der Map
  void _bakeNavMesh(
    RenderableTiledMap tileMap,
    Paths64 staticColliders,
  ) {
    final double mapPixelWidth = (tileMap.map.width * 64).toDouble();
    final double mapPixelHeight = (tileMap.map.height * 64).toDouble();

    _mapPixelWidth = mapPixelWidth;
    _mapPixelHeight = mapPixelHeight;

    final Paths64 baseRoom = Paths64.of(<Path64>[]);
    baseRoom.add(
      Path64Ext.from(<int>[
        0,
        0,
        mapPixelWidth.round(),
        0,
        mapPixelWidth.round(),
        mapPixelHeight.round(),
        0,
        mapPixelHeight.round(),
      ]),
    );

    _navigationBlockers = staticColliders;

    _walkableNavMesh = Clipper.difference(
      subject: baseRoom,
      clip: _navigationBlockers,
      fillRule: FillRule.nonZero,
    );

    // --- ALTEN VISUALIZER ENTFERNEN ---
    if (_activeVisualizer != null && _activeVisualizer!.isMounted) {
      _activeVisualizer!.removeFromParent();
    }

    // --- NEUEN VISUALIZER HINZUFÜGEN ---
    _activeVisualizer = NavMeshVisualizer(_walkableNavMesh!);
    //world.add(_activeVisualizer!);

    debugPrint('🎉 NavMesh erfolgreich gebacken! Subpolygone: ${_walkableNavMesh?.length}');
  }

  List<Vector2> _findPathToWalkableTarget(Vector2 start, Vector2 end) {
    const double nodeSize = 32.0; // Rastergröße

    // Start- und Zielkoordinaten auf das Raster umrechnen
    final int startX = (start.x / nodeSize).round();
    final int startY = (start.y / nodeSize).round();
    final int endX = (end.x / nodeSize).round();
    final int endY = (end.y / nodeSize).round();

    final _AStarNode startNode = _AStarNode(startX, startY);
    final _AStarNode endNode = _AStarNode(endX, endY);

    // Das Ziel ist ein Rasterpunkt, nicht zwingend die exakte Klickposition.
    final Vector2 endWorldPosition = Vector2(
      endX * nodeSize,
      endY * nodeSize,
    );

    if (!isPositionWalkable(endWorldPosition)) {
      return <Vector2>[];
    }

    final List<_AStarNode> openSet = <_AStarNode>[startNode];
    final Set<_AStarNode> closedSet = <_AStarNode>{};

    // Nachbargebiete
    final List<List<int>> directions = <List<int>>[
      <int>[0, 1], <int>[1, 0], <int>[0, -1], <int>[-1, 0], // Achsen
      <int>[1, 1], <int>[-1, 1], <int>[1, -1], <int>[-1, -1], // Diagonalen
    ];

    while (openSet.isNotEmpty) {
      openSet.sort((_AStarNode a, _AStarNode b) => a.f.compareTo(b.f));
      final _AStarNode current = openSet.removeAt(0);
      closedSet.add(current);

      if (current == endNode) {
        final List<Vector2> path = <Vector2>[];
        _AStarNode? temp = current;
        while (temp != null) {
          // Wir speichern die Raster-Punkte als echte Welt-Koordinaten
          path.add(Vector2(temp.x * nodeSize, temp.y * nodeSize));
          temp = temp.parent;
        }
        return path.reversed.toList();
      }

      for (final List<int> dir in directions) {
        final int neighborX = current.x + dir[0];
        final int neighborY = current.y + dir[1];
        final _AStarNode neighbor = _AStarNode(neighborX, neighborY, parent: current);

        if (closedSet.contains(neighbor)) continue;

        final Vector2 worldPos = Vector2(neighborX * nodeSize, neighborY * nodeSize);

        // 1. Ist der Zielpunkt begehbar?
        if (!isPositionWalkable(worldPos)) {
          continue;
        }

        // 2. Schneidet die Verbindung zwischen beiden Rasterknoten ein Hindernis?
        final Vector2 currentWorldPos = Vector2(
          current.x * nodeSize,
          current.y * nodeSize,
        );

        if (!canWalkBetween(currentWorldPos, worldPos)) {
          continue;
        }

        // 2. VERHINDERE DIAGONALES ABKÜRZEN DURCH WÄNDE:
        // Wenn wir uns diagonal bewegen (z.B. rechts-unten), dürfen die beiden
        // direkt anliegenden Achsen-Knoten (rechts und unten) nicht blockiert sein!
        if (dir[0] != 0 && dir[1] != 0) {
          final Vector2 adjacent1 = Vector2((current.x + dir[0]) * nodeSize, current.y * nodeSize);
          final Vector2 adjacent2 = Vector2(current.x * nodeSize, (current.y + dir[1]) * nodeSize);
          if (!isPositionWalkable(adjacent1) || !isPositionWalkable(adjacent2)) {
            continue; // Diagonale Bewegung blockieren, um nicht durch Ecken zu glitchen
          }
        }

        final double moveCost = (dir[0] != 0 && dir[1] != 0) ? 1.414 : 1.0;
        final double tentativeG = current.g + moveCost;

        final _AStarNode? existingOpen = openSet.where((_AStarNode n) => n == neighbor).firstOrNull;

        if (existingOpen == null) {
          neighbor.g = tentativeG;
          neighbor.h = ((neighbor.x - endNode.x).abs() + (neighbor.y - endNode.y).abs()).toDouble();
          openSet.add(neighbor);
        } else if (tentativeG < existingOpen.g) {
          existingOpen.g = tentativeG;
          existingOpen.parent = current;
        }
      }
    }

    return <Vector2>[];
  }

  bool canWalkBetween(Vector2 from, Vector2 to) {
    final Vector2 delta = to - from;

    // Alle vier Weltpixel einen Zwischenpunkt prüfen.
    final int steps = max(1, (delta.length / 4.0).ceil());

    for (int i = 1; i <= steps; i++) {
      final Vector2 samplePoint = from + (delta * (i / steps));

      if (!isPositionWalkable(samplePoint)) {
        return false;
      }
    }

    return true;
  }
}

// Füge diese Hilfsklassen für A* ganz unten in tiled_map_loader.dart ein:

// ==========================================
// HILFSKLASSEN (Ganz unten außerhalb des Mixins)
// ==========================================

class _AStarNode {
  _AStarNode(this.x, this.y, {this.parent});
  final int x;
  final int y;
  double g = 0;
  double h = 0;
  _AStarNode? parent;

  double get f => g + h;

  @override
  bool operator ==(Object other) => other is _AStarNode && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

class NavMeshVisualizer extends PositionComponent {
  NavMeshVisualizer(this.paths) : super(priority: 9999);
  final Paths64 paths;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final Paint fillPaint = Paint()
      ..color = const Color(0x3F00FF00)
      ..style = PaintingStyle.fill;

    final Paint strokePaint = Paint()
      ..color = const Color(0xFF00FF00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Alle Clipper-Konturen gemeinsam füllen.
    // Dadurch werden innere Konturen als Löcher interpretiert.
    final Path combinedPath = Path()..fillType = PathFillType.evenOdd;

    for (final Path64 path in paths) {
      if (path.isEmpty) {
        continue;
      }

      final List<Offset> points = path
          .map(
            (Point64 point) => Offset(
              point.x.toDouble(),
              point.y.toDouble(),
            ),
          )
          .toList();

      combinedPath.addPolygon(points, true);
    }

    // Die komplette begehbare Fläche einmal füllen.
    canvas.drawPath(combinedPath, fillPaint);

    // Ränder weiterhin einzeln zeichnen, damit jede Kante sichtbar bleibt.
    for (final Path64 path in paths) {
      if (path.isEmpty) {
        continue;
      }

      final List<Offset> points = path
          .map(
            (Point64 point) => Offset(
              point.x.toDouble(),
              point.y.toDouble(),
            ),
          )
          .toList();

      final Path outlinePath = Path()..addPolygon(points, true);
      canvas.drawPath(outlinePath, strokePaint);
    }
  }
}
