import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';

import '../components/projectiles/space_projectile.dart';
import '../galactic_demolition_game.dart';
import '../systems/trajectory_predictor.dart';

/// Drag-to-shoot input for launching a [SpaceProjectile] from a fixed
/// [origin] point.
///
/// Added directly as a child of the physics world (not the screen-space
/// viewport), so its own local coordinate space is already in world meters
/// — the same space bodies live in. That means drag positions need no
/// manual screen-to-world conversion, and the trajectory preview can be
/// drawn using the exact same coordinates the projectile will actually
/// launch with.
class SlingshotController extends PositionComponent
    with DragCallbacks, HasGameReference<GalacticDemolitionGame> {
  SlingshotController({
    required this.origin,
    this.maxPullDistance = 4,
    this.launchPower = 9,
    required this.projectileFactory,
  });

  /// The slingshot's fixed anchor point, in world meters.
  final Vector2 origin;

  /// How far the player can pull back, in meters. The drag point is clamped
  /// to this distance from [origin], so pulling further than the sling
  /// physically allows has no extra effect.
  final double maxPullDistance;

  /// Launch speed, in m/s, delivered at a full [maxPullDistance] pull.
  /// Scales down linearly for a shorter pull.
  final double launchPower;

  /// Builds the projectile to launch. Kept as a swappable factory rather
  /// than a hardcoded type so ammo selection (Booster/Meteor/Plasma) can be
  /// wired up independently of the drag/launch mechanics.
  SpaceProjectile Function(Vector2 startPosition, Vector2 initialVelocity)
  projectileFactory;

  Vector2? _pull;

  final Paint _bandPaint = Paint()
    ..color = const Color(0xFFCCCCCC)
    ..strokeWidth = 0.08
    ..strokeCap = StrokeCap.round;

  final Paint _trajectoryPaint = Paint()
    ..color = const Color(0x99FFFFFF)
    ..strokeWidth = 0.05;

  /// Covering the whole world with a hit-test that always succeeds means a
  /// drag can start anywhere on screen — precisely hitting a small anchor
  /// point is a poor touch-target on mobile.
  @override
  bool containsLocalPoint(Vector2 point) => true;

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _updatePull(event.localPosition);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    _updatePull(event.localEndPosition);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _launch();
  }

  void _updatePull(Vector2 worldPoint) {
    final offset = worldPoint - origin;
    final distance = offset.length;
    _pull = distance > maxPullDistance
        ? offset * (maxPullDistance / distance)
        : offset;
  }

  /// The projectile is flung opposite the pull direction, like a real
  /// slingshot: pulling down-left launches up-right. Power scales linearly
  /// with pull distance, reaching [launchPower] at a full [maxPullDistance]
  /// pull.
  Vector2 _launchVelocity(Vector2 pull) =>
      -pull * (launchPower / maxPullDistance);

  void _launch() {
    final pull = _pull;
    _pull = null;
    // A negligible pull is almost certainly an accidental tap, not an
    // intentional shot.
    if (pull == null || pull.length < 0.1) {
      return;
    }
    if (!game.gameState.consumeAmmo()) {
      return;
    }
    game.world.add(
      projectileFactory(origin.clone(), _launchVelocity(pull)),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final pull = _pull;
    if (pull == null) {
      return;
    }

    final pullPoint = origin + pull;
    canvas.drawLine(origin.toOffset(), pullPoint.toOffset(), _bandPaint);

    final level = game.currentLevel;
    final path = TrajectoryPredictor.samplePath(
      origin: origin,
      initialVelocity: _launchVelocity(pull),
      gravity: level.gravity,
      wind: level.wind,
    );
    TrajectoryPredictor.renderDashed(canvas, path, _trajectoryPaint);
  }
}
