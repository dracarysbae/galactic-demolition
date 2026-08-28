import 'dart:ui';

import 'package:flame_forge2d/flame_forge2d.dart';

import '../../galactic_demolition_game.dart';
import '../../systems/collision_system.dart';
import '../../systems/particle_effects.dart';

/// Base class for every destructible piece of an AI base.
///
/// Concrete subclasses (Solar Panel, Titanium, Repulsion Shield, Coolant
/// Tank, ...) only need to supply physical properties and [maxHealth]; body
/// creation and impact-damage bookkeeping are handled once here so damage
/// math can't drift between block types.
abstract class BuildingBlock extends BodyComponent<GalacticDemolitionGame>
    with ContactCallbacks {
  BuildingBlock({
    required Vector2 center,
    required this.halfWidth,
    required this.halfHeight,
  }) : _center = center {
    final shortSide = halfWidth < halfHeight ? halfWidth : halfHeight;
    final cornerRadius = shortSide * 0.25;
    _rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: halfWidth * 2,
        height: halfHeight * 2,
      ),
      Radius.circular(cornerRadius),
    );
    _shadowRRect = _rrect.shift(const Offset(0.05, 0.09));
    _borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerRadius * 0.3
      ..color = const Color(0xB3000000);
    _rimLightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = shortSide * 0.06
      ..color = const Color(0x77FFFFFF);
    _ambientOcclusionPaint = Paint()
      ..shader = Gradient.linear(
        Offset(0, halfHeight * 0.4),
        Offset(0, halfHeight),
        const [Color(0x00000000), Color(0x70000000)],
      );
    _refreshFillShader();
  }

  final Vector2 _center;
  final double halfWidth;
  final double halfHeight;

  /// Base fill color; [render] derives the actual gradient/damage tint
  /// from this rather than using it directly.
  Color get color;

  double get density;
  double get friction;

  /// Bounciness in [0, 1]. Near 1 makes the block act like a pinball bumper
  /// (see Repulsion Shield).
  double get restitution;

  /// Total impact impulse this block can absorb before breaking, in kg·m/s.
  /// Lower values break more easily (Solar Panel); higher values resist
  /// being moved or destroyed (Titanium).
  double get maxHealth;

  late double health = maxHealth;
  bool get isDestroyed => health <= 0;

  /// Score awarded when this block is destroyed. Defaults to [maxHealth]
  /// rounded — tougher blocks are worth proportionally more to destroy —
  /// but subclasses can override for a flat/curated value instead.
  int get scoreValue => maxHealth.round();

  // Cached render state — everything here is built once (in the
  // constructor) or refreshed only when [health] actually changes, never
  // reallocated inside [render] itself.
  late final RRect _rrect;
  late final RRect _shadowRRect;
  late final Paint _borderPaint;
  late final Paint _rimLightPaint;
  late final Paint _ambientOcclusionPaint;
  final Paint _fillPaint = Paint();
  final Paint _shadowPaint = Paint()
    ..color = const Color(0x55000000)
    // Sigma is in local (meter) units, which the camera then scales up by
    // its zoom factor — a tiny sigma here still reads as a soft multi-pixel
    // blur on screen.
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.12);

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: _center,
      userData: this,
    );
    final body = world.createBody(bodyDef);
    final shape = PolygonShape()..setAsBoxXY(halfWidth, halfHeight);
    final fixtureDef = FixtureDef(
      shape,
      density: density,
      friction: friction,
      restitution: restitution,
    );
    body.createFixture(fixtureDef);
    return body;
  }

  /// Impacts only actually damage a block once the physics solver has
  /// resolved them — [postSolve] is where Box2D reports the impulses that
  /// were needed to keep the bodies from interpenetrating, which is the
  /// "how hard did this hit" number [CollisionDamage] converts to damage.
  @override
  void postSolve(Object other, Contact contact, ContactImpulse impulse) {
    super.postSolve(other, contact, impulse);
    applyDamage(CollisionDamage.impulseMagnitude(impulse));
  }

  void applyDamage(double amount) {
    if (isDestroyed || amount <= 0) {
      return;
    }
    health -= amount;
    // Every solid hit throws a few sparks, whether or not the block
    // survives — a hit should always feel tactile, not just a broken one.
    if (amount > 1) {
      game.world.add(ParticleEffects.sparks(origin: body.position.clone()));
    }
    if (isDestroyed) {
      onDestroyed();
      game.gameState.addScore(scoreValue);
      game.world.add(
        ParticleEffects.debris(origin: body.position.clone(), color: color),
      );
      // Bigger blocks feel like they should shake the screen more when
      // they come down; capped so Titanium doesn't overwhelm the camera.
      game.triggerShake((maxHealth * 0.01).clamp(0.05, 0.35));
      removeFromParent();
    } else {
      _refreshFillShader();
      onDamaged(amount);
      // A light, damage-proportional shake gives hits weight without a
      // full particle burst on every scrape.
      game.triggerShake((amount * 0.01).clamp(0.0, 0.12));
    }
  }

  /// Recomputes the fill gradient's colors from the current damage state.
  /// Called only when [health] changes, not every frame — the gradient
  /// [Shader] itself is cheap to rebuild but there's no reason to do it 60
  /// times a second when nothing changed.
  ///
  /// Four stops approximate a lit, rounded surface rather than a flat
  /// tint: a bright specular band near the top (where the implied light
  /// grazes the surface), a lit mid-tone, the true material color, and a
  /// darker ambient-occluded band at the bottom.
  void _refreshFillShader() {
    final damageFraction = 1 - (health / maxHealth).clamp(0.0, 1.0);
    final baseColor = Color.lerp(
      color,
      const Color(0xFF1F2937),
      damageFraction * 0.6,
    )!;
    final highlightColor = Color.lerp(
      baseColor,
      const Color(0xFFFFFFFF),
      0.5,
    )!;
    final litColor = Color.lerp(baseColor, const Color(0xFFFFFFFF), 0.12)!;
    final shadowColor = Color.lerp(baseColor, const Color(0xFF000000), 0.35)!;

    _fillPaint.shader = Gradient.linear(
      Offset(0, -halfHeight),
      Offset(0, halfHeight),
      [highlightColor, litColor, baseColor, shadowColor],
      const [0, 0.22, 0.65, 1],
    );
  }

  /// Called when the block absorbs damage but survives. Override for
  /// visual feedback (e.g. a cracked texture at low health).
  void onDamaged(double amount) {}

  /// Called once, immediately before the block is removed from the world.
  /// Override for destruction-triggered effects (e.g. Coolant Tank's
  /// explosion, implemented as part of the explosion system).
  void onDestroyed() {}

  /// Replaces [BodyComponent]'s default flat-fill fixture rendering with a
  /// lit, rounded block: a drop shadow for separation from the space
  /// background, a 4-stop gradient for volume, a bottom ambient-occlusion
  /// pass, a bright top-edge rim light, subclass-specific accents
  /// (bevel/glass/glow — see [renderAccents]), and a dark border.
  @override
  void render(Canvas canvas) {
    canvas.drawRRect(_shadowRRect, _shadowPaint);
    canvas.drawRRect(_rrect, _fillPaint);
    canvas.drawRRect(_rrect, _ambientOcclusionPaint);
    canvas.drawLine(
      Offset(_rrect.left + _rrect.tlRadius.x, _rrect.top),
      Offset(_rrect.right - _rrect.trRadius.x, _rrect.top),
      _rimLightPaint,
    );
    renderAccents(canvas, _rrect);
    canvas.drawRRect(_rrect, _borderPaint);
  }

  /// Hook for subclass-specific visual texture drawn between the base fill
  /// and the border — e.g. Titanium's bevel, Solar Panel's glass
  /// reflections, Repulsion Shield's pulsing neon rim. No-op by default.
  void renderAccents(Canvas canvas, RRect rrect) {}
}
