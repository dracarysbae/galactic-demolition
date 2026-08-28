import 'dart:ui';

import '../../systems/explosion_system.dart';
import 'building_block.dart';

/// Ruptures violently when destroyed, radiating an outward shockwave that
/// can chain into nearby blocks — a single well-placed hit can bring down
/// more than it directly touches.
class CoolantTankBlock extends BuildingBlock {
  CoolantTankBlock({
    required super.center,
    required super.halfWidth,
    required super.halfHeight,
  });

  /// Blast radius, in meters.
  static const double _blastRadius = 3.5;

  /// Peak impulse magnitude applied to bodies at the blast center.
  static const double _blastStrength = 9;

  @override
  Color get color => const Color(0xFFF97316);

  @override
  double get density => 1.2;

  @override
  double get friction => 0.3;

  @override
  double get restitution => 0.1;

  @override
  double get maxHealth => 10;

  @override
  void onDestroyed() {
    // The body/fixtures are still valid at this point — onDestroyed runs
    // right before BuildingBlock removes this component — so worldCenter
    // reflects where the tank actually was when it broke.
    ExplosionSystem.applyShockwave(
      world: world,
      origin: body.worldCenter,
      radius: _blastRadius,
      strength: _blastStrength,
    );
  }
}
