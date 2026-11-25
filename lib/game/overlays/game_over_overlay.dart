import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/game_state.dart';

import '../../data/level_repository.dart';
import '../../ui/style.dart';
import '../word_rumble_game.dart';
import 'hud_overlay.dart';
import 'clear_vignette.dart';
import '../../data/supplies.dart';

const _ink = InkColors.ink;
const _cream = InkColors.cream;
const _teal = InkColors.teal;

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({
    super.key,
    required this.game,
    required this.onNextLevel,
    required this.onExit,
    required this.onNewWord,
    this.daily = false,
  });
  final WordRumbleGame game;
  final ValueChanged<int> onNextLevel;
  final VoidCallback onExit;
  final VoidCallback onNewWord;
  final bool daily;

  Future<void> _confirmContinue(BuildContext context) async {
    final wallet = context.read<GameState>();
    final approved = await showDialog<bool>(
      context: context,
      builder:
          (dialog) => AlertDialog(
            title: const Text('Continue this round?'),
            content: const Text(
              'Keep your tiles and add ${WordRumbleGame.continueSeconds} seconds. You can do this once per attempt.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialog, true),
                child: const Text('Spend ${WordRumbleGame.continueCost} coins'),
              ),
            ],
          ),
    );
    if (approved != true || !context.mounted) return;
    if (game.continueAfterTimeout(wallet.spendCoins)) wallet.feedback();
  }

  @override
  Widget build(BuildContext context) {
    final coins = context.select<GameState, int>((s) => s.coins);
    const price = WordRumbleGame.continueCost;
    final paused = game.isRoundPaused && !game.isGameOver;
    final levels = LevelRepository.campaignLevels;
    final current = LevelRepository.getCampaignLevel(game.levelIndex);
    final next = levels.indexWhere((l) => l.index == current.index) + 1;
    final hasNext =
        game.isWon && !game.isWordRumble && next > 0 && next < levels.length;
    final won = game.isWon;
    final icon =
        paused
            ? Icons.pause_rounded
            : won
            ? Icons.emoji_events_outlined
            : Icons.hourglass_empty_rounded;
    final title =
        paused
            ? 'Paused'
            : won
            ? (daily ? 'Daily solved!' : 'Word solved!')
            : game.remainingTime <= 0
            ? 'Time’s up'
            : 'Out of guesses';
    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: _teal,
      foregroundColor: Colors.white,
      minimumSize: const Size(48, 48),
    );
    Widget primary(
      String label,
      VoidCallback action,
      IconData symbol, {
      Key? key,
    }) => FilledButton.icon(
      key: key,
      style: buttonStyle,
      onPressed: action,
      icon: Icon(symbol, size: 19),
      label: Text(label),
    );
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 405),
          child: Material(
            color: _cream,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(23),
              side: const BorderSide(color: _ink, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            won
                                ? const Color(0xFFFFCD50)
                                : const Color(0xFFDAECE0),
                        foregroundColor: _ink,
                        child: Icon(icon),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              daily
                                  ? 'DAILY CHALLENGE'
                                  : game.isWordRumble
                                  ? 'RUMBLE MODE'
                                  : '${game.currentTheme.name.toUpperCase()}  /  ${LevelRepository.positionOf(game.levelIndex).toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: _teal,
                                letterSpacing: 1.2,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              title,
                              style: const TextStyle(
                                color: _ink,
                                fontFamily: 'Barlow Condensed',
                                fontSize: 36,
                                height: 1.05,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (paused) ...[
                    Text(
                      'Your timer is paused at ${game.remainingTime.ceil()} seconds.',
                      style: const TextStyle(color: _ink),
                    ),
                    const SizedBox(height: 12),
                    primary(
                      'Resume',
                      () => game.setRoundPaused(false),
                      Icons.play_arrow_rounded,
                    ),
                    if (!game.isWordRumble)
                      OutlinedButton.icon(
                        key: const ValueKey('campaign-restart'),
                        onPressed: game.restartLevel,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Restart'),
                      ),
                    if (!game.isWordRumble) _PausedSupplies(game: game),
                    TextButton.icon(
                      onPressed:
                          () => Navigator.pushNamed(context, '/settings'),
                      icon: const Icon(Icons.tune_rounded),
                      label: const Text('Settings'),
                    ),
                  ] else ...[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFDFECDD),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              won ? 'SOLVED WORD' : 'THE WORD WAS',
                              style: const TextStyle(
                                color: _teal,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 1.3,
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    game.targetWord,
                                    style: const TextStyle(
                                      color: _ink,
                                      letterSpacing: 2,
                                      fontFamily: 'Barlow Condensed',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 34,
                                    ),
                                  ),
                                ),
                                if (won && !game.isWordRumble)
                                  ClearVignette(
                                    word: game.targetWord,
                                    world: current.themeId,
                                    still: game.reducedMotion,
                                  ),
                              ],
                            ),
                            Text(
                              game.isWordRumble
                                  ? '${game.guessesUsed} of ${game.maxGuesses} guesses used'
                                  : won
                                  ? '${current.medalFor(secondsLeft: game.remainingTime, misses: game.landingMisses, assisted: game.assisted).label} medal  ·  +${current.rewardCoins} coins'
                                  : 'Round ${LevelRepository.positionOf(current.index)} • ${current.timeLimitSeconds} seconds',
                              style: const TextStyle(
                                color: _ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (game.isWordRumble && game.guessHistory.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      GuessHistory(game: game, forceMarks: true),
                    ],
                    const SizedBox(height: 12),
                    if (hasNext)
                      primary(
                        'Next · ${levels[next].targetWord}',
                        () => onNextLevel(levels[next].index),
                        Icons.arrow_forward_rounded,
                        key: const ValueKey('campaign-next'),
                      )
                    else if (game.isWordRumble && !daily)
                      primary('New word', onNewWord, Icons.casino_outlined)
                    else if (daily)
                      primary('Main Menu', onExit, Icons.home_outlined),
                    if (game.canContinueAfterTimeout) ...[
                      FilledButton.icon(
                        onPressed:
                            coins >= price
                                ? () => _confirmContinue(context)
                                : null,
                        icon: const Icon(Icons.more_time),
                        label: const Text('Continue · $price coins'),
                      ),
                      if (coins < price)
                        Text(
                          'Earn ${price - coins} more coins to continue.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: InkColors.muted,
                            fontSize: 12,
                          ),
                        ),
                    ],
                    if (!daily)
                      OutlinedButton.icon(
                        onPressed: game.restartLevel,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    if (game.isWordRumble)
                      TextButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/shop'),
                        icon: const Icon(Icons.storefront),
                        label: const Text('Shop'),
                      ),
                  ],
                  if (paused || !daily)
                    TextButton.icon(
                      onPressed: onExit,
                      icon: const Icon(Icons.home_outlined),
                      label: const Text('Main Menu'),
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

class _PausedSupplies extends StatelessWidget {
  const _PausedSupplies({required this.game});
  final WordRumbleGame game;

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<GameState>();
    return ExpansionTile(
      title: const Text('Supplies'),
      children: [
        for (final supply in supplies)
          ListTile(
            leading: Icon(supply.icon),
            title: Text(supply.label),
            subtitle: Text(
              wallet.stock(supply.type) > 0
                  ? 'Use 1 of ${wallet.stock(supply.type)} and resume'
                  : 'Use ${supply.cost} coins and resume',
            ),
            enabled:
                game.canUsePowerUp(supply.type, fromPause: true) &&
                (wallet.stock(supply.type) > 0 || wallet.coins >= supply.cost),
            onTap: () {
              final stocked = wallet.stock(supply.type) > 0;
              if (!stocked && wallet.coins < supply.cost) return;
              game.setRoundPaused(false);
              if (!game.onPowerUpUsed(supply.type)) {
                game.setRoundPaused(true);
                return;
              }
              if (stocked) {
                wallet.useStock(supply.type);
              } else {
                wallet.spendCoins(supply.cost);
              }
              wallet.feedback();
            },
          ),
        ListTile(
          leading: const Icon(Icons.shuffle),
          title: const Text('Shuffle'),
          subtitle: const Text('Rearrange loose tiles and resume'),
          onTap: () {
            game.setRoundPaused(false);
            game.shuffleLetters();
          },
        ),
      ],
    );
  }
}
