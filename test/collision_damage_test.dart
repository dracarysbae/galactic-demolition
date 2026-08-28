import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galactic_demolition/src/systems/collision_system.dart';

void main() {
  group('CollisionDamage.impulseMagnitude', () {
    test('is zero for an untouched impulse', () {
      final impulse = ContactImpulse();
      expect(CollisionDamage.impulseMagnitude(impulse), 0);
    });

    test('combines normal and tangent impulse per point via Pythagoras', () {
      final impulse = ContactImpulse()..count = 1;
      impulse.normalImpulses[0] = 3;
      impulse.tangentImpulses[0] = 4;

      // sqrt(3^2 + 4^2) = 5.
      expect(CollisionDamage.impulseMagnitude(impulse), 5);
    });

    test('sums magnitudes across every active manifold point', () {
      final impulse = ContactImpulse()..count = 2;
      impulse.normalImpulses[0] = 3;
      impulse.tangentImpulses[0] = 4;
      impulse.normalImpulses[1] = 6;
      impulse.tangentImpulses[1] = 8;

      // 5 (first point) + 10 (second point).
      expect(CollisionDamage.impulseMagnitude(impulse), 15);
    });

    test('ignores manifold points beyond count', () {
      final impulse = ContactImpulse()..count = 1;
      impulse.normalImpulses[0] = 3;
      impulse.tangentImpulses[0] = 4;
      // These are past `count` and must not be included.
      impulse.normalImpulses[1] = 100;
      impulse.tangentImpulses[1] = 100;

      expect(CollisionDamage.impulseMagnitude(impulse), 5);
    });
  });
}
