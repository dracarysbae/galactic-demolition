import 'dart:math';
import 'dart:ui';

import 'package:flame/events.dart';

import '../../systems/explosion_system.dart';
import '../../systems/particle_effects.dart';
import 'space_projectile.dart';

/// Detonates into a radial shockwave when tapped mid-flight instead of
/// relying on a direct hit — good for scattering a tight cluster of blocks
/// rather than punching through a single one.
class PlasmaBatteryProjectile extends SpaceProjectile {
  PlasmaBatteryProjectile({
    required super.startPosition,
    required super.initialVelocity,
  }) {
    _glowPaint = Paint()..style = PaintingStyle.stroke;
    _corePaint = Paint()..color = const Color(0xFFFFFFFF);
  }

  /// Blast radius, in meters.
  static const double _blastRadius = 4;

  /// Peak impulse magnitude applied to bodies at the blast center.
  static const double _blastStrength = 12;

  // Mutated in place each frame for the pulse animation — never replaced.
  late final Paint _glowPaint;
  late final Paint _corePaint;
  double _pulseTime = 0;

  @override
  Color get color => const Color(0xFFA855F7);

  @override
  double get radius => 0.4;

  @override
  double get density => 4;

  @override
  double get friction => 0.4;

  @override
  double get restitution => 0.1;

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTime += dt;
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    final origin = body.worldCenter.clone();
    ExplosionSystem.applyShockwave(
      world: world,
      origin: origin,
      radius: _blastRadius,
      strength: _blastStrength,
    );
    game.world.addAll(
      ParticleEffects.explosion(
        origin: origin,
        fireColor: const Color(0xFF67E8F9),
        radius: _blastRadius * 0.6,
      ),
    );
    game.triggerShake(0.35);
    removeFromParent();
  }

  /// An intense pulsing cyan/violet glow around a white-hot core — meant to
  /// read as "dangerous, about to go off" even before it's tapped.
  @override
  void render(Canvas canvas) {
    final pulse = (sin(_pulseTime * 6) + 1) / 2; // oscillates 0..1
    _glowPaint
      ..strokeWidth = radius * (0.5 + pulse * 0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.12 + pulse * 0.18)
      ..color = const Color(0xFF22D3EE).withValues(alpha: 0.6 + pulse * 0.4);
    canvas.drawCircle(Offset.zero, radius * 0.85, _glowPaint);

    _corePaint.color = const Color(
      0xFFFFFFFF,
    ).withValues(alpha: 0.85 + pulse * 0.15);
    canvas.drawCircle(Offset.zero, radius * (0.35 + pulse * 0.08), _corePaint);
  }
}
