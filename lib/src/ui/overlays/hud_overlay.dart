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
          child: SafeArea(
            child: _Pill(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text('${gameState.score}', style: _statTextStyle),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: SafeArea(
            child: _Pill(child: _AmmoIndicator(gameState: gameState)),
          ),
        ),
        if (gameState.isLevelComplete)
          _EndGameBanner(
            emoji: '🎯',
            title: 'Base Destroyed',
            subtitle: 'Score: ${gameState.score}',
            buttonLabel: 'Play Again',
            accentColor: const Color(0xFF34D399),
            onPressed: onRestart,
          ),
        if (gameState.isGameOver)
          _EndGameBanner(
            emoji: '💥',
            title: 'Out of Ammo',
            subtitle: 'Score: ${gameState.score}',
            buttonLabel: 'Retry',
            accentColor: const Color(0xFFF87171),
            onPressed: onRestart,
          ),
      ],
    );
  }
}

const _statTextStyle = TextStyle(
  color: Colors.white,
  fontSize: 17,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.3,
);

/// Common rounded-pill chrome shared by the score and ammo readouts.
class _Pill extends StatelessWidget {
  const _Pill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.14),
            Colors.black.withValues(alpha: 0.35),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: child,
      ),
    );
  }
}

/// Ammo shown as a row of dots (filled = remaining) instead of a bare
/// number — reads at a glance and telegraphs scarcity as shots run low.
class _AmmoIndicator extends StatelessWidget {
  const _AmmoIndicator({required this.gameState});

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    if (gameState.maxAmmo == 0) {
      return Text('${gameState.ammoRemaining}', style: _statTextStyle);
    }
    final isLow = gameState.ammoRemaining <= 2 && gameState.ammoRemaining > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < gameState.maxAmmo; i++)
          Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < gameState.ammoRemaining
                    ? (isLow ? const Color(0xFFF87171) : const Color(0xFFFB923C))
                    : Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ),
      ],
    );
  }
}

class _EndGameBanner extends StatelessWidget {
  const _EndGameBanner({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.accentColor,
    required this.onPressed,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final Color accentColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.65),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1F2937), Color(0xFF111827)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentColor.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white60, fontSize: 16),
                ),
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: const Color(0xFF111827),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  child: Text(buttonLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
