import 'package:flame/components.dart' as flame;
import 'package:flame_forge2d/flame_forge2d.dart';

import 'components/boundary_wall.dart';
import 'components/wind_affected.dart';
import 'config/level_config.dart';
import 'game_state.dart';

/// Root game class. Owns the Forge2D world, camera, and per-level
/// environment (gravity + wind). Levels are swapped by calling
/// [loadLevel], which resets gravity, rebuilds boundary walls, and clears
/// any leftover projectiles/blocks from the previous attempt.
class GalacticDemolitionGame extends Forge2DGame {
  GalacticDemolitionGame({required this.gameState})
      : super(gravity: LevelConfig.defaultGravityFallback);

  final GameState gameState;

  LevelConfig? _currentLevel;
  LevelConfig get currentLevel =>
      _currentLevel ?? (throw StateError('No level loaded yet'));

  final List<BoundaryWall> _walls = [];

  static const double _pixelsPerMeter = 20;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    camera.viewfinder.zoom = _pixelsPerMeter;
    camera.viewfinder.anchor = flame.Anchor.center;
  }

  /// Tears down the previous level's walls/bodies and configures the world
  /// for [level]: sets gravity, rebuilds boundary walls sized to the arena,
  /// and centers the camera on the arena.
  void loadLevel(LevelConfig level) {
    _currentLevel = level;

    // Setting `world.gravity` wakes every existing body, which is fine here
    // since we're about to clear them anyway.
    // Forge2DWorld.gravity is typed with flame's Vector2 (vector_math,
    // 32-bit), distinct from forge2d's own Vector2 (vector_math_64) used
    // everywhere else in the physics world — hence the explicit conversion.
    world.gravity = flame.Vector2(level.gravity.x, level.gravity.y);

    for (final wall in _walls) {
      wall.removeFromParent();
    }
    _walls.clear();

    final halfW = level.arenaWidth / 2;
    final halfH = level.arenaHeight / 2;
    final corners = <List<Vector2>>[
      [Vector2(-halfW, halfH), Vector2(halfW, halfH)], // ground
      [Vector2(-halfW, -halfH), Vector2(halfW, -halfH)], // ceiling
      [Vector2(-halfW, -halfH), Vector2(-halfW, halfH)], // left
      [Vector2(halfW, -halfH), Vector2(halfW, halfH)], // right
    ];
    for (final edge in corners) {
      final wall = BoundaryWall(start: edge[0], end: edge[1]);
      _walls.add(wall);
      world.add(wall);
    }

    camera.viewfinder.position = flame.Vector2.zero();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _applyWind(dt);
  }

  /// Wind is not a native Forge2D concept, so it's applied here as a
  /// per-tick force on every body that opts in via [WindAffected].
  /// F = wind_vector * mass * susceptibility, matching how gravity itself
  /// is applied internally (force = mass * acceleration).
  void _applyWind(double dt) {
    final level = _currentLevel;
    if (level == null || level.wind.length2 == 0) return;

    for (final component in world.children.query<BodyComponent>()) {
      if (component is! WindAffected) continue;
      final body = component.body;
      final force = level.wind * body.mass * component.windSusceptibility;
      body.applyForce(force);
    }
  }
}
