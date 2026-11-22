import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_rumble/game/word_rumble_game.dart';
import 'package:word_rumble/main.dart';

void main() {
  testWidgets(
    'menu opens a live round; pause, resume and rotate keep the same game',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final board = find.byType(GameWidget<WordRumbleGame>);
      late WordRumbleGame game;
      await tester.pumpWidget(const WordRumbleApp());
      await tester.pumpAndSettle();
      expect(find.text('Play campaign'), findsOneWidget);
      final entry = find.text('WORD GUESS');
      await tester.scrollUntilVisible(entry, 140);
      await tester.pumpAndSettle();
      await tester.tap(entry);
      await tester.pumpAndSettle();
      final start = find.text('Start Word Guess');
      await tester.scrollUntilVisible(start, 150);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(start);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        game = tester.widget<GameWidget<WordRumbleGame>>(board).game!;
        await game.toBeLoaded();
      });
      await tester.pump();
      expect(game.isReady, isTrue);
      expect(find.byKey(const ValueKey('round-clock')), findsOneWidget);

      await tester.tap(find.text('Submit Guess'));
      await tester.pump();
      expect(game.guessesUsed, 0);
      expect(game.lastResultMessage, isNotNull);
      expect(find.text(game.lastResultMessage!), findsOneWidget);

      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
      expect(find.text('Paused'), findsOneWidget);
      final pausedTime = game.remainingTime;
      await tester.pump(const Duration(seconds: 3));
      expect(game.remainingTime, pausedTime);

      tester.view.physicalSize = const Size(640, 360);
      await tester.pump();
      expect(tester.widget<GameWidget<WordRumbleGame>>(board).game, same(game));
      await tester.tap(find.text('Resume'));
      await tester.pump();
      expect(game.isRoundPaused, isFalse);
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(milliseconds: 200));
      expect(game.remainingTime, lessThan(pausedTime));

      final beforeBackground = game.remainingTime;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Paused'), findsOneWidget);
      expect(game.remainingTime, beforeBackground);
      await tester.tap(find.text('Main Menu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('Leave round'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Play campaign'), findsOneWidget);
      expect(board, findsNothing);
    },
  );
}
