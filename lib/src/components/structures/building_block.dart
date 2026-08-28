import 'dart:ui';

import 'package:flame_forge2d/flame_forge2d.dart';

import '../../galactic_demolition_game.dart';
import '../../systems/collision_system.dart';

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
  }) : _center = center;

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
    if (isDestroyed) {
      onDestroyed();
      game.gameState.addScore(scoreValue);
      removeFromParent();
    } else {
      onDamaged(amount);
    }
  }

  /// Called when the block absorbs damage but survives. Override for
  /// visual feedback (e.g. a cracked texture at low health).
  void onDamaged(double amount) {}

  /// Called once, immediately before the block is removed from the world.
  /// Override for destruction-triggered effects (e.g. Coolant Tank's
  /// explosion, implemented as part of the explosion system).
  void onDestroyed() {}

  /// Replaces [BodyComponent]'s default flat-fill fixture rendering with a
  /// rounded, top-lit block: a vertical gradient for a bit of volume, a
  /// dark border for separation against other blocks, and a darkening tint
  /// as [health] drops so damage is visible before the block breaks.
  @override
  void render(Canvas canvas) {
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: halfWidth * 2,
      height: halfHeight * 2,
    );
    final cornerRadius = (halfWidth < halfHeight ? halfWidth : halfHeight) * 0.25;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));

    final damageFraction = 1 - (health / maxHealth).clamp(0.0, 1.0);
    final baseColor = Color.lerp(color, const Color(0xFF1F2937), damageFraction * 0.6)!;
    final topColor = Color.lerp(baseColor, const Color(0xFFFFFFFF), 0.25)!;
    final bottomColor = Color.lerp(baseColor, const Color(0xFF000000), 0.25)!;

    final fillPaint = Paint()
      ..shader = Gradient.linear(
        Offset(0, -halfHeight),
        Offset(0, halfHeight),
        [topColor, bottomColor],
      );
    canvas.drawRRect(rrect, fillPaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerRadius * 0.3
      ..color = const Color(0xB3000000);
    canvas.drawRRect(rrect, borderPaint);
  }
}
