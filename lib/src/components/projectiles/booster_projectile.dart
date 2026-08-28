import 'dart:ui';

import 'space_projectile.dart';

/// Heavy decommissioned rocket booster. High mass and friction make it
/// plow through structures rather than bounce off them; low restitution
/// means very little of its momentum is wasted on rebounding.
class BoosterProjectile extends SpaceProjectile {
  BoosterProjectile({
    required super.startPosition,
    required super.initialVelocity,
  });

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
}
