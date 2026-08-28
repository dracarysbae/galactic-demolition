import 'dart:math';
import 'dart:ui';

import '../systems/particle_effects.dart';
import 'structures/building_block.dart';

/// The AI core each level's demolition is aimed at.
///
/// Behaves exactly like a [BuildingBlock] for physics/damage purposes — same
/// impulse-based health system — but destroying it is the level's win
/// condition, so [onDestroyed] reports completion through [GameState]
/// instead of just disappearing. Its pulsing reactor-core glow marks it as
/// the priority target at a glance.
class TargetCore extends BuildingBlock {
  TargetCore({
    required super.center,
    required super.halfWidth,
    required super.halfHeight,
    this.maxHealth = 50,
  }) {
    _corePaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.12);
  }

  @override
  final double maxHealth;

  late final Paint _corePaint;
  double _pulseTime = 0;

  @override
  Color get color => const Color(0xFFEF4444);

  @override
  double get density => 2.0;

  @override
  double get friction => 0.4;

  @override
  double get restitution => 0.05;

  @override
  int get scoreValue => 500;

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTime += dt;
  }

  @override
  void onDestroyed() {
    game.gameState.completeLevel();
    game.world.addAll(
      ParticleEffects.explosion(
        origin: body.worldCenter.clone(),
        fireColor: color,
        radius: 3.5,
      ),
    );
    game.triggerShake(0.6);
  }

  /// A breathing white-hot core, like an active reactor — the brighter and
  /// faster the pulse, the more this reads as "the important one."
  @override
  void renderAccents(Canvas canvas, RRect rrect) {
    final pulse = (sin(_pulseTime * 5) + 1) / 2;
    final coreRadius =
        (rrect.width < rrect.height ? rrect.width : rrect.height) *
        (0.18 + pulse * 0.05);
    _corePaint.color = const Color(0xFFFFF7ED).withValues(
      alpha: 0.75 + pulse * 0.25,
    );
    canvas.drawCircle(Offset.zero, coreRadius, _corePaint);
  }
}
