import 'package:forge2d/forge2d.dart';

/// Immutable description of a single level's physical environment and layout.
///
/// Adding a new planet only requires a new [LevelConfig] instance in
/// `levels_data.dart` — no changes to the game/physics engine are needed.
class LevelConfig {
  const LevelConfig({
    required this.id,
    required this.name,
    required this.gravity,
    this.wind = const Vector2.zero(),
    this.arenaWidth = 40,
    this.arenaHeight = 22.5,
  });

  final String id;
  final String name;

  /// Forge2D world gravity, in meters/second^2 (Forge2D "meters", not pixels).
  /// Positive Y is downward in Forge2D's world convention when used with
  /// flame_forge2d's default camera mapping.
  final Vector2 gravity;

  /// Constant force-per-unit-mass applied to wind-affected bodies every tick,
  /// in meters/second^2. Zero vector = no wind (e.g. the Moon).
  final Vector2 wind;

  /// Play area size in Forge2D meters, used to place boundary walls.
  final double arenaWidth;
  final double arenaHeight;
}
