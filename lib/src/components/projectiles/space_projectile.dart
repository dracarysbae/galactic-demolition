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
       _initialVelocity = initialVelocity;

  final Vector2 _startPosition;
  final Vector2 _initialVelocity;

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
}
