import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galactic_demolition/src/systems/trajectory_predictor.dart';

void main() {
  group('TrajectoryPredictor.samplePath', () {
    test('first point is always the origin', () {
      final path = TrajectoryPredictor.samplePath(
        origin: Vector2(1, 2),
        initialVelocity: Vector2(5, 0),
        gravity: Vector2.zero(),
        wind: Vector2.zero(),
        steps: 10,
      );
      expect(path.first, Vector2(1, 2));
    });

    test('produces steps + 1 points', () {
      final path = TrajectoryPredictor.samplePath(
        origin: Vector2.zero(),
        initialVelocity: Vector2(1, 0),
        gravity: Vector2.zero(),
        wind: Vector2.zero(),
        steps: 7,
      );
      expect(path.length, 8);
    });

    test('with no gravity/wind, moves in a straight line at constant velocity', () {
      final path = TrajectoryPredictor.samplePath(
        origin: Vector2.zero(),
        initialVelocity: Vector2(2, 0),
        gravity: Vector2.zero(),
        wind: Vector2.zero(),
        steps: 4,
        stepDuration: 0.5,
      );
      // Semi-implicit Euler with constant (zero) acceleration is exact:
      // position after n steps of dt = initialVelocity * (n * dt).
      expect(path[1].x, closeTo(1.0, 1e-9)); // 2 * 0.5
      expect(path[2].x, closeTo(2.0, 1e-9));
      expect(path[4].x, closeTo(4.0, 1e-9));
      for (final point in path) {
        expect(point.y, closeTo(0, 1e-9));
      }
    });

    test('gravity curves the path downward over time', () {
      final path = TrajectoryPredictor.samplePath(
        origin: Vector2.zero(),
        initialVelocity: Vector2(3, 0),
        gravity: Vector2(0, 10),
        wind: Vector2.zero(),
        steps: 5,
        stepDuration: 0.1,
      );
      // y should be monotonically non-decreasing (gravity pulls toward +y)
      // and strictly increasing once velocity has accumulated.
      for (var i = 1; i < path.length; i++) {
        expect(path[i].y, greaterThanOrEqualTo(path[i - 1].y));
      }
      expect(path.last.y, greaterThan(0));
    });

    test('wind adds a constant lateral acceleration', () {
      final noWind = TrajectoryPredictor.samplePath(
        origin: Vector2.zero(),
        initialVelocity: Vector2(0, 0),
        gravity: Vector2.zero(),
        wind: Vector2.zero(),
        steps: 3,
        stepDuration: 0.2,
      );
      final withWind = TrajectoryPredictor.samplePath(
        origin: Vector2.zero(),
        initialVelocity: Vector2(0, 0),
        gravity: Vector2.zero(),
        wind: Vector2(5, 0),
        steps: 3,
        stepDuration: 0.2,
      );
      expect(noWind.last.x, closeTo(0, 1e-9));
      expect(withWind.last.x, greaterThan(0));
    });
  });
}
