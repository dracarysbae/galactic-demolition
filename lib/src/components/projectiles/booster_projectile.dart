import 'dart:ui';

import '../../systems/particle_effects.dart';
import 'space_projectile.dart';

/// Heavy decommissioned rocket booster. High mass and friction make it
/// plow through structures rather than bounce off them; low restitution
/// means very little of its momentum is wasted on rebounding.
class BoosterProjectile extends SpaceProjectile {
  BoosterProjectile({
    required super.startPosition,
    required super.initialVelocity,
  }) {
    _metalPaint = Paint()
      ..shader = Gradient.radial(
        Offset(-radius * 0.35, -radius * 0.35),
        radius * 1.5,
        [
          const Color(0xFFF5F5F4),
          const Color(0xFFFB923C),
          const Color(0xFF7C2D12),
        ],
        const [0, 0.55, 1],
      );
    _rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.15
      ..color = const Color(0xB3000000);
  }

  late final Paint _metalPaint;
  late final Paint _rimPaint;

  /// Accumulates toward the next exhaust puff; reset whenever one is spawned.
  double _trailTimer = 0;
  static const double _trailInterval = 0.04;

  @override
  Color get color => const Color(0xFFFB923C);

  @override
  double get radius => 0.5;

  @override
  double get density => 8;

  @override
  double get friction => 0.8;

  @override
  double get restitution => 0.05;

  @override
  void update(double dt) {
    super.update(dt);
    _trailTimer += dt;
    if (_trailTimer < _trailInterval) {
      return;
    }
    _trailTimer = 0;
    final speed = body.linearVelocity.length;
    if (speed < 1) {
      return;
    }
    final direction = body.linearVelocity / speed;
    final tailPosition = body.position - direction * radius;
    game.world.add(
      ParticleEffects.debris(
        origin: tailPosition,
        color: const Color(0xFFFDBA74),
        count: 2,
        speed: 1.5,
        lifespan: 0.28,
      ),
    );
  }

  /// Metallic radial gradient (bright specular hotspot → steel → dark
  /// gunmetal edge) instead of the base's simple two-tone fill.
  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset.zero, radius, _metalPaint);
    canvas.drawCircle(Offset.zero, radius, _rimPaint);
  }
}
