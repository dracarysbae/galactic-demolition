import 'package:forge2d/forge2d.dart';

import '../config/level_config.dart';

/// Concrete per-planet configurations.
///
/// Real-world surface gravities (m/s^2) are used as a starting point for
/// feel, then tuned per level:
///   Earth ≈ 9.8, Moon ≈ 1.6, Mars ≈ 3.7, Jupiter ≈ 24.8 (cloud-top).
/// Forge2D's world convention here uses +Y as "down" on screen.
class LevelsData {
  LevelsData._();

  static const moon = LevelConfig(
    id: 'moon',
    name: 'Moon',
    gravity: Vector2(0, 1.6),
    wind: Vector2.zero(),
  );

  static const mars = LevelConfig(
    id: 'mars',
    name: 'Mars',
    gravity: Vector2(0, 3.7),
    // Constant directional wind pushing projectiles sideways.
    wind: Vector2(1.2, 0),
  );

  static const jupiter = LevelConfig(
    id: 'jupiter',
    name: 'Jupiter',
    gravity: Vector2(0, 24.8),
    wind: Vector2.zero(),
  );

  static const all = <LevelConfig>[moon, mars, jupiter];
}
