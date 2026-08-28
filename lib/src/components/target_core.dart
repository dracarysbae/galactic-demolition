import 'structures/building_block.dart';

/// The AI core each level's demolition is aimed at.
///
/// Behaves exactly like a [BuildingBlock] for physics/damage purposes — same
/// impulse-based health system — but destroying it is the level's win
/// condition, so [onDestroyed] reports completion through [GameState]
/// instead of just disappearing.
class TargetCore extends BuildingBlock {
  TargetCore({
    required super.center,
    required super.halfWidth,
    required super.halfHeight,
    this.maxHealth = 50,
  });

  @override
  final double maxHealth;

  @override
  double get density => 2.0;

  @override
  double get friction => 0.4;

  @override
  double get restitution => 0.05;

  @override
  void onDestroyed() {
    game.gameState.completeLevel();
  }
}
