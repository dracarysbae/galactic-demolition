import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';

/// Shared particle-burst builders for impacts and explosions.
///
/// Kept separate from the components that trigger them (BuildingBlock,
/// CoolantTankBlock, PlasmaBatteryProjectile) so every "something broke"
/// moment uses the same look instead of each subclass hand-rolling its own
/// particle setup.
class ParticleEffects {
  ParticleEffects._();

  static final Random _random = Random();

  /// A burst of small rotating, falling debris chunks — rotated rectangles
  /// rather than plain circles, and pulled downward by [gravity] as they
  /// fly outward, so they read as real broken-off rubble rather than a
  /// generic radial sprite burst.
  static ParticleSystemComponent debris({
    required Vector2 origin,
    required Color color,
    int count = 12,
    double speed = 4,
    double lifespan = 0.7,
    Vector2? gravity,
  }) {
    final pull = gravity ?? Vector2(0, 9);
    final particle = Particle.generate(
      count: count,
      lifespan: lifespan,
      generator: (_) {
        final angle = _random.nextDouble() * pi * 2;
        final magnitude = speed * (0.4 + _random.nextDouble() * 0.6);
        final velocity = Vector2(cos(angle), sin(angle)) * magnitude;
        final halfSize = 0.05 + _random.nextDouble() * 0.08;
        final spin = (_random.nextDouble() * 2 - 1) * 10; // rad/s
        final shade = Color.lerp(
          color,
          const Color(0xFF1C1917),
          _random.nextDouble() * 0.5,
        )!;

        return ComputedParticle(
          renderer: (canvas, particle) {
            final fade = (1 - particle.progress).clamp(0.0, 1.0);
            canvas.save();
            canvas.rotate(spin * particle.progress);
            final paint = Paint()..color = shade.withValues(alpha: fade);
            canvas.drawRect(
              Rect.fromCenter(
                center: Offset.zero,
                width: halfSize * 2,
                height: halfSize * 1.4,
              ),
              paint,
            );
            canvas.restore();
          },
        ).accelerated(
          // Outward drag (opposes initial velocity) plus a constant
          // downward pull, so chunks arc and fall like real debris instead
          // of just decelerating in place.
          acceleration: velocity * -1.1 + pull,
          speed: velocity,
        );
      },
    );

    return ParticleSystemComponent(
      particle: particle,
      position: origin.clone(),
    );
  }

  /// A quick, bright, short-lived burst at a contact point — the "spark"
  /// every solid hit should produce, independent of whether the thing hit
  /// actually breaks.
  static ParticleSystemComponent sparks({
    required Vector2 origin,
    int count = 6,
    double speed = 5,
    double lifespan = 0.18,
  }) {
    final particle = Particle.generate(
      count: count,
      lifespan: lifespan,
      generator: (_) {
        final angle = _random.nextDouble() * pi * 2;
        final magnitude = speed * (0.5 + _random.nextDouble() * 0.7);
        final velocity = Vector2(cos(angle), sin(angle)) * magnitude;
        final length = 0.06 + _random.nextDouble() * 0.08;

        return ComputedParticle(
          renderer: (canvas, particle) {
            final fade = (1 - particle.progress).clamp(0.0, 1.0);
            final paint = Paint()
              ..strokeWidth = 0.02
              ..strokeCap = StrokeCap.round
              ..color = const Color(0xFFFFF7D6).withValues(alpha: fade);
            final direction = velocity.normalized();
            canvas.drawLine(
              Offset.zero,
              (direction * length).toOffset(),
              paint,
            );
          },
        ).accelerated(acceleration: velocity * -3, speed: velocity);
      },
    );

    return ParticleSystemComponent(
      particle: particle,
      position: origin.clone(),
    );
  }

  /// A layered explosion: an instant white flash, an expanding shockwave
  /// ring, rising smoke, fast fading fire embers, and falling debris
  /// chunks — composed from several [ParticleSystemComponent]s rather than
  /// one, since each layer needs different motion and lifespan to read as
  /// a real blast instead of a single uniform particle poof.
  static List<Component> explosion({
    required Vector2 origin,
    required Color fireColor,
    double radius = 3,
  }) {
    final flash = ParticleSystemComponent(
      position: origin.clone(),
      particle: ComputedParticle(
        lifespan: 0.12,
        renderer: (canvas, particle) {
          final fade = (1 - particle.progress).clamp(0.0, 1.0);
          final paint = Paint()
            ..color = const Color(0xFFFFFDF5).withValues(alpha: fade * 0.9);
          canvas.drawCircle(Offset.zero, radius * 0.4, paint);
        },
      ),
    );

    final shockwave = ParticleSystemComponent(
      position: origin.clone(),
      particle: ComputedParticle(
        lifespan: 0.4,
        renderer: (canvas, particle) {
          final progress = particle.progress;
          final paint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.12 * (1 - progress)
            ..color = fireColor.withValues(alpha: (1 - progress) * 0.8);
          canvas.drawCircle(Offset.zero, radius * progress, paint);
        },
      ),
    );

    final smoke = ParticleSystemComponent(
      position: origin.clone(),
      particle: Particle.generate(
        count: 10,
        lifespan: 1.1,
        generator: (_) {
          final angle = _random.nextDouble() * pi * 2;
          final speed = 1 + _random.nextDouble() * 1.5;
          final drift = Vector2(cos(angle), sin(angle)) * speed;
          final startRadius = 0.15 + _random.nextDouble() * 0.1;

          return ComputedParticle(
            renderer: (canvas, particle) {
              final fade = (1 - particle.progress).clamp(0.0, 1.0);
              final grownRadius =
                  startRadius + particle.progress * 0.6; // billows outward
              final paint = Paint()
                ..color = const Color(0xFF57534E).withValues(
                  alpha: fade * 0.45,
                );
              canvas.drawCircle(Offset.zero, grownRadius, paint);
            },
          ).accelerated(
            // Slows and drifts upward (buoyancy), like real smoke.
            acceleration: drift * -0.6 + Vector2(0, -1.2),
            speed: drift,
          );
        },
      ),
    );

    final embers = ParticleSystemComponent(
      position: origin.clone(),
      particle: Particle.generate(
        count: 16,
        lifespan: 0.5,
        generator: (_) {
          final angle = _random.nextDouble() * pi * 2;
          final speed = radius * (1.5 + _random.nextDouble() * 1.5);
          final velocity = Vector2(cos(angle), sin(angle)) * speed;
          final emberRadius = 0.04 + _random.nextDouble() * 0.05;

          return ComputedParticle(
            renderer: (canvas, particle) {
              final fade = (1 - particle.progress).clamp(0.0, 1.0);
              final shade = Color.lerp(
                const Color(0xFFFEF3C7),
                fireColor,
                particle.progress,
              )!;
              final paint = Paint()..color = shade.withValues(alpha: fade);
              canvas.drawCircle(Offset.zero, emberRadius, paint);
            },
          ).accelerated(
            acceleration: velocity * -1.8 + Vector2(0, 6),
            speed: velocity,
          );
        },
      ),
    );

    final chunks = debris(
      origin: origin,
      color: fireColor,
      count: 10,
      speed: radius * 1.4,
      lifespan: 0.6,
    );

    return [flash, shockwave, smoke, embers, chunks];
  }
}
