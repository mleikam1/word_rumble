import 'package:flutter/material.dart';
import '../word_rumble_game.dart';

class GameOverOverlay extends StatelessWidget {
  static const String overlayId = 'GameOverOverlay';

  final WordRumbleGame game;

  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final message = game.lastResultMessage ?? 'Nice try!';

    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Game Over',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          game.restartLevel();
                          game.overlays.remove(GameOverOverlay.overlayId);
                          game.overlays.add('HudOverlay');
                        },
                        child: const Text('Retry'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Main Menu'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Store not implemented')),
                    );
                  },
                  child: const Text('Store'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
