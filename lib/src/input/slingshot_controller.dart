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
  }) {
    final baseRect = Rect.fromCenter(
      center: (origin + Vector2(0, 0.15)).toOffset(),
      width: 1.6,
      height: 0.3,
    );
    _baseRRect = RRect.fromRectAndRadius(baseRect, const Radius.circular(0.1));
  }

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

  // The fork is drawn relative to `origin`, prongs pointing "up" (world -y).
  static final Vector2 _prongOffset = Vector2(0.45, -1.2);
  static final Vector2 _restOffset = Vector2(0, -0.35);

  static const Color _metalColor = Color(0xFFB6BEC9);
  static const Color _bandColor = Color(0xFF4B5563);
  static const Color _trajectoryColor = Color(0xFF67E8F9);
  static const Color _chargeColor = Color(0xFFFB923C);

  late final RRect _baseRRect;
  late final Paint _basePaint = Paint()
    ..shader = Gradient.linear(
      _baseRRect.outerRect.topCenter,
      _baseRRect.outerRect.bottomCenter,
      const [Color(0xFF6B7280), Color(0xFF1F2937)],
    );

  late final Paint _prongPaint = Paint()
    ..shader = Gradient.linear(
      _leftProngTip.toOffset(),
      origin.toOffset(),
      const [Color(0xFFE5E7EB), _metalColor],
    )
    ..strokeWidth = 0.12
    ..strokeCap = StrokeCap.round;

  late final Paint _bandPaint = Paint()
    ..color = _bandColor
    ..strokeWidth = 0.06
    ..strokeCap = StrokeCap.round;

  late final Paint _pouchPaint = Paint()..color = _bandColor;

  // Pulsing "charge" ring around the pouch — brighter/wider the further the
  // player pulls back. Mutated per-frame, never reallocated.
  late final Paint _chargeGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.06);

  late final Paint _trajectoryGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.09);
  final Paint _trajectoryCorePaint = Paint();

  Vector2 get _leftProngTip =>
      origin + Vector2(-_prongOffset.x, _prongOffset.y);
  Vector2 get _rightProngTip => origin + _prongOffset;
  Vector2 get _pouchPosition => origin + (_pull ?? _restOffset);

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

    canvas.drawRRect(_baseRRect, _basePaint);

    final leftTip = _leftProngTip.toOffset();
    final rightTip = _rightProngTip.toOffset();
    final base = origin.toOffset();
    final pouch = _pouchPosition.toOffset();

    // Fork posts, drawn every frame so the player always has a visible
    // anchor to aim from, not just while actively dragging.
    canvas.drawLine(base, leftTip, _prongPaint);
    canvas.drawLine(base, rightTip, _prongPaint);

    // Bands run from each prong tip to the pouch — a real slingshot's Y
    // shape — rather than a single line straight to the pull point.
    canvas.drawLine(leftTip, pouch, _bandPaint);
    canvas.drawLine(rightTip, pouch, _bandPaint);

    final pull = _pull;
    final chargeFraction = pull == null
        ? 0.0
        : (pull.length / maxPullDistance).clamp(0.0, 1.0);
    if (chargeFraction > 0) {
      _chargeGlowPaint
        ..strokeWidth = 0.03 + chargeFraction * 0.08
        ..color = _chargeColor.withValues(alpha: 0.4 + chargeFraction * 0.6);
      canvas.drawCircle(pouch, 0.14 + chargeFraction * 0.08, _chargeGlowPaint);
    }
    canvas.drawCircle(pouch, 0.14, _pouchPaint);

    if (pull == null) {
      return;
    }

    final level = game.currentLevel;
    final path = TrajectoryPredictor.samplePath(
      origin: origin,
      initialVelocity: _launchVelocity(pull),
      gravity: level.gravity,
      wind: level.wind,
    );
    TrajectoryPredictor.renderGlowingDots(
      canvas,
      path,
      _trajectoryColor,
      _trajectoryGlowPaint,
      _trajectoryCorePaint,
    );
  }
}
