import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../galactic_demolition_game.dart';

class _Star {
  _Star(this.position, this.radius, this.alpha, this.glow);
  final Offset position;
  final double radius;
  final double alpha;
  final bool glow;
}

class _Dust {
  _Dust(this.position, this.velocity, this.radius);
  Offset position;
  final Offset velocity;
  final double radius;
}

/// Layered procedural deep-space backdrop: soft nebula blobs, a bloom-lit
/// starfield, and a fast-drifting dust layer, for a sense of parallax depth.
///
/// Everything here is drawn with gradients/blur rather than image assets —
/// the project ships no sprite files — so this reaches for the same
/// layered-depth look Flame's image-based `ParallaxComponent` would, without
/// needing art. Added to the camera's viewport (screen space), so it stays
/// fixed regardless of world zoom/pan.
class DeepSpaceBackground extends PositionComponent
    with HasGameReference<GalacticDemolitionGame> {
  DeepSpaceBackground({
    this.nebulaCount = 3,
    this.starCount = 160,
    this.dustCount = 45,
  });

  final int nebulaCount;
  final int starCount;
  final int dustCount;

  final List<_Star> _stars = [];
  final List<_Dust> _dust = [];

  // Every Paint/Shader used in render() is built once here (or has only its
  // `color` field mutated per-draw) rather than allocated per frame.
  final List<Offset> _nebulaCenters = [];
  final List<double> _nebulaRadii = [];
  final List<Paint> _nebulaPaints = [];

  late final Paint _starPaint = Paint();
  late final Paint _glowStarPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  late final Paint _dustPaint = Paint()..color = const Color(0x66E5E7EB);

  static const List<Color> _nebulaColors = [
    Color(0xFF7C3AED),
    Color(0xFF0EA5E9),
    Color(0xFFDB2777),
  ];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = game.size;
    final random = Random(7); // fixed seed: same field every launch.

    for (var i = 0; i < nebulaCount; i++) {
      final center = Offset(
        random.nextDouble() * size.x,
        random.nextDouble() * size.y,
      );
      final radius = size.x * (0.28 + random.nextDouble() * 0.2);
      final color = _nebulaColors[i % _nebulaColors.length];
      _nebulaCenters.add(center);
      _nebulaRadii.add(radius);
      _nebulaPaints.add(
        Paint()
          ..shader = Gradient.radial(center, radius, [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0),
          ]),
      );
    }

    for (var i = 0; i < starCount; i++) {
      final glow = random.nextDouble() > 0.9;
      _stars.add(
        _Star(
          Offset(random.nextDouble() * size.x, random.nextDouble() * size.y),
          glow
              ? 1.6 + random.nextDouble() * 1.4
              : 0.5 + random.nextDouble() * 1.2,
          0.25 + random.nextDouble() * 0.65,
          glow,
        ),
      );
    }

    for (var i = 0; i < dustCount; i++) {
      final angle = random.nextDouble() * pi * 2;
      final speed = 8 + random.nextDouble() * 14;
      _dust.add(
        _Dust(
          Offset(random.nextDouble() * size.x, random.nextDouble() * size.y),
          Offset(cos(angle), sin(angle)) * speed,
          0.6 + random.nextDouble() * 1.0,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final d in _dust) {
      var next = d.position + d.velocity * dt;
      if (next.dx < 0) next += Offset(size.x, 0);
      if (next.dx > size.x) next -= Offset(size.x, 0);
      if (next.dy < 0) next += Offset(0, size.y);
      if (next.dy > size.y) next -= Offset(0, size.y);
      d.position = next;
    }
  }

  @override
  void render(Canvas canvas) {
    for (var i = 0; i < _nebulaCenters.length; i++) {
      canvas.drawCircle(_nebulaCenters[i], _nebulaRadii[i], _nebulaPaints[i]);
    }

    for (final star in _stars) {
      final paint = star.glow ? _glowStarPaint : _starPaint;
      paint.color = Color.fromRGBO(255, 255, 255, star.alpha);
      canvas.drawCircle(star.position, star.radius, paint);
    }

    for (final d in _dust) {
      canvas.drawCircle(d.position, d.radius, _dustPaint);
    }
  }
}
