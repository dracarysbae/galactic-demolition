import 'dart:math';

import 'package:flame_forge2d/flame_forge2d.dart';

/// Turns a resolved Box2D contact into a single "how hard did they hit"
/// number, shared by every [BuildingBlock]/[TargetCore] so damage math
/// lives in exactly one place instead of being re-derived per subclass.
class CollisionDamage {
  CollisionDamage._();

  /// Total impulse magnitude delivered by a contact, in kg·m/s.
  ///
  /// Box2D's solver reports *impulses* (force integrated over the sub-step),
  /// not instantaneous forces, because the contact force between two rigid
  /// bodies is effectively infinite over an infinitesimally short collision
  /// time — force alone is not a usable number. Impulse stays finite and is
  /// exactly "how much momentum changed hands," which is what should drive
  /// damage: a slow heavy Booster and a fast light piece of debris that
  /// deliver the same impulse should do the same damage.
  ///
  /// Each point in the contact manifold carries a normal impulse (the
  /// push-apart component, i.e. the "solid hit") and a tangent impulse (the
  /// friction/sliding component). They're combined per-point with a
  /// Pythagorean sum — impulse magnitude = sqrt(normal^2 + tangent^2), since
  /// normal and tangent are perpendicular — and then summed across every
  /// active manifold point to get the total impulse for the whole contact.
  static double impulseMagnitude(ContactImpulse impulse) {
    var total = 0.0;
    for (var i = 0; i < impulse.count; i++) {
      final normal = impulse.normalImpulses[i];
      final tangent = impulse.tangentImpulses[i];
      total += sqrt(normal * normal + tangent * tangent);
    }
    return total;
  }
}
