import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';

import 'credits_sequence.dart';

class IntroGame extends FlameGame<World> {
  // 2. Callback für das Ende des Intros definieren

  IntroGame({required this.onIntroComplete})
    : super(
        camera: CameraComponent.withFixedResolution(
          width: 1280,
          height: 720,
        ),
      );
  // Interner Tracker für den Audioplayer, um darauf lauschen zu können

  AudioPlayer? _bgmPlayer;
  final VoidCallback onIntroComplete;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // 3. Audio-Dateien vorab in den Cache laden
    await FlameAudio.audioCache.load('intro.mp3');

    // 4. Musik abspielen und Player-Instanz merken
    // Wir nutzen 'play' statt 'loop', da es nur einmal laufen soll
    _bgmPlayer = await FlameAudio.play('intro.mp3');
    await _bgmPlayer?.setVolume(0.2);

    // 5. Auf das Ende des Tracks lauschen
    _bgmPlayer?.onPlayerComplete.listen((_) {
      debugPrint('🎵 Intro-Musik beendet. Wechsel zum Hauptspiel...');
      onIntroComplete(); // Löst den automatischen Wechsel aus
    });

    // --- DEIN BESTEHENDER MAP- & PARTIKEL-CODE ---
    final TiledComponent<FlameGame<World>> introMap = await TiledComponent.load(
      'intro.tmx',
      Vector2(1280, 720),
    );
    world.add(introMap);

