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

    // 1. Kaputte Flacker-Lampen laden (Object-Layer 'flickerings')
    final ObjectGroup? flickeringLayer = introMap.tileMap.getLayer<ObjectGroup>('flickerings');
    if (flickeringLayer != null) {
      for (final TiledObject tiledObject in flickeringLayer.objects) {
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

    // 2. Weiche Ambient-Lichter & Fliegenschwärme laden (Object-Layer 'lights')
    final ObjectGroup? lightsLayer = introMap.tileMap.getLayer<ObjectGroup>('lights');
    if (lightsLayer != null) {
      for (final TiledObject lightObject in lightsLayer.objects) {
        final Vector2 pos = Vector2(lightObject.x, lightObject.y);
        final Vector2 size = Vector2(lightObject.width, lightObject.height);

        // Das Licht selbst
        world.add(GradientLight(position: pos, size: size, priority: 4));

        // Der Fliegenschwarm direkt am selben Platz
        world.add(MothSwarm(position: pos, size: size, priority: 6));
      }
    }

    world.add(RainParticleSystem(priority: 10));

    camera.viewfinder.position = Vector2(1280 / 2, 720 / 2);
    camera.viewfinder.anchor = Anchor.center;
  }
}

class GradientLight extends PositionComponent {
  GradientLight({required super.position, required super.size, super.priority});

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final double radius = size.x / 2;
    final Offset center = Offset(radius, radius);

    final Paint paint = Paint()
      ..shader = RadialGradient(
        colors: const <Color>[
          Color(0x88FFEEA0),
          Color(0x33FFDD88),
          Color(0x00FFDD88),
        ],
        stops: const <double>[0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..blendMode = BlendMode.screen;

    canvas.drawCircle(center, radius, paint);
  }
}

/// Struktur für eine einzelne Fliege/Motte
class _Moth {
  _Moth(this.angle, this.radius, this.speed, this.wobbleSpeed, this.size);
  double angle; // Aktueller Winkel im Orbit um die Lampe
  double radius; // Abstand zum Zentrum
  final double speed; // Rotationsgeschwindigkeit
  final double wobbleSpeed; // Wie hektisch sie ausbricht
  final double size; // Pixel-Größe (z.B. 2x2 oder 3x3)
  double time = 0; // Individueller Zeit-Tracker für das Rauschen
}

class MothSwarm extends PositionComponent {
  MothSwarm({required super.position, required super.size, super.priority});

  final List<_Moth> _moths = <_Moth>[];
  final int _mothCount = 12; // Anzahl der Fliegen pro Lichtquelle
  final math.Random _random = math.Random();

  final Paint _mothPaint = Paint()
    ..color =
        const Color(0x5F332211) // Dunkle, gräuliche Punkte für die Insekten
    ..style = PaintingStyle.fill;

  @override
  void onMount() {
    super.onMount();
    final double maxRadius = size.x / 4; // Sie fliegen eher im inneren, hellen Kern

    for (int i = 0; i < _mothCount; i++) {
      _moths.add(
        _Moth(
          _random.nextDouble() * math.pi * 2,
          _random.nextDouble() * maxRadius + 5,
          2.0 + _random.nextDouble() * 4.0,
          5.0 + _random.nextDouble() * 10.0,
          2.0 + _random.nextInt(2).toDouble(), // 2 bis 3 Pixel groß
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    for (final _Moth moth in _moths) {
      moth.time += dt * moth.wobbleSpeed;
      // Grund-Kreisbewegung
      moth.angle += moth.speed * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final double center = size.x / 2;

    for (final _Moth moth in _moths) {
      // Durch Sinus/Kosinus-Modulation auf Radius und Winkel entsteht das unberechenbare "Haken-Schlagen"
      final double chaoticRadius = moth.radius + math.sin(moth.time) * 8.0;
      final double chaoticAngle = moth.angle + math.cos(moth.time * 0.7) * 0.5;

      final double x = center + math.cos(chaoticAngle) * chaoticRadius;
      final double y = center + math.sin(chaoticAngle) * chaoticRadius;

      // Zeichne eckige Pixel-Fliegen für den passenden 8-Bit Look
      canvas.drawRect(
        Rect.fromLTWH(x, y, moth.size, moth.size),
        _mothPaint,
      );
    }
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
      logoSprite!.render(canvas, position: Vector2.zero(), size: size);
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
