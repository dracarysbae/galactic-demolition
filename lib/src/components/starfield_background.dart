import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../galactic_demolition_game.dart';

/// A fixed field of small stars behind the play area.
///
/// Added to the camera's viewport (screen space), not the physics world, so
/// it stays put regardless of camera zoom/pan and never needs to be rebuilt
/// between levels — it's set dressing, not gameplay.
class StarfieldBackground extends PositionComponent
    with HasGameReference<GalacticDemolitionGame> {
  StarfieldBackground({this.starCount = 140});

  final int starCount;

  final List<Offset> _positions = [];
  final List<double> _radii = [];
  final List<double> _alphas = [];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = game.size;
    final random = Random(42); // fixed seed: same field every launch.
    for (var i = 0; i < starCount; i++) {
      _positions.add(
        Offset(random.nextDouble() * size.x, random.nextDouble() * size.y),
      );
      _radii.add(0.6 + random.nextDouble() * 1.4);
      _alphas.add(0.25 + random.nextDouble() * 0.6);
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint();
    for (var i = 0; i < _positions.length; i++) {
      paint.color = Color.fromRGBO(255, 255, 255, _alphas[i]);
      canvas.drawCircle(_positions[i], _radii[i], paint);
    }
  }
}
