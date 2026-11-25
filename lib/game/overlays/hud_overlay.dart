import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/game_state.dart';
import '../../data/powerup_definition.dart';
import '../../data/supplies.dart';
import '../../ui/style.dart';
import '../components/slot_component.dart';
import '../word_rumble_game.dart';
import 'campaign_hud.dart';

const _ink = InkColors.ink;
const _paper = InkColors.cream;
const _teal = InkColors.teal;
const _butter = InkColors.gold;
const _softInk = InkColors.muted;

class HudOverlay extends StatelessWidget {
  const HudOverlay({
    super.key,
    required this.game,
    required this.arena,
    this.daily = false,
  });

  final WordRumbleGame game;
  final Widget arena;
  final bool daily;

  @override
  Widget build(BuildContext context) {
    if (!game.isWordRumble) {
      return CampaignHud(
        game: game,
        board: _Landscape(game: game, child: arena),
      );
    }
    const description = 'Drag five tiles, then submit a word.';
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton.filled(
              onPressed: game.isReady ? () => game.setRoundPaused(true) : null,
              icon: const Icon(Icons.pause_rounded),
              tooltip: 'Pause',
              style: IconButton.styleFrom(
                backgroundColor: _ink,
                foregroundColor: _paper,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    daily ? 'DAILY CHALLENGE' : 'LEGACY PRACTICE',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                      color: _teal,
                    ),
                  ),
                  Text(
                    game.currentTheme.name,
                    style: const TextStyle(
                      fontSize: 19,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                      color: _ink,
                    ),
                  ),
                ],
              ),
            ),
            Wallet(
              onPressed:
                  game.isReady
                      ? () {
                        game.setRoundPaused(true);
                        Navigator.pushNamed(context, '/shop');
                      }
                      : null,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                'Find the hidden word',
                style: const TextStyle(
                  color: _ink,
                  fontFamily: 'Barlow Condensed',
                  fontSize: 29,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.65,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              game.isFrozen ? Icons.ac_unit : Icons.timer_outlined,
              color: _ink,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              '${game.remainingTime.ceil()}s',
              key: const ValueKey('round-clock'),
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 8,
            value:
                game.totalTime == 0
                    ? 0
                    : (game.remainingTime / game.totalTime)
                        .clamp(0, 1)
                        .toDouble(),
            backgroundColor: const Color(0xFFDADED0),
            color:
                game.isFrozen
                    ? const Color(0xFF367BB4)
                    : game.remainingTime <= 5
                    ? const Color(0xFFBC4E34)
                    : _teal,
            semanticsLabel: 'Time remaining',
            semanticsValue: '${game.remainingTime.ceil()} seconds',
          ),
        ),
        if (game.isWordRumble) ...[
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Guesses  ${game.guessesUsed} / ${game.maxGuesses}',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(64, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                onPressed:
                    game.guessHistory.isEmpty
                        ? null
                        : () => _showHistory(context),
                child: const Text('History'),
              ),
            ],
          ),
          SizedBox(
            height: 30,
            child: Align(
              alignment: Alignment.centerLeft,
              child: GuessHistory(game: game, latestOnly: true),
            ),
          ),
        ],
      ],
    );

    final note = Semantics(
      liveRegion: game.lastResultMessage != null,
      child: SizedBox(
        height: 42,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            game.lastResultMessage ?? description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: game.lastResultMessage == null ? _softInk : _ink,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
    final board = _Landscape(game: game, child: arena);
    final tools = _RoundTools(game: game);

    return ColoredBox(
      color: _paper,
      child: LayoutBuilder(
        builder: (context, bounds) {
          final split =
              bounds.maxWidth >= 800 ||
              (bounds.maxHeight < 520 && bounds.maxWidth > bounds.maxHeight);
          if (split) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1220),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: math.min(318, bounds.maxWidth * .38),
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          children: [
                            header,
                            note,
                            const SizedBox(height: 6),
                            tools,
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: board),
                    ],
                  ),
                ),
              ),
            );
          }
          final stacked = <Widget>[header, note];
          final scroll =
              bounds.maxHeight < 540 ||
              MediaQuery.textScalerOf(context).scale(1) > 1.4;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 690),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child:
                    scroll
                        ? ListView(
                          children: [
                            ...stacked,
                            SizedBox(
                              height: math.max(270, bounds.maxHeight * .5),
                              child: board,
                            ),
                            const SizedBox(height: 8),
                            tools,
                          ],
                        )
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ...stacked,
                            Expanded(child: board),
                            const SizedBox(height: 8),
                            tools,
                          ],
                        ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showHistory(BuildContext context) async {
    // Use the existing pause state. Dismissing history returns to the explicit
    // resume button, including after the app was backgrounded inside the sheet.
    game.setRoundPaused(true);
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: _paper,
      builder:
          (sheetContext) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Guess history',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A check marks the correct spot. An arrow means the letter belongs elsewhere. A dash means that copy is absent.',
                  style: TextStyle(color: _softInk),
                ),
                const SizedBox(height: 12),
                GuessHistory(game: game, forceMarks: true),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
    );
  }
}

