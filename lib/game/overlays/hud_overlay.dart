import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/game_state.dart';
import '../../data/powerup_definition.dart';
import '../../ui/widgets/banner_ad_slot.dart';
import '../components/slot_component.dart';
import '../word_rumble_game.dart';

class HudOverlay extends StatelessWidget {
  final WordRumbleGame game;
  final Widget arena;

  const HudOverlay({super.key, required this.game, required this.arena});

  @override
  Widget build(BuildContext context) {
    final dark = game.isWordRumble;
    final foreground = dark ? Colors.white : const Color(0xFF0F172A);
    final panel = dark ? const Color(0xFF121A2A) : Colors.white;
    final coins = context.watch<GameState>().coins;
    final header = Material(
      color: panel,
      borderRadius: BorderRadius.circular(16),
      textStyle: TextStyle(color: foreground),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 4, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dark ? 'Word Rumble' : game.currentTheme.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(
                  Icons.monetization_on_outlined,
                  size: 18,
                  color: Color(0xFFB27C00),
                ),
                const SizedBox(width: 3),
                Text('$coins', semanticsLabel: 'Coins: $coins'),
                IconButton(
                  tooltip: 'Pause',
                  icon: Icon(Icons.pause, color: foreground),
                  onPressed:
                      game.isReady ? () => game.setRoundPaused(true) : null,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    dark
                        ? '${game.targetWord.length}-letter word · ${game.guessesUsed}/${game.maxGuesses} guesses'
                        : 'Level ${game.levelIndex} · Spell ${game.targetWord}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (game.isFrozen)
                  Icon(Icons.ac_unit, size: 16, color: foreground),
                Text(
                  '${game.remainingTime.ceil()}s',
                  key: const ValueKey('round-clock'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value:
                  game.totalTime > 0 ? game.remainingTime / game.totalTime : 0,
              semanticsLabel: 'Time remaining',
              semanticsValue: '${game.remainingTime.ceil()} seconds',
              color: game.isFrozen ? Colors.lightBlue : Colors.teal,
            ),
          ],
        ),
      ),
    );

    final notes = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Text(
        game.lastResultMessage ??
            (dark
                ? 'Drag letters into the row, then submit.'
                : 'Drag each letter into its slot.'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: foreground, fontSize: 13),
      ),
    );

    final board = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: arena,
    );

    final controls = _Controls(
      game: game,
      panel: panel,
      foreground: foreground,
    );
    return ColoredBox(
      color: dark ? const Color(0xFF0A0E21) : const Color(0xFFC6F2FF),
      child: LayoutBuilder(
        builder: (context, bounds) {
          // On short, wide screens leave the full height available for dragging.
          if (bounds.maxHeight < 530 &&
              bounds.maxWidth > bounds.maxHeight * 1.2) {
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: (bounds.maxWidth * .43).clamp(220, 350).toDouble(),
                    child: ListView(
                      children: [
                        header,
                        if (dark) GuessHistory(game: game),
                        notes,
                        controls,
                        BannerAdSlot(darkMode: dark, padding: EdgeInsets.zero),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: board),
                ],
              ),
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    if (dark) GuessHistory(game: game),
                    notes,
                    Expanded(child: board),
                    const SizedBox(height: 4),
                    controls,
                    BannerAdSlot(darkMode: dark, padding: EdgeInsets.zero),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final WordRumbleGame game;
  final Color panel;
  final Color foreground;

  const _Controls({
    required this.game,
    required this.panel,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<GameState>();
    Widget power(String label, String description, int cost, PowerUpType type) {
      final enabled = wallet.coins >= cost && game.canUsePowerUp(type);
      return Expanded(
        child: Tooltip(
          message: description,
          child: TextButton(
            onPressed:
                enabled
                    ? () {
                      if (wallet.coins >= cost && game.onPowerUpUsed(type)) {
                        wallet.spendCoins(cost);
                      }
                    }
                    : null,
            style: TextButton.styleFrom(
              foregroundColor: foreground,
              disabledForegroundColor: foreground.withValues(alpha: .50),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              minimumSize: const Size(48, 48),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label),
                Text('$cost coins', style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (game.isWordRumble)
          FilledButton(
            onPressed: game.isReady ? game.submitCurrentGuess : null,
            child: const Text('Submit Guess'),
          ),
        Material(
          color: panel,
          borderRadius: BorderRadius.circular(14),
          child: Row(
            children: [
              power(
                'Hint',
                'Place one correct letter',
                10,
                PowerUpType.hintLetter,
              ),
              Expanded(
                child: TextButton(
                  onPressed: game.isReady ? game.shuffleLetters : null,
                  style: TextButton.styleFrom(
                    foregroundColor: foreground,
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                  ),
                  child: const Text('Shuffle'),
                ),
              ),
              if (!game.isWordRumble)
                power(
                  'Clear up to 3',
                  'Clear up to three free decoys',
                  20,
                  PowerUpType.clearDecoys,
                ),
              power(
                'Freeze',
                'Freeze time for five seconds',
                20,
                PowerUpType.freezeTime,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Keep the newest guess visible. Scroll horizontally to revisit older rows.
class GuessHistory extends StatelessWidget {
  final WordRumbleGame game;

  const GuessHistory({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final history = game.guessHistory;
    if (history.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 42,
      child: ListView.separated(
        key: const ValueKey('guess-history'),
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        itemCount: history.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final number = history.length - index;
          final result = history[number - 1];
          return Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '#$number',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              for (int i = 0; i < result.guess.length; i++)
                Container(
                  width: 24,
                  margin: const EdgeInsets.only(right: 2),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: switch (result.feedback[i]) {
                      SlotFeedback.correct => const Color(0xFF397441),
                      SlotFeedback.present => const Color(0xFF8A680E),
                      _ => const Color(0xFF535964),
                    },
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    result.guess[i],
                    semanticsLabel:
                        '${result.guess[i]}, ${result.feedback[i].name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
