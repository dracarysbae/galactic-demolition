import 'dart:ui';

import 'building_block.dart';

/// Near-perfectly elastic structure — behaves like a pinball bumper,
/// redirecting most of a projectile's momentum back out rather than
/// absorbing it. Low friction keeps the bounce clean instead of scrubbing
/// off speed on the way out.
class RepulsionShieldBlock extends BuildingBlock {
  RepulsionShieldBlock({
    required super.center,
    required super.halfWidth,
    required super.halfHeight,
  });

  @override
  Color get color => const Color(0xFF22D3EE);

  @override
  double get density => 2;

  @override
  double get friction => 0.05;

  @override
  double get restitution => 0.95;

  @override
  double get maxHealth => 25;
}
