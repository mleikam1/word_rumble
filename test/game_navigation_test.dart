import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:word_rumble/core/game_mode.dart';
import 'package:word_rumble/core/game_state.dart';
import 'package:word_rumble/game/word_rumble_game.dart';
import 'package:word_rumble/ui/game_page.dart';
import 'package:word_rumble/ui/home_tab.dart';

void main() {
  testWidgets(
    'System back pauses and a daily forfeit records once before returning Home',
    (t) async {
      final records = <(bool, int)>[];
      homeTab.value = 1;
      addTearDown(() => homeTab.value = 0);
      await t.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => GameState(),
          child: MaterialApp(
            home: Builder(
              builder:
                  (context) => Scaffold(
                    body: Center(
                      child: FilledButton(
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder:
                                    (_) => GamePage(
                                      mode: GameMode.wordRumble,
                                      initialLevelIndex: 1,
                                      dailyWord: 'WATER',
                                      onDailyFinished:
                                          (won, guesses) =>
                                              records.add((won, guesses)),
                                    ),
                              ),
                            ),
                        child: const Text('Start daily'),
                      ),
                    ),
                  ),
            ),
          ),
        ),
      );
      await t.runAsync(() async {
        await t.tap(find.text('Start daily'));
        await t.pump();
        await t.pump(const Duration(milliseconds: 400));
        await t
            .widget<GameWidget<WordRumbleGame>>(
              find.byType(GameWidget<WordRumbleGame>),
            )
            .game!
            .toBeLoaded();
      });
      await t.pump();
      final game =
          t
              .widget<GameWidget<WordRumbleGame>>(
                find.byType(GameWidget<WordRumbleGame>),
              )
              .game!;
      await t.binding.handlePopRoute();
      await t.pump();
      expect(game.isRoundPaused, true);
      expect(records, isEmpty);
      await t.tap(find.text('Main Menu'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.text('Stay'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(records, isEmpty);
      await t.tap(find.text('Main Menu'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.text('Leave round'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text('Start daily'), findsOneWidget);
      expect(records, [(false, 0)]);
      expect(homeTab.value, 0);
    },
  );

  testWidgets(
    'Completed daily has no retry and returning from the shop keeps its result',
    (t) async {
      final records = <(bool, int)>[];
      await t.runAsync(() async {
        await t.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => GameState(),
            child: MaterialApp(
              routes: {
                '/shop': (_) => const Scaffold(body: Text('Supply counter')),
              },
              home: GamePage(
                mode: GameMode.wordRumble,
                initialLevelIndex: 1,
                dailyWord: 'WATER',
                onDailyFinished: (w, n) => records.add((w, n)),
              ),
            ),
          ),
        );
        await t.pump();
        await t
            .widget<GameWidget<WordRumbleGame>>(
              find.byType(GameWidget<WordRumbleGame>),
            )
            .game!
            .toBeLoaded();
      });
      await t.pump();
      final game =
          t
              .widget<GameWidget<WordRumbleGame>>(
                find.byType(GameWidget<WordRumbleGame>),
              )
              .game!;
      game.update(game.totalTime + 1);
      await t.pump();
      expect(records, [(false, 0)]);
      expect(find.text('Retry'), findsNothing);
      await t.tap(find.text('Shop'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text('Supply counter'), findsOneWidget);
      await t.binding.handlePopRoute();
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text('Time’s up'), findsOneWidget);
      expect(records, [(false, 0)]);
    },
  );
  testWidgets(
    'Paid Campaign continue preserves tiles, debits once and resets on retry',
    (t) async {
      final wallet = GameState()..addCoins(15);
      await t.pumpWidget(
        ChangeNotifierProvider.value(
          value: wallet,
          child: const MaterialApp(
            home: GamePage(mode: GameMode.campaign, initialLevelIndex: 1),
          ),
        ),
      );
      for (var i = 0; i < 4; i++) {
        await t.pump(const Duration(milliseconds: 16));
      }
      final g =
          t
              .widget<GameWidget<WordRumbleGame>>(
                find.byType(GameWidget<WordRumbleGame>),
              )
              .game!;
      final slot = g.slots.first;
      final tile = g.tiles.firstWhere((v) => v.letter == 'W');
      final origin = t.getTopLeft(find.byKey(const ValueKey('arena-surface')));
      final gesture = await t.startGesture(origin + Offset(tile.x, tile.y));
      await gesture.moveTo(origin + Offset(slot.x, slot.y));
      await t.pump(const Duration(milliseconds: 140));
      await gesture.up();
      await t.pump(const Duration(milliseconds: 320));
      expect(slot.tile, same(tile));
      g.update(g.totalTime + 1);
      await t.pump();
      await t.tap(find.text('Continue · 10 coins'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.text('Cancel'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(wallet.coins, 15);
      expect(g.isGameOver, true);
      await t.tap(find.text('Continue · 10 coins'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.text('Spend 10 coins'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(g.isGameOver, false);
      expect(wallet.coins, 5);
      expect(g.remainingTime, closeTo(10, .5));
      expect(slot.tile, same(tile));
      g.update(11);
      expect(g.canContinueAfterTimeout, false);
      expect(g.continueAfterTimeout(wallet.spendCoins), false);
      expect(wallet.coins, 5);
      g.restartLevel();
      g.update(g.totalTime + 1);
      expect(g.canContinueAfterTimeout, true);
      expect(g.continueAfterTimeout(wallet.spendCoins), false);
      expect(wallet.coins, 5);
    },
  );
}
