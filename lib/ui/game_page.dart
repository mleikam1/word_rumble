import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/game_mode.dart';
import '../core/game_state.dart';
import '../game/overlays/game_over_overlay.dart';
import '../game/overlays/hud_overlay.dart';
import '../game/word_rumble_game.dart';

class GamePage extends StatefulWidget {
  final GameMode mode;
  final int initialLevelIndex;

  const GamePage({
    super.key,
    required this.mode,
    required this.initialLevelIndex,
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with WidgetsBindingObserver {
  late final WordRumbleGame _game;
  late final Widget _arena;

  @override
  void initState() {
    super.initState();
    _game = WordRumbleGame(
      mode: widget.mode,
      initialLevelIndex: widget.initialLevelIndex,
      onCoinsEarned: context.read<GameState>().addCoins,
    );
    // Retain the engine and its input surface when the HUD or layout changes.
    _arena = GameWidget<WordRumbleGame>(key: GlobalKey(), game: _game);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _game.setRoundPaused(true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<int>(
          valueListenable: _game.hudTicker,
          child: _arena,
          builder: (context, _, arena) {
            final blocked = _game.isGameOver || _game.isRoundPaused;
            return Stack(
              fit: StackFit.expand,
              children: [
                ExcludeSemantics(
                  excluding: blocked,
                  child: IgnorePointer(
                    ignoring: blocked,
                    child: HudOverlay(game: _game, arena: arena!),
                  ),
                ),
                if (blocked) ...[
                  const ModalBarrier(dismissible: false, color: Colors.black54),
                  GameOverOverlay(
                    game: _game,
                    onNextLevel:
                        (index) => Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder:
                                (_) => GamePage(
                                  mode: GameMode.campaign,
                                  initialLevelIndex: index,
                                ),
                          ),
                        ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
