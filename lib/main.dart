import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/galactic_demolition_game.dart';
import 'src/game_state.dart';
import 'src/levels/levels_data.dart';
import 'src/ui/overlays/hud_overlay.dart';

void main() {
  runApp(const GalacticDemolitionApp());
}

class GalacticDemolitionApp extends StatelessWidget {
  const GalacticDemolitionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Galactic Demolition',
      theme: ThemeData.dark(),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameState _gameState;
  late final GalacticDemolitionGame _game;

  @override
  void initState() {
    super.initState();
    _gameState = GameState();
    _game = GalacticDemolitionGame(gameState: _gameState)
      ..loadLevel(LevelsData.moon);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _gameState,
      child: Scaffold(
        body: Stack(
          children: [
            GameWidget(game: _game),
            HudOverlay(
              onRestart: () => _game.loadLevel(_game.currentLevel),
            ),
          ],
        ),
      ),
    );
  }
}
