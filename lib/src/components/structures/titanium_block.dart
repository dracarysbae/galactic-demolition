import 'dart:ui';

import 'building_block.dart';

/// Dense, heavily reinforced structure. Its high density gives it enough
/// mass that projectiles struggle to move it at all, and it absorbs far
/// more impact than a typical block before breaking — meant to be routed
/// around or hit with something heavy (Booster) rather than punched
/// straight through.
class TitaniumBlock extends BuildingBlock {
  TitaniumBlock({
    required super.center,
    required super.halfWidth,
    required super.halfHeight,
  }) {
    final strokeWidth =
        (halfWidth < halfHeight ? halfWidth : halfHeight) * 0.12;
    _lightEdgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x99FFFFFF);
    _darkEdgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x66000000);
  }

  late final Paint _lightEdgePaint;
  late final Paint _darkEdgePaint;

  @override
  Color get color => const Color(0xFF9CA3AF);

  @override
  double get density => 12;

  @override
  double get friction => 0.6;

  @override
  double get restitution => 0.02;

  @override
  double get maxHealth => 60;

  /// A hand-drawn 3D bevel: a light stroke along the top/left edges and a
  /// dark one along bottom/right, as if lit from the upper-left — the
  /// classic "beveled panel" look, cheap to fake without a real light model.
  @override
  void renderAccents(Canvas canvas, RRect rrect) {
    final inset = rrect.tlRadius.x;
    canvas.drawLine(
      Offset(rrect.left + inset, rrect.top),
      Offset(rrect.right - inset, rrect.top),
      _lightEdgePaint,
    );
    canvas.drawLine(
      Offset(rrect.left, rrect.top + inset),
      Offset(rrect.left, rrect.bottom - inset),
      _lightEdgePaint,
    );
    canvas.drawLine(
      Offset(rrect.left + inset, rrect.bottom),
      Offset(rrect.right - inset, rrect.bottom),
      _darkEdgePaint,
    );
    canvas.drawLine(
      Offset(rrect.right, rrect.top + inset),
      Offset(rrect.right, rrect.bottom - inset),
      _darkEdgePaint,
    );
  }
}