class _Landscape extends StatelessWidget {
  const _Landscape({required this.game, required this.child});
  final WordRumbleGame game;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final art = switch (game.currentTheme.id) {
      'lava_core' => 'lava_core',
      'wind_peak' => 'wind_peak',
      'zero_station' => 'zero_g',
      _ => 'splash_bay',
    };
    final artView = Image.asset(
      'assets/art/$art.webp',
      fit: BoxFit.cover,
      alignment: const Alignment(.65, 0),
      excludeFromSemantics: true,
      errorBuilder:
          (_, __, ___) => ColoredBox(color: game.currentTheme.backgroundColor),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (art == 'splash_bay') ...[
                Align(
                  alignment: Alignment.topCenter,
                  child: FractionallySizedBox(
                    widthFactor: 1,
                    heightFactor: .40,
                    child: artView,
                  ),
                ),
                const CustomPaint(painter: _BaySurface()),
              ] else
                artView,
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x44102E38),
                      Color(0x0A102E38),
                      Color(0x50102E38),
                    ],
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Perspective ripples join the distant illustrated shore to the interactive
/// foreground, so buoyant tiles read as objects on the surface of the lagoon.
class _BaySurface extends CustomPainter {
  const _BaySurface();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final shore = h * .35;
    final water = Path()..moveTo(0, shore);
    for (var i = 0; i < 4; i++) {
      water.quadraticBezierTo(
        w * (i + .5) / 4,
        shore + (i.isEven ? -5 : 6),
        w * (i + 1) / 4,
        shore,
      );
    }
    water.lineTo(w, h);
    water.lineTo(0, h);
    water.close();
    canvas.drawPath(
      water,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF169D93), Color(0xFF138B88), Color(0xFF067175)],
        ).createShader(Rect.fromLTRB(0, shore, w, h)),
    );
    final ripple =
        Paint()
          ..color = const Color(0x48AFEBCC)
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
    for (var row = 0; row < 8; row++) {
      final depth = (row + 1) / 9;
      final y = shore + (h - shore) * depth;
      ripple.strokeWidth = .8 + depth * 1.5;
      for (var col = 0; col < 4; col++) {
        final x = w * (col + (row.isEven ? .17 : .56)) / 4;
        final width = w * (.037 + depth * .068);
        final d = math.sin(row * 11 + col * 2) * 4;
        final path =
            Path()
              ..moveTo(x, y + d)
              ..quadraticBezierTo(
                x + width * .43,
                y + d + 3,
                x + width,
                y + d - 1,
              );
        canvas.drawPath(path, ripple);
      }
    }
  }

  @override
  bool shouldRepaint(_BaySurface oldDelegate) => false;
}

