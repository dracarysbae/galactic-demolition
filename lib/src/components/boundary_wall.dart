import 'dart:ui';

import 'package:flame_forge2d/flame_forge2d.dart';

/// A single static edge of the play area (ground, ceiling, left/right walls).
///
/// Built as a thin static box rather than a raw edge shape so it has
/// well-defined thickness for fixture friction/restitution tuning later
/// (e.g. a bouncier "arena wall" variant could subclass this).
class BoundaryWall extends BodyComponent {
  BoundaryWall({
    required this.start,
    required this.end,
    this.thickness = 0.5,
  }) {
    paint.color = const Color(0xFF4B5563);
  }

  final Vector2 start;
  final Vector2 end;
  final double thickness;

  @override
  Body createBody() {
    final center = (start + end) / 2;
    final bodyDef = BodyDef(
      type: BodyType.static,
      position: center,
    );
    final body = world.createBody(bodyDef);

    final length = (end - start).length;
    final isHorizontal = (end.y - start.y).abs() < (end.x - start.x).abs();
    final halfWidth = isHorizontal ? length / 2 : thickness / 2;
    final halfHeight = isHorizontal ? thickness / 2 : length / 2;

    final shape = PolygonShape()..setAsBoxXY(halfWidth, halfHeight);
    final fixtureDef = FixtureDef(shape)
      ..friction = 0.3
      ..restitution = 0.1;
    body.createFixture(fixtureDef);
    return body;
  }
}
