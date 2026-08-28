import 'package:flame/components.dart' show Anchor;
import 'package:flame_forge2d/flame_forge2d.dart';

import 'components/boundary_wall.dart';
import 'components/projectiles/booster_projectile.dart';
import 'components/projectiles/space_projectile.dart';
import 'components/structures/building_block.dart';
import 'components/wind_affected.dart';
import 'config/level_config.dart';
import 'game_state.dart';
import 'input/slingshot_controller.dart';
import 'levels/level_loader.dart';

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
  final List<BuildingBlock> _structures = [];

  SlingshotController? slingshot;

  static const double _pixelsPerMeter = 20;
  static const int _startingAmmo = 8;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    camera.viewfinder.zoom = _pixelsPerMeter;
    camera.viewfinder.anchor = Anchor.center;
  }

  /// Tears down the previous level's walls/bodies and configures the world
  /// for [level]: sets gravity, rebuilds boundary walls sized to the arena,
  /// and centers the camera on the arena.
  void loadLevel(LevelConfig level) {
    _currentLevel = level;

    // Setting `world.gravity` wakes every existing body, which is fine here
    // since we're about to clear them anyway.
    world.gravity = level.gravity;

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

    slingshot?.removeFromParent();
    slingshot = SlingshotController(
      origin: Vector2(-halfW * 0.7, halfH * 0.5),
      projectileFactory: (position, velocity) => BoosterProjectile(
        startPosition: position,
        initialVelocity: velocity,
      ),
    );
    world.add(slingshot!);

    for (final structure in _structures) {
      structure.removeFromParent();
    }
    _structures
      ..clear()
      ..addAll(LevelLoader.spawnDemoStructure(world, level));

    gameState
      ..reset()
      ..setAmmoRemaining(_startingAmmo);

    camera.viewfinder.position = Vector2.zero();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _applyWind(dt);
    _checkOutOfAmmo();
  }

  /// The player has lost once every shot has been fired, none are still in
  /// flight, and the target still stands. Waiting for in-flight projectiles
  /// to clear avoids calling it too early on the very shot that would have
  /// won — e.g. a Meteor's fragments are still airborne after the parent is
  /// removed.
  void _checkOutOfAmmo() {
    if (gameState.ammoRemaining > 0 ||
        gameState.isLevelComplete ||
        gameState.isGameOver) {
      return;
    }
    final hasActiveProjectile = world.children
        .query<BodyComponent>()
        .any((component) => component is SpaceProjectile);
    if (!hasActiveProjectile) {
      gameState.gameOver();
    }
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
