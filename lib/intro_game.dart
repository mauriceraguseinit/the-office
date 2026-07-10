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

    // Füge den Regen über der Map hinzu (Priority sorgt dafür, dass er im Vordergrund liegt)
    world.add(RainParticleSystem(priority: 10));

    camera.viewfinder.position = Vector2(1280 / 2, 720 / 2);
    camera.viewfinder.anchor = Anchor.center;
  }
}

/// Repräsentiert eine einzelne pixelige Regen-Untereinheit
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
  final int _maxDrops = 150; // Anzahl der Regentropfen auf dem Bildschirm
  final math.Random _random = math.Random();

  // Richtungs-Vektoren für den seitlichen Fall (z.B. Wind von rechts nach links)
  final double _windX = -3.0; // Negativ = zieht nach links
  final double _fallY = 8.0; // Positiv = fällt nach unten

  final Paint _rainPaint = Paint()
    ..color =
        const Color(0x99A5C0D6) // Leicht transparentes Retro-Blau/Grün (z.B. passend zu heißen Tagen/Gewitter)
    ..strokeWidth =
        3.0 // Dicke Linien für den 8-Bit Look (Keine dünnen 1px Linien!)
    ..strokeCap = StrokeCap.square; // Eckige Kanten statt runder Punkte

  @override
  void onMount() {
    super.onMount();
    // Start-Population generieren, damit der Regen sofort da ist
    for (int i = 0; i < _maxDrops; i++) {
      _drops.add(
        _RainDrop(
          _random.nextDouble() * 1280,
          _random.nextDouble() * 720,
          100 + _random.nextDouble() * 150, // Individuelle Fallgeschwindigkeit
          6 + _random.nextDouble() * 10, // Länge des Tropfens
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    for (final _RainDrop drop in _drops) {
      // Bewegung berechnen (Kombination aus Basis-Geschwindigkeit und Richtungsfaktor)
      drop.x += _windX * drop.speed * dt;
      drop.y += _fallY * drop.speed * dt;

      // Wenn der Tropfen unten aus dem Bildschirm fällt, respawne ihn oben
      if (drop.y > 720) {
        drop.y = -20;
        drop.x = _random.nextDouble() * 1400; // Puffer einbauen wegen des schrägen Falls
      }
      // Wenn er links aus dem Bildschirm weht
      if (drop.x < -20) {
        drop.x = 1300;
        drop.y = _random.nextDouble() * 720;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Alle Tropfen basierend auf ihren Wind-Vektoren als Linien zeichnen
    for (final _RainDrop drop in _drops) {
      canvas.drawLine(
        Offset(drop.x, drop.y),
        Offset(drop.x + _windX * drop.length, drop.y + _fallY * drop.length),
        _rainPaint,
      );
    }
  }
}