class _RoundTools extends StatelessWidget {
  const _RoundTools({required this.game});
  final WordRumbleGame game;

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<GameState>();
    Widget power(PowerUpType type) {
      final supply = supplies.firstWhere((s) => s.type == type);
      final cost = supply.cost;
      final owned = wallet.stock(type);
      final enabled =
          game.canUsePowerUp(type) && (owned > 0 || wallet.coins >= cost);
      return _ToolButton(
        label: type == PowerUpType.clearDecoys ? 'Clear' : supply.label,
        detail: owned > 0 ? '×$owned' : '$cost coins',
        icon: supply.icon,
        active: enabled,
        onTap: () {
          if (wallet.stock(type) == 0 && wallet.coins < cost) return;
          if (!game.onPowerUpUsed(type)) return;
          if (wallet.stock(type) > 0) {
            wallet.useStock(type);
          } else {
            wallet.spendCoins(cost);
          }
          wallet.feedback();
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (game.isWordRumble) ...[
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _butter,
              foregroundColor: _ink,
              minimumSize: const Size(44, 46),
            ),
            onPressed: game.isReady ? game.submitCurrentGuess : null,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text(
              'Submit Guess',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 6),
        ],
        LayoutBuilder(
          builder: (context, c) {
            final buttons = [
              power(PowerUpType.hintLetter),
              _ToolButton(
                label: 'Shuffle',
                detail: 'Free',
                icon: Icons.shuffle_rounded,
                active: game.isReady,
                onTap: game.shuffleLetters,
              ),
              if (!game.isWordRumble) power(PowerUpType.clearDecoys),
              power(PowerUpType.freezeTime),
            ];
            final columns = c.maxWidth < 260 ? 2 : buttons.length;
            return Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final b in buttons)
                  SizedBox(
                    width: (c.maxWidth - (columns - 1) * 5) / columns,
                    child: b,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.label,
    required this.detail,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final String label, detail;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: active ? onTap : null,
      style: OutlinedButton.styleFrom(
        backgroundColor:
            active ? const Color(0xFFE1F1E6) : const Color(0xFFF4EDDC),
        foregroundColor: _ink,
        disabledForegroundColor: const Color(0xFF63706A),
        side: BorderSide(color: active ? _teal : const Color(0xFFBFC6B8)),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
        minimumSize: const Size(42, 62),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
          Text(detail, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}

/// A complete, immutable scoring row with optional redundant clue symbols.
class GuessHistory extends StatelessWidget {
  const GuessHistory({
    super.key,
    required this.game,
    this.latestOnly = false,
    this.forceMarks = false,
  });
  final WordRumbleGame game;
  final bool latestOnly, forceMarks;

  @override
  Widget build(BuildContext context) {
    final marks = forceMarks || context.watch<GameState>().colorClues;
    final history = game.guessHistory;
    final start = latestOnly && history.isNotEmpty ? history.length - 1 : 0;
    return Column(
      key: const ValueKey('guess-history'),
      children: [
        for (var n = start; n < history.length; n++)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: [
                Text(
                  '#${n + 1}',
                  style: const TextStyle(
                    color: _softInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 7),
                for (var i = 0; i < history[n].guess.length; i++)
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 38),
                      child: Container(
                        margin: const EdgeInsets.only(right: 3),
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: switch (history[n].feedback[i]) {
                            SlotFeedback.correct => _teal,
                            SlotFeedback.present => _butter,
                            _ => const Color(0xFF52656A),
                          },
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Semantics(
                          label:
                              '${history[n].guess[i]}, ${history[n].feedback[i].name}',
                          child: ExcludeSemantics(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  history[n].guess[i],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color:
                                        history[n].feedback[i] ==
                                                SlotFeedback.present
                                            ? _ink
                                            : Colors.white,
                                  ),
                                ),
                                if (marks)
                                  Icon(
                                    switch (history[n].feedback[i]) {
                                      SlotFeedback.correct => Icons.check,
                                      SlotFeedback.present => Icons.swap_horiz,
                                      _ => Icons.remove,
                                    },
                                    size: 10,
                                    color:
                                        history[n].feedback[i] ==
                                                SlotFeedback.present
                                            ? _ink
                                            : Colors.white,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
