import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';

class IntroGame extends FlameGame<World> {
  IntroGame()
    : super(
        camera: CameraComponent.withFixedResolution(
          width: 1280,
          height: 720,
        ),
      );

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final TiledComponent<FlameGame<World>> introMap = await TiledComponent.load(
      'intro.tmx',
      Vector2(1280, 720),
    );
    world.add(introMap);

    final ObjectGroup? flickeringLayer = introMap.tileMap.getLayer<ObjectGroup>('flickerings');
    if (flickeringLayer != null) {
      for (final TiledObject tiledObject in flickeringLayer.objects) {
        // REPARATUR: Wenn das Objekt keine GID hat, überspringen wir es sofort
        if (tiledObject.gid == null) continue;

        final int gid = tiledObject.gid!;
        Sprite? tileSprite;

        final tiledMapData = introMap.tileMap.map;
        Tileset? tileset;

        for (final ts in tiledMapData.tilesets) {
          if (ts.firstGid != null && gid >= ts.firstGid!) {
            if (tileset == null || ts.firstGid! > tileset.firstGid!) {
              tileset = ts;
            }
          }
        }

        if (tileset != null && tileset.firstGid != null) {
          final localId = gid - tileset.firstGid!;

          final tile = tileset.tiles.cast<Tile?>().firstWhere(
            (t) => t?.localId == localId,
            orElse: () => null,
          );

          if (tile != null && tile.image != null && tile.image!.source != null) {
            String imagePath = tile.image!.source!;

            if (imagePath.startsWith('../images/')) {
              imagePath = imagePath.replaceAll('../images/', '');
            } else if (imagePath.startsWith('assets/images/')) {
              imagePath = imagePath.replaceAll('assets/images/', '');
            }

            tileSprite = await Sprite.load(imagePath);
          }
        }

        world.add(
          FlickeringLight(
            position: Vector2(tiledObject.x, tiledObject.y),
            size: Vector2(tiledObject.width, tiledObject.height),
            logoSprite: tileSprite,
            priority: 5,
          ),
        );
      }
    }

    world.add(RainParticleSystem(priority: 10));

    camera.viewfinder.position = Vector2(1280 / 2, 720 / 2);
    camera.viewfinder.anchor = Anchor.center;
  }
}

class FlickeringLight extends PositionComponent {
  FlickeringLight({
    required super.position,
    required super.size,
    required this.logoSprite,
    super.priority,
  }) {
    anchor = Anchor.bottomLeft;
  }

  final Sprite? logoSprite;
  final math.Random _random = math.Random();

  double _timer = 0.0;
  double _nextToggleTime = 0.1;
  bool _isVisible = true;

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    if (_timer >= _nextToggleTime) {
      _timer = 0.0;
      _isVisible = !_isVisible;

      _nextToggleTime = _isVisible ? 0.05 + _random.nextDouble() * 0.5 : 0.02 + _random.nextDouble() * 0.15;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_isVisible && logoSprite != null) {
      logoSprite!.render(
        canvas,
        position: Vector2.zero(),
        size: size,
      );
    }
  }
}

class _RainDrop {
  _RainDrop(this.x, this.y, this.speed, this.length);
  double x;
  double y;
  final double speed;
  final double length;
}

class RainParticleSystem extends Component {
  RainParticleSystem({super.priority});

  final List<_RainDrop> _drops = <_RainDrop>[];
  final int _maxDrops = 150;
  final math.Random _random = math.Random();

  final double _windX = -3.0;
  final double _fallY = 8.0;

  final Paint _rainPaint = Paint()
    ..color = const Color(0x99A5C0D6)
    ..strokeWidth = 3.0
    ..strokeCap = StrokeCap.square;

  @override
  void onMount() {
    super.onMount();
    for (int i = 0; i < _maxDrops; i++) {
      _drops.add(
        _RainDrop(
          _random.nextDouble() * 1280,
          _random.nextDouble() * 720,
          100 + _random.nextDouble() * 150,
          6 + _random.nextDouble() * 10,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    for (final _RainDrop drop in _drops) {
      drop.x += _windX * drop.speed * dt;
      drop.y += _fallY * drop.speed * dt;

      if (drop.y > 720) {
        drop.y = -20;
        drop.x = _random.nextDouble() * 1400;
      }
      if (drop.x < -20) {
        drop.x = 1300;
        drop.y = _random.nextDouble() * 720;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (final _RainDrop drop in _drops) {
      canvas.drawLine(
        Offset(drop.x, drop.y),
        Offset(drop.x + _windX * drop.length, drop.y + _fallY * drop.length),
        _rainPaint,
      );
    }
  }
}
