import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

class PeeStream extends Component {
  PeeStream({
    required this.startPos,
    required this.targetPos,
    this.duration = 2.5,
  });

  final Vector2 startPos;
  final Vector2 targetPos;
  final double duration;
  double _timer = 0;
  final Random _random = Random();

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;

    if (_timer >= duration) {
      removeFromParent();
      return;
    }

    // Trajektorien-Parameter
    const double tHit = 0.55; // Zeit bis zum Einschlag
    const double gravity = 500.0;

    final Vector2 diff = targetPos - startPos;

    // Physikalische Berechnung der Startgeschwindigkeit, um targetPos bei tHit zu treffen
    final double vx = diff.x / tHit;
    final double vy = (diff.y - 0.5 * gravity * tHit * tHit) / tHit;

    parent?.add(
      ParticleSystemComponent(
        priority: priority,
        particle: Particle.generate(
          count: 1,
          lifespan: tHit, // Partikel stirbt exakt am Ziel
          generator: (int i) {
            final Vector2 jitter = Vector2(
              (_random.nextDouble() - 0.5) * 1.5,
              (_random.nextDouble() - 0.5) * 0.2,
            );

            return AcceleratedParticle(
              position: startPos + jitter,
              speed: Vector2(vx, vy),
              acceleration: Vector2(0, gravity),
              child: CircleParticle(
                radius: 0.2 + _random.nextDouble() * 0.2,
                paint: Paint()..color = const Color(0xFFFFdd00).withAlpha(220),
              ),
            );
          },
        ),
      ),
    );
  }
}
