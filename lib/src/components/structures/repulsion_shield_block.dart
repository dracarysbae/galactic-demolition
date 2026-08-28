import 'dart:math';
import 'dart:ui';

import 'building_block.dart';

/// Near-perfectly elastic structure — behaves like a pinball bumper,
/// redirecting most of a projectile's momentum back out rather than
/// absorbing it. Low friction keeps the bounce clean instead of scrubbing
/// off speed on the way out.
class RepulsionShieldBlock extends BuildingBlock {
  RepulsionShieldBlock({
    required super.center,
    required super.halfWidth,
    required super.halfHeight,
  });

  // Mutated in place each frame (strokeWidth/maskFilter/color), never
  // replaced with a new Paint() — only the animated glow parameters change.
  final Paint _glowPaint = Paint()..style = PaintingStyle.stroke;

  double _pulseTime = 0;

  @override
  Color get color => const Color(0xFF22D3EE);

  @override
  double get density => 2;

  @override
  double get friction => 0.05;

  @override
  double get restitution => 0.95;

  @override
  double get maxHealth => 25;

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTime += dt;
  }

  /// A neon rim that breathes in and out — signals "this bounces you" at a
  /// glance, and the pulse gives an otherwise-static block some life.
  @override
  void renderAccents(Canvas canvas, RRect rrect) {
    final pulse = (sin(_pulseTime * 4) + 1) / 2; // oscillates 0..1
    _glowPaint
      ..strokeWidth = 0.05 + pulse * 0.05
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.1 + pulse * 0.15)
      ..color = color.withValues(alpha: 0.55 + pulse * 0.45);
    canvas.drawRRect(rrect.deflate(0.03), _glowPaint);
  }
}
