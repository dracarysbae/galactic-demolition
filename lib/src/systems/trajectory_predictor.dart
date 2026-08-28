import 'dart:ui';

import 'package:flame/extensions.dart';

/// Computes and draws a ballistic preview path, so the player can see
/// roughly where a slingshot launch will go before releasing it.
class TrajectoryPredictor {
  TrajectoryPredictor._();

  /// Samples points along the path a body would follow starting at [origin]
  /// with [initialVelocity], under constant [gravity] and [wind]
  /// accelerations.
  ///
  /// Uses simple constant-acceleration (semi-implicit Euler) kinematics per
  /// step — `velocity += acceleration * dt; position += velocity * dt` —
  /// the same integration Box2D itself uses internally. It intentionally
  /// ignores drag, restitution, and collisions: this is a *preview* of the
  /// unobstructed flight path, not a re-simulation of the physics world, so
  /// it only needs to be visually close, not exact.
  static List<Vector2> samplePath({
    required Vector2 origin,
    required Vector2 initialVelocity,
    required Vector2 gravity,
    required Vector2 wind,
    int steps = 40,
    double stepDuration = 0.05,
  }) {
    final acceleration = gravity + wind;
    var position = origin.clone();
    var velocity = initialVelocity.clone();
    final points = <Vector2>[position.clone()];

    for (var i = 0; i < steps; i++) {
      velocity = velocity + acceleration * stepDuration;
      position = position + velocity * stepDuration;
      points.add(position.clone());
    }
    return points;
  }

  /// Renders [points] as a dashed line.
  ///
  /// A solid line would read as a real rail/trajectory the projectile is
  /// bound to; dashing is the standard visual language for "this is a
  /// prediction, not a guarantee."
  static void renderDashed(
    Canvas canvas,
    List<Vector2> points,
    Paint paint, {
    double dashLength = 0.15,
    double gapLength = 0.1,
  }) {
    for (var i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      final segment = end - start;
      final segmentLength = segment.length;
      if (segmentLength == 0) {
        continue;
      }
      final direction = segment..scale(1 / segmentLength);

      var drawn = 0.0;
      var isDash = true;
      while (drawn < segmentLength) {
        final remaining = segmentLength - drawn;
        final pieceLength = (isDash ? dashLength : gapLength).clamp(
          0.0,
          remaining,
        );
        if (isDash) {
          final from = start + direction * drawn;
          final to = start + direction * (drawn + pieceLength);
          canvas.drawLine(from.toOffset(), to.toOffset(), paint);
        }
        drawn += pieceLength;
        isDash = !isDash;
      }
    }
  }
}
