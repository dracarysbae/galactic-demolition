import 'package:flutter/foundation.dart';

/// UI-facing game state, deliberately kept separate from the Forge2D
/// simulation. Components/systems push updates into this via the callbacks
/// below; Flutter overlay widgets only ever read from it through Provider.
/// This keeps the HUD decoupled from the physics update loop.
class GameState extends ChangeNotifier {
  int score = 0;
  int ammoRemaining = 0;
  bool isLevelComplete = false;
  bool isGameOver = false;

  void addScore(int points) {
    score += points;
    notifyListeners();
  }

  void setAmmoRemaining(int ammo) {
    ammoRemaining = ammo;
    notifyListeners();
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
    isLevelComplete = false;
    isGameOver = false;
    notifyListeners();
  }
}
