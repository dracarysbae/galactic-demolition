import 'dart:math';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import 'space_projectile.dart';

/// Fires the Meteor's shrapnel. Kept private since fragments are an
/// implementation detail of the split, not a projectile a player selects
/// or launches directly — they can't split further.
class _MeteorFragment extends SpaceProjectile {
  _MeteorFragment({
    required super.startPosition,
    required super.initialVelocity,
  });

  @override
  Color get color => const Color(0xFFA8A29E);

  @override
  double get radius => 0.2;

  @override
  double get density => 3;

  @override
  double get friction => 0.5;

  @override
  double get restitution => 0.2;
}

/// Splits into three smaller fragments when tapped mid-flight, trading one
/// concentrated hit for a wider spread of smaller impacts — good against
/// clusters of low-health blocks like Solar Panels.
class MeteorProjectile extends SpaceProjectile {
  MeteorProjectile({
    required super.startPosition,
    required super.initialVelocity,
  });

  /// Angle, in radians, each of the two outer fragments is deflected from
  /// the parent's velocity direction.
  static const double _spreadAngle = 0.35; // ~20 degrees

  /// Fragments keep most, but not all, of the parent's speed — the split
  /// itself absorbs some kinetic energy, same as a real fragmentation.
  static const double _fragmentSpeedFactor = 0.75;

  @override
  Color get color => const Color(0xFF78716C);

  @override
  double get radius => 0.45;

  @override
  double get density => 5;

  @override
  double get friction => 0.6;

  @override
  double get restitution => 0.1;

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    _split();
  }

  void _split() {
    final origin = body.position.clone();
    final velocity = body.linearVelocity;
    final speed = velocity.length;

    // A stationary or barely-moving meteor has no meaningful direction to
    // spread fragments along; skip the split rather than dividing by zero.
    if (speed < 0.01) {
      removeFromParent();
      return;
    }

    final direction = velocity / speed;
    final fragmentSpeed = speed * _fragmentSpeedFactor;

    for (final angle in [-_spreadAngle, 0.0, _spreadAngle]) {
      final rotated = _rotate(direction, angle) * fragmentSpeed;
      world.add(
        _MeteorFragment(startPosition: origin, initialVelocity: rotated),
      );
    }

    removeFromParent();
  }

  /// Rotates a 2D vector by [radians] counter-clockwise, using the standard
  /// 2x2 rotation matrix: [x', y'] = [x*cos - y*sin, x*sin + y*cos].
  Vector2 _rotate(Vector2 v, double radians) {
    final cosA = cos(radians);
    final sinA = sin(radians);
    return Vector2(v.x * cosA - v.y * sinA, v.x * sinA + v.y * cosA);
  }
}
