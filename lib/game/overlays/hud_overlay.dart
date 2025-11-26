import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/game_state.dart';
import '../../data/powerup_definition.dart';
import '../components/slot_component.dart';
import '../word_rumble_game.dart';

class HudOverlay extends StatelessWidget {
  static const String overlayId = 'HudOverlay';

  final WordRumbleGame game;

  const HudOverlay({super.key, required this.game});

  Color _feedbackColor(SlotFeedback feedback, bool darkMode) {
    switch (feedback) {
      case SlotFeedback.correct:
        return const Color(0xFF6AAA64);
      case SlotFeedback.present:
        return const Color(0xFFC9B458);
      case SlotFeedback.absent:
        return darkMode ? const Color(0xFF3A3A3C) : const Color(0xFFB8BDC4);
      case SlotFeedback.none:
        return darkMode
            ? const Color(0xFF3B3B4F).withOpacity(0.6)
            : const Color(0xFFDDEFF2);
    }
  }

  Widget _buildTopBar(BuildContext context, GameState gameState,
      {required bool darkMode}) {
    final remainingTime = game.remainingTime;
    final totalTime = game.totalTime;
    final progress = (remainingTime / totalTime).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: darkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: Color(0xFFFFD166)),
                const SizedBox(width: 6),
                Text(
                  gameState.coins.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor:
                        darkMode ? Colors.white24 : Colors.black12,
                    color: darkMode
                        ? const Color(0xFF6EE7FF)
                        : const Color(0xFF0D8EF0),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${remainingTime.toStringAsFixed(1)}s left',
                  style: TextStyle(
                    color: darkMode ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (game.isWordRumble)
                  Text(
                    'Guess ${game.guessesUsed}/${game.maxGuesses}',
                    style: TextStyle(
                      color: darkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon')),
              );
            },
            icon: Icon(
              Icons.settings,
              color: darkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(bool darkMode) {
    final wordLength = game.targetWord.length;
    final rows = game.maxGuesses;

    return IgnorePointer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(rows, (row) {
          final letters = List<String?>.filled(wordLength, null);
          final feedback =
              List<SlotFeedback>.filled(wordLength, SlotFeedback.none);

          if (row < game.guessHistory.length) {
            final guess = game.guessHistory[row];
            for (int i = 0; i < wordLength; i++) {
              letters[i] = guess.guess[i];
              feedback[i] = guess.feedback[i];
            }
          } else if (row == game.guessHistory.length) {
            for (int i = 0; i < wordLength; i++) {
              letters[i] = game.slots[i].currentLetter;
              feedback[i] = game.slots[i].feedback;
            }
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(wordLength, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _GuessTile(
                    letter: letters[i],
                    background: _feedbackColor(feedback[i], darkMode),
                    borderColor:
                        darkMode ? Colors.white24 : Colors.black12,
                    textColor:
                        feedback[i] == SlotFeedback.none && !darkMode
                            ? Colors.black
                            : Colors.white,
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  SlotFeedback? _feedbackForLetter(String letter) {
    SlotFeedback? best;
    for (final guess in game.guessHistory) {
      for (int i = 0; i < guess.guess.length; i++) {
        if (guess.guess[i] == letter) {
          final fb = guess.feedback[i];
          if (best == null || fb.index < best.index) {
            best = fb;
          }
        }
      }
    }
    return best;
  }

  Widget _buildKeyboard(bool darkMode) {
    const rows = ['QWERTYUIOP', 'ASDFGHJKL', 'ZXCVBNM'];

    Color keyColor(String letter) {
      final feedback = _feedbackForLetter(letter);
      if (feedback == null) {
        return darkMode ? const Color(0xFF565F7E) : const Color(0xFFE3EBF5);
      }
      return _feedbackColor(feedback, darkMode);
    }

    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.split('').map((letter) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _KeyButton(
                    label: letter,
                    background: keyColor(letter),
                    textColor: Colors.white,
                    onTap: () => game.inputLetter(letter),
                  ),
                );
              }).toList(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _KeyButton(
                label: '⌫',
                background:
                    darkMode ? const Color(0xFF565F7E) : const Color(0xFFE3EBF5),
                textColor: darkMode ? Colors.white : Colors.black87,
                onTap: game.removeLetter,
                wide: true,
              ),
              const SizedBox(width: 8),
              _KeyButton(
                label: 'SUBMIT',
                background: const Color(0xFF0AC47D),
                textColor: Colors.white,
                onTap: () {
                  game.submitCurrentGuess();
                  final msg = game.lastResultMessage;
                  if (msg != null && msg.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg)),
                    );
                  }
                },
                wide: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final darkMode = game.isWordRumble;
    final backgroundColor = darkMode
        ? const Color(0xFF181824)
        : const Color(0xFF9FE1E6);

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
      child: ValueListenableBuilder<int>(
        valueListenable: game.hudTicker,
        builder: (context, _, __) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: darkMode
                    ? [const Color(0xFF0F0F1A), const Color(0xFF1F1F35)]
                    : [const Color(0xFFA7E9F1), const Color(0xFF7BCFDB)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                _buildTopBar(context, gameState, darkMode: darkMode),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: darkMode
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.ad_units, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Test Ad Banner',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Spacer(),
                        Text('AdMob demo'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Center(
                    child: IgnorePointer(
                      ignoring: true,
                      child: AspectRatio(
                        aspectRatio: 9 / 16,
                        child: Stack(
                          children: [
                            IgnorePointer(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: darkMode
                                        ? Colors.white12
                                        : Colors.black12,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Column(
                                children: [
                                  const SizedBox(height: 18),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32),
                                    child: _buildGrid(darkMode),
                                  ),
                                  const Spacer(),
                                  IgnorePointer(
                                    child: Container(
                                      height: 140,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: darkMode
                                            ? const Color(0xFF111827)
                                            : const Color(0xFF6BE0FF),
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.15),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            game.isWordRumble
                                                ? 'Letters floating – tap keys or drag pieces!'
                                                : 'Drag the bobbing letters into the slots above.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: darkMode
                                                  ? Colors.white70
                                                  : Colors.black87,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Water physics enabled',
                                            style:
                                                TextStyle(color: Colors.white70),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: darkMode
                        ? const Color(0xFF0F172A)
                        : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (game.isWordRumble) _buildKeyboard(darkMode),
                      if (!game.isWordRumble)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Grab letters from the water and spell "${game.targetWord}"',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: darkMode ? Colors.white : Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      Row(
                        children: powerUps.map((p) {
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: darkMode
                                      ? Colors.white12
                                      : Colors.blueGrey.shade50,
                                  foregroundColor:
                                      darkMode ? Colors.white : Colors.black,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  final success = context
                                      .read<GameState>()
                                      .spendCoins(p.costCoins);
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
                                    const SizedBox(height: 4),
                                    Text('${p.costCoins} coins',
                                        style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GuessTile extends StatelessWidget {
  final String? letter;
  final Color background;
  final Color borderColor;
  final Color textColor;

  const _GuessTile({
    required this.letter,
    required this.background,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        letter ?? '',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color textColor;
  final VoidCallback onTap;
  final bool wide;

  const _KeyButton({
    required this.label,
    required this.background,
    required this.textColor,
    required this.onTap,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: wide ? 86 : 32,
      height: 44,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 1,
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
