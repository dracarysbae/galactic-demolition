import 'dart:math';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import 'space_projectile.dart';

/// A single darker "crater" blob drawn over a meteor's base fill, faking a
/// rocky surface without needing a texture asset.
class _Crater {
  const _Crater(this.offset, this.radius);
  final Offset offset;
  final double radius;
}

List<_Crater> _generateCraters(double radius, int count, int seed) {
  final random = Random(seed);
  return List.generate(count, (_) {
    final angle = random.nextDouble() * pi * 2;
    final distance = random.nextDouble() * radius * 0.5;
    final craterRadius = radius * (0.15 + random.nextDouble() * 0.22);
    return _Crater(
      Offset(cos(angle), sin(angle)) * distance,
      craterRadius,
    );
  });
}

/// Fires the Meteor's shrapnel. Kept private since fragments are an
/// implementation detail of the split, not a projectile a player selects
/// or launches directly — they can't split further.
class _MeteorFragment extends SpaceProjectile {
  _MeteorFragment({
    required super.startPosition,
    required super.initialVelocity,
  }) {
    _bodyPaint = Paint()..color = const Color(0xFFA8A29E);
    _craters = _generateCraters(radius, 2, hashCode);
  }

  late final Paint _bodyPaint;
  late final List<_Crater> _craters;
  final Paint _craterPaint = Paint()..color = const Color(0x552B2521);

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

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset.zero, radius, _bodyPaint);
    for (final crater in _craters) {
      canvas.drawCircle(crater.offset, crater.radius, _craterPaint);
    }
  }
}

/// Splits into three smaller fragments when tapped mid-flight, trading one
/// concentrated hit for a wider spread of smaller impacts — good against
/// clusters of low-health blocks like Solar Panels.
class MeteorProjectile extends SpaceProjectile {
  MeteorProjectile({
    required super.startPosition,
    required super.initialVelocity,
  }) {
    _bodyPaint = Paint()..color = const Color(0xFF78716C);
    _craters = _generateCraters(radius, 5, hashCode);
    _rimGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.22
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.06)
      ..color = const Color(0xFFF97316);
  }

  late final Paint _bodyPaint;
  late final List<_Crater> _craters;
  final Paint _craterPaint = Paint()..color = const Color(0x552B2521);
  late final Paint _rimGlowPaint;

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

  /// A rocky body (base fill + overlapping darker "craters") with a glowing
  /// fiery rim, like atmospheric-entry heat — replaces the base class's
  /// plain lit-sphere look entirely.
  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset.zero, radius, _bodyPaint);
    for (final crater in _craters) {
      canvas.drawCircle(crater.offset, crater.radius, _craterPaint);
    }
    canvas.drawCircle(Offset.zero, radius, _rimGlowPaint);
  }
}
