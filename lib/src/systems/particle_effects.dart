import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';

/// Shared particle-burst builders for impacts and explosions.
///
/// Kept separate from the components that trigger them (BuildingBlock,
/// CoolantTankBlock, PlasmaBatteryProjectile) so every "something broke"
/// moment uses the same debris look instead of each subclass hand-rolling
/// its own particle setup.
class ParticleEffects {
  ParticleEffects._();

  static final Random _random = Random();

  /// A burst of small fading circles radiating outward from [origin],
  /// simulating debris from a broken block or explosion.
  ///
  /// Each particle is a [ComputedParticle] (full control over its paint, so
  /// alpha can fade with [Particle.progress]) wrapped in [Particle.
  /// accelerated] for the physics: outward `speed`, with a `deceleration`
  /// (negative acceleration along the same direction) so debris slows down
  /// rather than flying off at constant speed — reads as drag/friction
  /// without needing a real physics body per particle.
  static ParticleSystemComponent debris({
    required Vector2 origin,
    required Color color,
    int count = 12,
    double speed = 4,
    double lifespan = 0.6,
  }) {
    final particle = Particle.generate(
      count: count,
      lifespan: lifespan,
      generator: (_) {
        final angle = _random.nextDouble() * pi * 2;
        final magnitude = speed * (0.4 + _random.nextDouble() * 0.6);
        final velocity = Vector2(cos(angle), sin(angle)) * magnitude;
        final radius = 0.05 + _random.nextDouble() * 0.09;

        return ComputedParticle(
          renderer: (canvas, particle) {
            final fade = (1 - particle.progress).clamp(0.0, 1.0);
            final paint = Paint()..color = color.withValues(alpha: fade);
            canvas.drawCircle(Offset.zero, radius, paint);
          },
        ).accelerated(acceleration: velocity * -1.4, speed: velocity);
      },
    );

    return ParticleSystemComponent(
      particle: particle,
      position: origin.clone(),
    );
  }
}
