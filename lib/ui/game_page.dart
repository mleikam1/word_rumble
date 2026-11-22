import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/game_mode.dart';
import '../core/game_state.dart';
import '../game/overlays/game_over_overlay.dart';
import '../game/overlays/hud_overlay.dart';
import '../game/word_rumble_game.dart';
import 'home_tab.dart';

class GamePage extends StatefulWidget {
  const GamePage({
    super.key,
    required this.mode,
    required this.initialLevelIndex,
    this.dailyWord,
    this.onDailyFinished,
  });

  final GameMode mode;
  final int initialLevelIndex;
  final String? dailyWord;
  final void Function(bool won, int guesses)? onDailyFinished;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with WidgetsBindingObserver {
  late final WordRumbleGame _game;
  late final Widget _arena;
  bool _dailyRecorded = false;
  bool get _daily => widget.dailyWord != null;

  @override
  void initState() {
    super.initState();
    final wallet = context.read<GameState>();
    _game = WordRumbleGame(
      mode: widget.mode,
      initialLevelIndex: widget.initialLevelIndex,
      targetOverride: widget.dailyWord,
      onCoinsEarned:
          (amount) => wallet.winCampaign(widget.initialLevelIndex, amount),
    );
    _arena = GameWidget<WordRumbleGame>(
      key: GlobalKey(),
      game: _game,
      loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
    );
    _game.hudTicker.addListener(_observeResult);
    WidgetsBinding.instance.addObserver(this);
  }

  void _observeResult() {
    if (_game.isGameOver) _recordDaily(_game.isWon);
  }

  void _recordDaily(bool won) {
    if (!_daily || _dailyRecorded) return;
    _dailyRecorded = true;
    widget.onDailyFinished?.call(won, _game.guessesUsed);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _game.setRoundPaused(true);
  }

  @override
  void dispose() {
    _game.hudTicker.removeListener(_observeResult);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _leave() async {
    if (!_game.isGameOver) {
      _game.setRoundPaused(true);
      final leave = await showDialog<bool>(
        context: context,
        builder:
            (dialog) => AlertDialog(
              title: const Text('Leave this round?'),
              content: Text(
                _daily
                    ? 'Leaving ends today’s attempt. Your coin balance is saved.'
                    : 'Your current word and timer will reset. Your coin balance and completed levels are saved.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialog, false),
                  child: const Text('Stay'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialog, true),
                  child: const Text('Leave round'),
                ),
              ],
            ),
      );
      if (leave != true || !mounted) return;
      _recordDaily(false);
    }
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    homeTab.value = 0;
  }

  void _nextRound(GameMode mode, int level) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GamePage(mode: mode, initialLevelIndex: level),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _game.hudTicker,
      child: _arena,
      builder: (context, _, arena) {
        final blocked = _game.isGameOver || _game.isRoundPaused;
        return PopScope(
          canPop: _game.isGameOver,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !_game.isGameOver) {
              _game.setRoundPaused(!_game.isRoundPaused);
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFFFF8E7),
            body: SafeArea(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ExcludeSemantics(
                    excluding: blocked,
                    child: ExcludeFocus(
                      excluding: blocked,
                      child: IgnorePointer(
                        ignoring: blocked,
                        child: HudOverlay(
                          game: _game,
                          daily: _daily,
                          arena: arena!,
                        ),
                      ),
                    ),
                  ),
                  if (blocked) ...[
                    const ModalBarrier(
                      dismissible: false,
                      color: Color(0xBA102E38),
                    ),
                    GameOverOverlay(
                      game: _game,
                      daily: _daily,
                      onNextLevel:
                          (index) => _nextRound(GameMode.campaign, index),
                      onNewWord:
                          () => _nextRound(
                            GameMode.wordRumble,
                            widget.initialLevelIndex,
                          ),
                      onExit: _leave,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
