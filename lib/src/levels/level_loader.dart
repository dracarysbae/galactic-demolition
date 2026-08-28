import 'package:flame_forge2d/flame_forge2d.dart';

import '../components/structures/building_block.dart';
import '../components/structures/coolant_tank_block.dart';
import '../components/structures/repulsion_shield_block.dart';
import '../components/structures/solar_panel_block.dart';
import '../components/structures/titanium_block.dart';
import '../components/target_core.dart';
import '../config/level_config.dart';

/// Builds the destructible structure for a level: a small stacked base
/// topped with the [TargetCore], plus a standalone bumper obstacle.
///
/// Kept separate from [GalacticDemolitionGame] so level layout (what gets
/// built) stays independent of level *environment* (gravity/wind), and so
/// a real level-authoring format (e.g. loading layouts from data) can
/// replace this without touching the game/physics wiring.
class LevelLoader {
  LevelLoader._();

  /// Spawns the demo structure into [world] and returns every block that
  /// was added, so the caller can track and later remove them.
  static List<BuildingBlock> spawnDemoStructure(
    Forge2DWorld world,
    LevelConfig level,
  ) {
    final groundY = level.arenaHeight / 2;
    final baseX = level.arenaWidth / 2 * 0.45;
    final blocks = <BuildingBlock>[];

    // Stacks blocks upward from the ground at `baseX`, each one sitting
    // directly on top of the last.
    var topY = groundY;
    void stack(BuildingBlock Function(Vector2 center) build, double halfHeight) {
      final center = Vector2(baseX, topY - halfHeight);
      topY -= halfHeight * 2;
      final block = build(center);
      blocks.add(block);
      world.add(block);
    }

    stack(
      (c) => TitaniumBlock(center: c, halfWidth: 0.6, halfHeight: 1.2),
      1.2,
    );
    stack(
      (c) => SolarPanelBlock(center: c, halfWidth: 0.6, halfHeight: 0.6),
      0.6,
    );
    stack(
      (c) => CoolantTankBlock(center: c, halfWidth: 0.6, halfHeight: 0.6),
      0.6,
    );
    stack(
      (c) => TargetCore(center: c, halfWidth: 0.8, halfHeight: 0.8),
      0.8,
    );

    // A standalone bumper obstacle between the slingshot and the base.
    final shield = RepulsionShieldBlock(
      center: Vector2(baseX - 6, groundY - 1),
      halfWidth: 0.5,
      halfHeight: 1,
    );
    blocks.add(shield);
    world.add(shield);

    return blocks;
  }
}
