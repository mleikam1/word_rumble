import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/game_mode.dart';
import '../game/word_rumble_game.dart';
import '../game/overlays/hud_overlay.dart';
import '../game/overlays/game_over_overlay.dart';

class GamePage extends StatelessWidget {
  final GameMode mode;
  final int initialLevelIndex;

  const GamePage({
    super.key,
    required this.mode,
    required this.initialLevelIndex,
  });

  @override
  Widget build(BuildContext context) {
    final game = WordRumbleGame(
      mode: mode,
      initialLevelIndex: initialLevelIndex,
    );

    return Scaffold(
      body: GameWidget<WordRumbleGame>(
        game: game,
        overlayBuilderMap: {
          HudOverlay.overlayId: (ctx, gameRef) => HudOverlay(game: gameRef),
          GameOverOverlay.overlayId: (ctx, gameRef) =>
              GameOverOverlay(game: gameRef),
        },
        initialActiveOverlays: const [HudOverlay.overlayId],
      ),
    );
  }
}
