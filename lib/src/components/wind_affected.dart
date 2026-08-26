import 'package:flame_forge2d/flame_forge2d.dart';

/// Mixin for [BodyComponent]s that should feel the level's wind force.
///
/// Wind is not native to Forge2D, so [GalacticDemolitionGame] applies it
/// manually each tick to every component that opts in via this mixin,
/// rather than baking wind handling into every projectile/block subclass.
mixin WindAffected on BodyComponent {
  /// Multiplier applied to the level's base wind vector before it's
  /// converted to a force. Lets heavier/lighter objects react differently
  /// to the same wind (e.g. a Booster resists wind more than debris).
  double get windSusceptibility => 1.0;
}
