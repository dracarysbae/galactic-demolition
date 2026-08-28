import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galactic_demolition/src/systems/explosion_system.dart';

Body _addDynamicBody(Forge2DWorld world, Vector2 position) {
  final body = world.createBody(
    BodyDef(type: BodyType.dynamic, position: position),
  );
  body.createFixture(FixtureDef(CircleShape(radius: 0.5), density: 1));
  return body;
}

void main() {
  group('ExplosionSystem.applyShockwave', () {
    test('pushes a nearby dynamic body away from the blast origin', () {
      final world = Forge2DWorld(gravity: Vector2.zero());
      final body = _addDynamicBody(world, Vector2(2, 0));

      ExplosionSystem.applyShockwave(
        world: world,
        origin: Vector2.zero(),
        radius: 5,
        strength: 10,
      );

      // The body sits directly on the +x axis from the origin, so the
      // shockwave should push it further in +x with no y component.
      expect(body.linearVelocity.x, greaterThan(0));
      expect(body.linearVelocity.y, closeTo(0, 1e-9));
    });

    test('applies more velocity change closer to the blast center', () {
      final world = Forge2DWorld(gravity: Vector2.zero());
      final near = _addDynamicBody(world, Vector2(1, 0));
      final far = _addDynamicBody(world, Vector2(4, 0));

      ExplosionSystem.applyShockwave(
        world: world,
        origin: Vector2.zero(),
        radius: 5,
        strength: 10,
      );

      expect(near.linearVelocity.x, greaterThan(far.linearVelocity.x));
    });

    test('does not affect bodies outside the blast radius', () {
      final world = Forge2DWorld(gravity: Vector2.zero());
      final body = _addDynamicBody(world, Vector2(10, 0));

      ExplosionSystem.applyShockwave(
        world: world,
        origin: Vector2.zero(),
        radius: 5,
        strength: 10,
      );

      expect(body.linearVelocity.length, 0);
    });

    test('does not affect static bodies', () {
      final world = Forge2DWorld(gravity: Vector2.zero());
      final body = world.createBody(
        BodyDef(type: BodyType.static, position: Vector2(1, 0)),
      );
      body.createFixture(FixtureDef(CircleShape(radius: 0.5), density: 1));

      ExplosionSystem.applyShockwave(
        world: world,
        origin: Vector2.zero(),
        radius: 5,
        strength: 10,
      );

      expect(body.linearVelocity.length, 0);
    });
  });
}
