import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/game_state.dart';
import '../../data/powerup_definition.dart';
import '../word_rumble_game.dart';

class HudOverlay extends StatelessWidget {
  static const String overlayId = 'HudOverlay';

  final WordRumbleGame game;

  const HudOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final remainingTime = game.remainingTime;
    final totalTime = game.totalTime;
    final progress = (remainingTime / totalTime).clamp(0.0, 1.0);

    final List<PowerUpDefinition> powerUps = const [
      PowerUpDefinition(
        type: PowerUpType.hintLetter,
        id: 'hint',
        label: 'Hint',
        costCoins: 10,
      ),
      PowerUpDefinition(
        type: PowerUpType.freezeTime,
        id: 'freeze',
        label: 'Freeze',
        costCoins: 20,
      ),
      PowerUpDefinition(
        type: PowerUpType.clearDecoys,
        id: 'clear',
        label: 'Clear',
        costCoins: 30,
      ),
    ];

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 4),
                      Text('Time: ${remainingTime.toStringAsFixed(1)}s'),

                      if (game.isWordRumble)
                        Text('Guess ${game.guessesUsed}/${game.maxGuesses}'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Icon(Icons.monetization_on),
                    const SizedBox(width: 4),
                    Text(
                      gameState.coins.toString(),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(),

          if (game.isWordRumble)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                onPressed: () {
                  game.submitCurrentGuess();
                  final msg = game.lastResultMessage;
                  if (msg != null && msg.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg)),
                    );
                  }
                },
                child: const Text('Submit Guess'),
              ),
            ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.black.withOpacity(0.1),
            child: Row(
              children: powerUps.map((p) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: () {
                        final success =
                        context.read<GameState>().spendCoins(p.costCoins);
                        if (success) {
                          game.onPowerUpUsed(p.type);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Not enough coins'),
                            ),
                          );
                        }
                      },
                      child: Column(
                        children: [
                          Text(p.label),
                          Text('${p.costCoins}', style: const TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
