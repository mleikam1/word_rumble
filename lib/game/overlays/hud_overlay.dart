import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/game_state.dart';
import '../../data/powerup_definition.dart';
import '../../ui/widgets/banner_ad_slot.dart';
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
            ? const Color(0xFF1F2333)
            : Colors.white.withValues(alpha: 0.85);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    final darkMode = game.isWordRumble;

    return SafeArea(
      child: ValueListenableBuilder<int>(
        valueListenable: game.hudTicker,
        builder: (context, _, __) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = math.min(constraints.maxWidth - 32, 640.0);

              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: darkMode
                        ? [const Color(0xFF0A0E21), const Color(0xFF101429)]
                        : [const Color(0xFFc6f2ff), const Color(0xFF91d8f4)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildHeaderBar(gameState, darkMode),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildPlayCard(cardWidth, darkMode),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildActionButtons(context, darkMode),
                    ),
                    const SizedBox(height: 8),
                    BannerAdSlot(darkMode: darkMode),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeaderBar(GameState gameState, bool darkMode) {
    final starCount = gameState.coins == 0 ? 12 : gameState.coins;
    final gemCount = 50 + game.guessHistory.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: darkMode ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: darkMode ? Colors.white12 : Colors.black12,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatPill(
            icon: Icons.star,
            value: starCount,
            color: const Color(0xFFFFD166),
            darkMode: darkMode,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: darkMode
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFE9F6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: darkMode ? Colors.white12 : Colors.black12,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Level ${game.levelIndex.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: darkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    game.currentTheme.name,
                    style: TextStyle(
                      color: darkMode ? Colors.white70 : Colors.black54,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          _StatPill(
            icon: Icons.diamond,
            value: gemCount,
            color: const Color(0xFF7DD3FC),
            darkMode: darkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayCard(double width, bool darkMode) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: darkMode ? const Color(0xFF0B1220) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: darkMode ? Colors.white12 : Colors.black12,
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildClue(darkMode),
          const SizedBox(height: 16),
          _buildSlotsRow(darkMode),
          const SizedBox(height: 22),
          _buildPhysicsArena(darkMode),
        ],
      ),
    );
  }

  Widget _buildClue(bool darkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: darkMode ? const Color(0xFF121A2A) : const Color(0xFFF4FBFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: darkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Column(
        children: [
          Text(
            '“A long sharp tool.”',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: darkMode ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sound familiar? Collect the letters and spell it out before the timer melts away.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: darkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsRow(bool darkMode) {
    final letters = game.slots.map((s) => s.currentLetter).toList();
    final feedback = game.slots.map((s) => s.feedback).toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(letters.length, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _GuessTile(
                letter: letters[i],
                background: _feedbackColor(feedback[i], darkMode),
                borderColor: darkMode ? Colors.white10 : Colors.black12,
                textColor: feedback[i] == SlotFeedback.none && !darkMode
                    ? Colors.black
                    : Colors.white,
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          '[ _ ]  [ _ ]  [ _ ]  [ _ ]  [ _ ]',
          style: TextStyle(
            color: darkMode ? Colors.white38 : Colors.black38,
            letterSpacing: 1.2,
          ),
        )
      ],
    );
  }

  Widget _buildPhysicsArena(bool darkMode) {
    final letters = (game.targetWord + 'LETTER').split('');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.sailing, size: 18, color: darkMode ? Colors.white54 : Colors.black45),
            const SizedBox(width: 8),
            Text(
              'Physics Arena',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: darkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: darkMode ? Colors.white12 : const Color(0xFFE8F6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                game.currentTheme.physicsStyle.name.toUpperCase(),
                style: TextStyle(
                  color: darkMode ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: darkMode
                  ? [const Color(0xFF0E1627), const Color(0xFF1B2640)]
                  : [const Color(0xFFd4f1ff), const Color(0xFFb1ddff)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: darkMode ? Colors.white12 : Colors.black12,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Letters float, bounce, and tumble depending on the mode.',
                    style: TextStyle(
                      color: darkMode ? Colors.white54 : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final letter in letters)
                        _FloatingChip(
                          label: letter,
                          tilt: (letter.codeUnitAt(0) % 20 - 10) / 60,
                          darkMode: darkMode,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _usePowerUp(
    BuildContext context,
    PowerUpDefinition powerUp,
    VoidCallback action,
  ) {
    final spent = powerUp.costCoins == 0
        ? true
        : context.read<GameState>().spendCoins(powerUp.costCoins);
    if (spent) {
      action();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins for that move.')),
      );
    }
  }

  Widget _buildActionButtons(BuildContext context, bool darkMode) {
    final actions = [
      PowerUpDefinition(
        id: 'hint',
        label: 'Hint',
        costCoins: 10,
        type: PowerUpType.hintLetter,
      ),
      PowerUpDefinition(
        id: 'shuffle',
        label: 'Shuffle',
        costCoins: 0,
        type: PowerUpType.freezeTime,
      ),
      PowerUpDefinition(
        id: 'clear',
        label: 'Clear 3',
        costCoins: 20,
        type: PowerUpType.clearDecoys,
      ),
      PowerUpDefinition(
        id: 'freeze',
        label: 'Freeze',
        costCoins: 20,
        type: PowerUpType.freezeTime,
      ),
    ];

    return Row(
      children: actions.map((p) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor:
                    darkMode ? Colors.white10 : const Color(0xFFE8F6FF),
                foregroundColor: darkMode ? Colors.white : Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (p.id == 'shuffle') {
                  _usePowerUp(context, p, game.shuffleLetters);
                } else {
                  _usePowerUp(context, p, () => game.onPowerUpUsed(p.type));
                }
              },
              child: Column(
                children: [
                  Text(
                    p.label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.id == 'shuffle' ? 'Mix the chaos' : '${p.costCoins} coins',
                    style: TextStyle(
                      fontSize: 12,
                      color: darkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
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
      width: 54,
      height: 56,
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        letter ?? '',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;
  final bool darkMode;

  const _StatPill({
    required this.icon,
    required this.value,
    required this.color,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: darkMode ? Colors.white10 : const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: darkMode ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 6),
          Text(
            value.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: darkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingChip extends StatelessWidget {
  final String label;
  final double tilt;
  final bool darkMode;

  const _FloatingChip({
    required this.label,
    required this.tilt,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    final background = darkMode ? const Color(0xFF1F2A44) : Colors.white;
    final borderColor = darkMode ? Colors.white10 : Colors.black12;

    return Transform.rotate(
      angle: tilt,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: darkMode ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