    final ObjectGroup? flickeringLayer = introMap.tileMap.getLayer<ObjectGroup>('flickerings');
    if (flickeringLayer != null) {
      for (final TiledObject tiledObject in flickeringLayer.objects) {
        if (tiledObject.gid == null) continue;

        final int gid = tiledObject.gid!;
        Sprite? tileSprite;
        final TiledMap tiledMapData = introMap.tileMap.map;
        Tileset? tileset;

        for (final Tileset ts in tiledMapData.tilesets) {
          if (ts.firstGid != null && gid >= ts.firstGid!) {
            if (tileset == null || ts.firstGid! > tileset.firstGid!) {
              tileset = ts;
            }
          }
        }

        if (tileset != null && tileset.firstGid != null) {
          final int localId = gid - tileset.firstGid!;
          final Tile? tile = tileset.tiles.cast<Tile?>().firstWhere(
            (Tile? t) => t?.localId == localId,
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

    final ObjectGroup? lightsLayer = introMap.tileMap.getLayer<ObjectGroup>('lights');
    if (lightsLayer != null) {
      for (final TiledObject lightObject in lightsLayer.objects) {
        final Vector2 pos = Vector2(lightObject.x, lightObject.y);
        final Vector2 size = Vector2(lightObject.width, lightObject.height);

        world.add(GradientLight(position: pos, size: size, priority: 4));
        world.add(MothSwarm(position: pos, size: size, priority: 6));
      }
    }

    world.add(RainParticleSystem(priority: 10));
    world.add(RainSplashParticleSystem(priority: 9));

    camera.viewfinder.position = Vector2(1280 / 2, 720 / 2);
    camera.viewfinder.anchor = Anchor.center;

    world.add(CreditsSequence(priority: 20));
  }

  // 6. Ressourcen sauber freigeben, falls das Intro vorzeitig übersprungen wird
  @override
  void onRemove() {
    _bgmPlayer?.stop();
    _bgmPlayer?.dispose();
    super.onRemove();
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

class _Moth {
  _Moth(this.angle, this.radius, this.speed, this.wobbleSpeed, this.size);
  double angle;
  double radius;
  final double speed;
  final double wobbleSpeed;
  final double size;
  double time = 0;
}

class MothSwarm extends PositionComponent {
  MothSwarm({required super.position, required super.size, super.priority});

  final List<_Moth> _moths = <_Moth>[];
  final int _mothCount = 12;
  final math.Random _random = math.Random();

  final Paint _mothPaint = Paint()
    ..color = const Color(0xDD332211)
    ..style = PaintingStyle.fill;

  @override
  void onMount() {
    super.onMount();
    final double maxRadius = size.x / 4;

    for (int i = 0; i < _mothCount; i++) {
      _moths.add(
        _Moth(
          _random.nextDouble() * math.pi * 2,
          _random.nextDouble() * maxRadius + 5,
          2.0 + _random.nextDouble() * 4.0,
          5.0 + _random.nextDouble() * 10.0,
          2.0 + _random.nextInt(2).toDouble(),
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final _Moth moth in _moths) {
      moth.time += dt * moth.wobbleSpeed;
      moth.angle += moth.speed * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final double center = size.x / 2;

    for (final _Moth moth in _moths) {
      final double chaoticRadius = moth.radius + math.sin(moth.time) * 8.0;
      final double chaoticAngle = moth.angle + math.cos(moth.time * 0.7) * 0.5;

      final double x = center + math.cos(chaoticAngle) * chaoticRadius;
      final double y = center + math.sin(chaoticAngle) * chaoticRadius;

      canvas.drawRect(Rect.fromLTWH(x, y, moth.size, moth.size), _mothPaint);
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

/// Struktur für ein einzelnes Spritzer-Teilchen
class _Splash {
  _Splash(this.x, this.y, this.vx, this.vy, this.maxAge);
  double x;
  double y;
  final double vx; // Horizontale Pixel-Geschwindigkeit
  double vy; // Vertikale Pixel-Geschwindigkeit (mit Gravitation)
  final double maxAge; // Lebensdauer in Sekunden
  double age = 0.0;
}

/// Erzeugt kleine 8-Bit Aufschlag-Animationen am unteren Bildschirmrand
class RainSplashParticleSystem extends Component {
  RainSplashParticleSystem({super.priority});

  final List<_Splash> _splashes = <_Splash>[];
  final math.Random _random = math.Random();

  double _spawnTimer = 0.0;
  final double _spawnInterval = 0.05; // Wie oft spritzt es irgendwo (alle 0.05s)

  final Paint _splashPaint = Paint()
    ..color =
        const Color(0xB3B9D1E3) // Etwas helleres, gischtartiges Retro-Blau
    ..style = PaintingStyle.fill;

  @override
  void update(double dt) {
    super.update(dt);

    // 1. Bestehende Partikel aktualisieren
    for (int i = _splashes.length - 1; i >= 0; i--) {
      final _Splash splash = _splashes[i];
      splash.age += dt;

      if (splash.age >= splash.maxAge) {
        _splashes.removeAt(i);
        continue;
      }

      // Bewegung anwenden + kleine Gravitation für die Flugkurve
      splash.vy += 300 * dt;
      splash.x += splash.vx * dt;
      splash.y += splash.vy * dt;
    }

    // 2. Neue Spritzer erzeugen
    _spawnTimer += dt;
    if (_spawnTimer >= _spawnInterval) {
      _spawnTimer = 0.0;

      // Schlägt zufällig im unteren Drittel des Bildschirms auf (Bodenbereich)
      final double impactX = _random.nextDouble() * 1280;
      final double impactY = 620 + _random.nextDouble() * 80;

      // Pro Aufschlag fliegen 3 bis 4 Pixel-Fragmente weg
      final int particlesPerSplash = 3 + _random.nextInt(2);
      for (int i = 0; i < particlesPerSplash; i++) {
        _splashes.add(
          _Splash(
            impactX,
            impactY,
            (_random.nextDouble() - 0.5) * 120, // Verteilt sich nach links/rechts
            -60 - _random.nextDouble() * 80, // Fliegt nach oben weg
            0.15 + _random.nextDouble() * 0.15, // Verschwindet nach max 0.3 Sekunden
          ),
        );
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (final _Splash splash in _splashes) {
      // Quadratische 2x2 Pixel-Punkte für den passenden 8-Bit Look
      canvas.drawRect(
        Rect.fromLTWH(splash.x, splash.y, 2.5, 2.5),
        _splashPaint,
      );
    }
  }
}
