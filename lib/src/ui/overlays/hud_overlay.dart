import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../game_state.dart';

/// Score/ammo readout plus win/lose banners, driven entirely by
/// [GameState] via Provider.
///
/// Deliberately has zero references to the game/physics classes — it only
/// ever reads [GameState] and calls [onRestart], which keeps the HUD
/// decoupled from the game loop the same way [GameState] itself is.
class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key, required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    return Stack(
      children: [
        Positioned(
          top: 16,
          left: 16,
          child: _StatChip(label: 'Score', value: '${gameState.score}'),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: _StatChip(label: 'Ammo', value: '${gameState.ammoRemaining}'),
        ),
        if (gameState.isLevelComplete)
          _EndGameBanner(
            title: 'Base Destroyed',
            subtitle: 'Score: ${gameState.score}',
            buttonLabel: 'Play Again',
            onPressed: onRestart,
          ),
        if (gameState.isGameOver)
          _EndGameBanner(
            title: 'Out of Ammo',
            subtitle: 'Score: ${gameState.score}',
            buttonLabel: 'Retry',
            onPressed: onRestart,
          ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          '$label: $value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EndGameBanner extends StatelessWidget {
  const _EndGameBanner({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: onPressed, child: Text(buttonLabel)),
            ],
          ),
        ),
      ),
    );
  }
}
