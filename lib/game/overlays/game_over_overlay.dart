import 'package:flutter/material.dart';

import '../../data/level_repository.dart';
import '../word_rumble_game.dart';
import 'hud_overlay.dart';

class GameOverOverlay extends StatelessWidget {
  final WordRumbleGame game;
  final ValueChanged<int> onNextLevel;

  const GameOverOverlay({
    super.key,
    required this.game,
    required this.onNextLevel,
  });

  @override
  Widget build(BuildContext context) {
    final paused = game.isRoundPaused && !game.isGameOver;
    final levels = LevelRepository.campaignLevels;
    final nextIndex =
        levels.indexWhere((level) => level.index == game.levelIndex) + 1;
    final hasNext =
        !game.isWordRumble &&
        game.isWon &&
        nextIndex > 0 &&
        nextIndex < levels.length;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    paused
                        ? 'Paused'
                        : (game.isWon ? 'Word solved!' : 'Game Over'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!paused) ...[
                    const SizedBox(height: 8),
                    Text(
                      game.lastResultMessage ?? '',
                      textAlign: TextAlign.center,
                    ),
                    if (game.isWordRumble && game.guessHistory.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        color: const Color(0xFF121A2A),
                        child: GuessHistory(game: game),
                      ),
                  ],
                  const SizedBox(height: 12),
                  if (paused)
                    FilledButton(
                      onPressed: () => game.setRoundPaused(false),
                      child: const Text('Resume'),
                    )
                  else ...[
                    if (hasNext)
                      FilledButton(
                        onPressed: () => onNextLevel(levels[nextIndex].index),
                        child: Text(
                          'Next: ${LevelRepository.getThemeById(levels[nextIndex].themeId).name}',
                        ),
                      ),
                    ElevatedButton(
                      onPressed: game.restartLevel,
                      child: const Text('Retry'),
                    ),
                  ],
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Main Menu'),
                  ),
                  if (!paused)
                    TextButton(
                      onPressed:
                          () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Store not implemented'),
                            ),
                          ),
                      child: const Text('Store'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
