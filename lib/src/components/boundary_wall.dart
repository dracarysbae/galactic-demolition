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
    final length = (end - start).length;
    final isHorizontal = (end.y - start.y).abs() < (end.x - start.x).abs();
    _halfWidth = isHorizontal ? length / 2 : thickness / 2;
    _halfHeight = isHorizontal ? thickness / 2 : length / 2;
  }

  final Vector2 start;
  final Vector2 end;
  final double thickness;

  late final double _halfWidth;
  late final double _halfHeight;

  @override
  Body createBody() {
    final center = (start + end) / 2;
    final bodyDef = BodyDef(type: BodyType.static, position: center);
    final body = world.createBody(bodyDef);

    final shape = PolygonShape()..setAsBoxXY(_halfWidth, _halfHeight);
    final fixtureDef = FixtureDef(shape)
      ..friction = 0.3
      ..restitution = 0.1;
    body.createFixture(fixtureDef);
    return body;
  }

  /// A plain slate-gray panel with a faint highlight edge, so the arena
  /// boundary reads as station hull plating rather than a debug outline.
  @override
  void render(Canvas canvas) {
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: _halfWidth * 2,
      height: _halfHeight * 2,
    );

    final fillPaint = Paint()
      ..shader = Gradient.linear(
        Offset(0, -_halfHeight),
        Offset(0, _halfHeight),
        [const Color(0xFF5B6472), const Color(0xFF333B47)],
      );
    canvas.drawRect(rect, fillPaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness * 0.06
      ..color = const Color(0x66000000);
    canvas.drawRect(rect, borderPaint);
  }
}
