import 'dart:ui';

import '../../systems/explosion_system.dart';
import '../../systems/particle_effects.dart';
import 'building_block.dart';

/// Ruptures violently when destroyed, radiating an outward shockwave that
/// can chain into nearby blocks — a single well-placed hit can bring down
/// more than it directly touches.
class CoolantTankBlock extends BuildingBlock {
  CoolantTankBlock({
    required super.center,
    required super.halfWidth,
    required super.halfHeight,
  }) {
    _hazardStripePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = halfHeight * 0.35
      ..color = const Color(0x991C1917);
  }

  /// Blast radius, in meters.
  static const double _blastRadius = 3.5;

  /// Peak impulse magnitude applied to bodies at the blast center.
  static const double _blastStrength = 9;

  static const Color _explosionColor = Color(0xFFFBBF24);

  late final Paint _hazardStripePaint;

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
    final origin = body.worldCenter;
    ExplosionSystem.applyShockwave(
      world: world,
      origin: origin,
      radius: _blastRadius,
      strength: _blastStrength,
    );
    // A second, fierier burst on top of the base destruction debris, plus
    // a stronger shake — this is meant to feel like the biggest bang on
    // the board.
    game.world.add(
      ParticleEffects.debris(
        origin: origin.clone(),
        color: _explosionColor,
        count: 22,
        speed: 7,
        lifespan: 0.5,
      ),
    );
    game.triggerShake(0.45);
  }

  /// Diagonal hazard stripes — the universal "this explodes" visual cue.
  @override
  void renderAccents(Canvas canvas, RRect rrect) {
    canvas.save();
    canvas.clipRRect(rrect);
    final step = rrect.height * 0.6;
    for (var x = rrect.left - rrect.height; x < rrect.right; x += step) {
      canvas.drawLine(
        Offset(x, rrect.bottom),
        Offset(x + rrect.height, rrect.top),
        _hazardStripePaint,
      );
    }
    canvas.restore();
  }
}
