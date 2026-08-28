import 'package:flutter/foundation.dart';

/// UI-facing game state, deliberately kept separate from the Forge2D
/// simulation. Components/systems push updates into this via the callbacks
/// below; Flutter overlay widgets only ever read from it through Provider.
/// This keeps the HUD decoupled from the physics update loop.
class GameState extends ChangeNotifier {
  int score = 0;
  int ammoRemaining = 0;

  /// Ammo the level started with, so the HUD can render a "N of M" style
  /// indicator instead of just a bare count.
  int maxAmmo = 0;
  bool isLevelComplete = false;
  bool isGameOver = false;

  void addScore(int points) {
    score += points;
    notifyListeners();
  }

  /// Sets the ammo the current level starts with — call once when a level
  /// loads, not mid-level (use [consumeAmmo] for that).
  void startAmmo(int count) {
    ammoRemaining = count;
    maxAmmo = count;
    notifyListeners();
  }

  /// Spends one unit of ammo. Returns false without changing state if none
  /// is left, so callers (e.g. the slingshot) can refuse to launch instead
  /// of driving ammo negative.
  bool consumeAmmo() {
    if (ammoRemaining <= 0) {
      return false;
    }
    ammoRemaining -= 1;
    notifyListeners();
    return true;
  }

  void completeLevel() {
    isLevelComplete = true;
    notifyListeners();
  }

  void gameOver() {
    isGameOver = true;
    notifyListeners();
  }

  void reset() {
    score = 0;
    ammoRemaining = 0;
    maxAmmo = 0;
    isLevelComplete = false;
    isGameOver = false;
    notifyListeners();
  }
}
