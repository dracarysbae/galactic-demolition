import 'dart:ui';

import 'building_block.dart';

/// Lightweight, fragile structure. Breaks in one or two solid hits — good
/// for teaching the player how impact damage works without frustration.
class SolarPanelBlock extends BuildingBlock {
  SolarPanelBlock({
    required super.center,
    required super.halfWidth,
    required super.halfHeight,
  });

  @override
  Color get color => const Color(0xFF3B82F6);

  @override
  double get density => 0.6;

  @override
  double get friction => 0.3;

  @override
  double get restitution => 0.1;

  @override
  double get maxHealth => 6;
}
