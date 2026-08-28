import 'dart:ui';

import 'building_block.dart';

/// Dense, heavily reinforced structure. Its high density gives it enough
/// mass that projectiles struggle to move it at all, and it absorbs far
/// more impact than a typical block before breaking — meant to be routed
/// around or hit with something heavy (Booster) rather than punched
/// straight through.
class TitaniumBlock extends BuildingBlock {
  TitaniumBlock({
    required super.center,
    required super.halfWidth,
    required super.halfHeight,
  });

  @override
  Color get color => const Color(0xFF9CA3AF);

  @override
  double get density => 12;

  @override
  double get friction => 0.6;

  @override
  double get restitution => 0.02;

  @override
  double get maxHealth => 60;
}
