import 'package:flame_forge2d/flame_forge2d.dart';

/// Shared radial-impulse ("shockwave") math, used by both the Plasma
/// Battery's mid-flight detonation and Coolant Tank's destruction
/// explosion, so the two features can't drift out of sync.
class ExplosionSystem {
  ExplosionSystem._();

  /// Applies an outward impulse to every dynamic body within [radius] of
  /// [origin], falling off linearly from [strength] at the center to 0 at
  /// the edge of the blast.
  ///
  /// Linear falloff is the classic 2D-game shockwave approximation: real
  /// blast pressure falls off with distance^2 (inverse-square, like light or
  /// gravity), but that makes anything not almost touching the explosion
  /// feel unaffected, which reads as "weak" rather than "far away." Linear
  /// falloff keeps the blast feeling powerful across its whole radius while
  /// still guaranteeing nothing outside [radius] is touched, at the cost of
  /// physical realism.
  static void applyShockwave({
    required Forge2DWorld world,
    required Vector2 origin,
    required double radius,
    required double strength,
  }) {
    for (final body in world.physicsWorld.bodies) {
      if (body.bodyType != BodyType.dynamic) {
        continue;
      }

      final offset = body.worldCenter - origin;
      final distance = offset.length;
      if (distance <= 0 || distance > radius) {
        continue;
      }

      final falloff = 1 - (distance / radius);
      final direction = offset..scale(1 / distance);
      final impulse = direction * (strength * falloff);
      body.applyLinearImpulse(impulse, point: body.worldCenter);
    }
  }
}
