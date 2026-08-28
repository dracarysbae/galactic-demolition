import 'dart:ui';

import 'building_block.dart';

/// Lightweight, fragile structure. Breaks in one or two solid hits — good
/// for teaching the player how impact damage works without frustration.
class SolarPanelBlock extends BuildingBlock {
  SolarPanelBlock({
    required super.center,
    required super.halfWidth,
    required super.halfHeight,
  }) {
    _gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.02
      ..color = const Color(0x552563EB);
    _reflectionPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = halfHeight * 0.3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x33FFFFFF);
  }

  late final Paint _gridPaint;
  late final Paint _reflectionPaint;

  @override
  Color get color => const Color(0xFF3B82F6);

  @override
  double get density => 0.6;

  @override
  double get friction => 0.3;

  @override
  double get restitution => 0.1;

  @override
  double get maxHealth => 6;

  /// A cell grid (like real photovoltaic panels) plus a soft diagonal
  /// streak, standing in for a glassy reflection — reads as "glass panel"
  /// rather than a solid tile.
  @override
  void renderAccents(Canvas canvas, RRect rrect) {
    const columns = 3;
    for (var i = 1; i < columns; i++) {
      final x = rrect.left + rrect.width * i / columns;
      canvas.drawLine(
        Offset(x, rrect.top),
        Offset(x, rrect.bottom),
        _gridPaint,
      );
    }
    final midY = rrect.top + rrect.height * 0.5;
    canvas.drawLine(
      Offset(rrect.left, midY),
      Offset(rrect.right, midY),
      _gridPaint,
    );

    canvas.drawLine(
      Offset(rrect.left + rrect.width * 0.15, rrect.top + rrect.height * 0.85),
      Offset(rrect.left + rrect.width * 0.55, rrect.top + rrect.height * 0.15),
      _reflectionPaint,
    );
  }
}
