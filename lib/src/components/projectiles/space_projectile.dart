import 'dart:math';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../../galactic_demolition_game.dart';

/// Base class for every piece of launchable space junk.
///
/// Concrete subclasses (Booster, Meteor, Plasma Battery, ...) only need to
/// supply the physical properties ([radius], [density], [friction],
/// [restitution]); body/fixture creation and contact-callback wiring are
/// handled once here.
///
/// [TapCallbacks] is mixed in so that mid-flight special abilities (Meteor's
/// split, Plasma Battery's shockwave) can be implemented by overriding
/// [onTapDown] in a subclass — the default implementation does nothing, so
/// projectiles without an ability (e.g. Booster) don't need to opt out.
abstract class SpaceProjectile extends BodyComponent<GalacticDemolitionGame>
    with ContactCallbacks, TapCallbacks {
  SpaceProjectile({
    required Vector2 startPosition,
    required Vector2 initialVelocity,
  }) : _startPosition = startPosition,
       _initialVelocity = initialVelocity {
    final highlight = Color.lerp(color, const Color(0xFFFFFFFF), 0.55)!;
    _fillPaint = Paint()
      ..shader = Gradient.radial(
        Offset(-radius * 0.3, -radius * 0.3),
        radius * 1.4,
        [highlight, color],
      );
    _rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.12
      ..color = const Color(0x99000000);
  }

  final Vector2 _startPosition;
  final Vector2 _initialVelocity;

  // Built once above from the (constant) color/radius — render() only ever
  // draws with these, never allocates a Paint/Shader itself.
  late final Paint _fillPaint;
  late final Paint _rimPaint;

  /// Base color; [render] builds a radial highlight/rim around it rather
  /// than using it as a flat fill.
  Color get color;

  /// Collision radius in meters. Also drives mass via [density].
  double get radius;

  /// Mass per unit area, in kg/m^2 — higher values make the projectile
  /// harder for other bodies to push around and hit harder on impact.
  double get density;
  double get friction;

  /// Bounciness in [0, 1]. 0 = no bounce (Booster), closer to 1 = pinball-like.
  double get restitution;

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: _startPosition,
      linearVelocity: _initialVelocity,
      // Projectiles are launched fast enough to tunnel through thin
      // BuildingBlock fixtures in a single step without continuous
      // collision detection.
      bullet: true,
      userData: this,
    );
    final body = world.createBody(bodyDef);
    final shape = CircleShape(radius: radius);
    final fixtureDef = FixtureDef(
      shape,
      density: density,
      friction: friction,
      restitution: restitution,
    );
    body.createFixture(fixtureDef);
    return body;
  }

  @override
  void onTapDown(TapDownEvent event) {}

  /// Radial highlight (bright off-center hotspot fading to [color]) plus a
  /// dark rim — reads as a lit, rounded object with volume instead of a
  /// solid disc. Subclasses with a distinct look (Booster's metal, Meteor's
  /// rock, Plasma's neon) override this entirely.
  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset.zero, radius, _fillPaint);
    canvas.drawCircle(Offset.zero, radius, _rimPaint);
  }
}

/// Shared motion-streak trail for projectiles fast/heavy enough that they
/// should visibly show their recent path instead of just teleporting from
/// frame to frame (Booster, Meteor). Mix in, call [recordTrailPosition]
/// once per [update], and call [renderTrail] at the start of [render].
mixin MotionStreak on SpaceProjectile {
  final List<Vector2> _trailHistory = [];
  static const int _trailLength = 6;
  final Paint _trailPaint = Paint();

  void recordTrailPosition() {
    _trailHistory.insert(0, body.position.clone());
    if (_trailHistory.length > _trailLength) {
      _trailHistory.removeLast();
    }
  }

  /// Draws a fading streak through recent world positions.
  ///
  /// [render] runs inside a canvas already translated *and rotated* to the
  /// body's current transform (see `BodyComponent.renderTree`), so each
  /// history point — recorded in world space — is rotated by `-body.angle`
  /// before drawing to cancel that out; otherwise the trail would swing
  /// around with the body's own spin instead of staying laid out along its
  /// actual path.
  void renderTrail(Canvas canvas, Color streakColor) {
    if (_trailHistory.length < 2) {
      return;
    }
    final cosA = cos(-body.angle);
    final sinA = sin(-body.angle);
    final current = body.position;

    for (var i = 1; i < _trailHistory.length; i++) {
      final worldOffset = _trailHistory[i] - current;
      final localX = worldOffset.x * cosA - worldOffset.y * sinA;
      final localY = worldOffset.x * sinA + worldOffset.y * cosA;

      final fade = 1 - i / _trailHistory.length;
      _trailPaint.color = streakColor.withValues(alpha: fade * 0.3);
      canvas.drawCircle(
        Offset(localX, localY),
        radius * (1 - i / _trailHistory.length * 0.6),
        _trailPaint,
      );
    }
  }
}
