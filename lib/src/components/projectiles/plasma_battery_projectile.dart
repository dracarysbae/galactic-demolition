import 'dart:ui';

import 'package:flame/events.dart';

import '../../systems/explosion_system.dart';
import 'space_projectile.dart';

/// Detonates into a radial shockwave when tapped mid-flight instead of
/// relying on a direct hit — good for scattering a tight cluster of blocks
/// rather than punching through a single one.
class PlasmaBatteryProjectile extends SpaceProjectile {
  PlasmaBatteryProjectile({
    required super.startPosition,
    required super.initialVelocity,
  });

  /// Blast radius, in meters.
  static const double _blastRadius = 4;

  /// Peak impulse magnitude applied to bodies at the blast center.
  static const double _blastStrength = 12;

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
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    ExplosionSystem.applyShockwave(
      world: world,
      origin: body.worldCenter,
      radius: _blastRadius,
      strength: _blastStrength,
    );
    removeFromParent();
  }
}
