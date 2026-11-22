import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:word_rumble/game/components/slot_component.dart';
import 'package:word_rumble/game/word_rumble_game.dart';
import 'package:word_rumble/main.dart' as app;

final board = find.byType(GameWidget<WordRumbleGame>);

// The Flame loop continuously schedules frames, so pumpAndSettle cannot
// indicate when an individual route, asset or piece of feedback is ready.
Future<void> waitFor(
  WidgetTester tester,
  bool Function() ready,
  String state,
) async {
  final timeout = Stopwatch()..start();
  while (!ready() && timeout.elapsed < const Duration(seconds: 20)) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(ready(), isTrue, reason: 'Waiting for $state');
}

Future<void> press(WidgetTester tester, Finder control) async {
  await waitFor(
    tester,
    () => control.hitTestable().evaluate().length == 1,
    control.toString(),
  );
  await tester.tap(control);
  await tester.pump();
}

Future<WordRumbleGame> openBoard(
  WidgetTester tester,
  Finder control,
  String theme,
) async {
  await press(tester, control);
  bool ready() {
    if (board.evaluate().length != 1) return false;
    final game = tester.widget<GameWidget<WordRumbleGame>>(board).game!;
    return game.isReady &&
        game.currentTheme.name == theme &&
        ModalRoute.of(tester.element(board))?.animation?.status ==
            AnimationStatus.completed;
  }

  await waitFor(tester, ready, '$theme board');
  await tester.pump(const Duration(milliseconds: 32)); // Mount Flame children.
  return tester.widget<GameWidget<WordRumbleGame>>(board).game!;
}

Future<void> arrange(
  WidgetTester tester,
  WordRumbleGame game,
  String word,
) async {
  for (var i = 0; i < word.length; i++) {
    final slot = game.slots[i];
    final tile = game.tiles.firstWhere(
      (t) => t.letter == word[i] && !game.slots.any((s) => s.tile == t),
    );
    final origin = tester.getTopLeft(board);
    final start = origin + Offset(tile.x, tile.y);
    final target = origin + Offset(slot.x, slot.y);
    final gesture = await tester.startGesture(start);
    await gesture.moveTo(Offset.lerp(start, target, .4)!);
    await gesture.moveTo(target);
    await gesture.up();
    await tester.pump();
    expect(
      slot.tile,
      same(tile),
      reason: 'Drag ${word[i]} to position ${i + 1}',
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'native launch, Campaign progression, Word Guess feedback and Retry',
    (tester) async {
      // Exercise production startup, including native plugin registration.
      await app.main();
      await tester.pump();

      var game = await openBoard(
        tester,
        find.textContaining('Crazy Physics'),
        'Splash Bay',
      );
      expect(game.isWordRumble, isFalse);
      for (final entry in [
        ('WATER', 'Lava Core'),
        ('FIRE', 'Wind Peak'),
        ('STORM', ''),
      ]) {
        expect(game.targetWord, entry.$1);
        expect(find.text('Submit Guess'), findsNothing);
        await arrange(tester, game, entry.$1);
        expect(game.isWon, isTrue);
        await waitFor(
          tester,
          () => find.text('Word solved!').evaluate().isNotEmpty,
          'Campaign victory',
        );
        if (entry.$2.isNotEmpty) {
          game = await openBoard(
            tester,
            find.text('Next: ${entry.$2}'),
            entry.$2,
          );
        }
      }
      await press(tester, find.text('Main Menu'));

      game = await openBoard(
        tester,
        find.textContaining('Word-Guess Chaos'),
        'Splash Bay',
      );
      expect(game.isWordRumble, isTrue);
      final answer = game.targetWord;
      expect(find.textContaining(answer), findsNothing);
      final submit = find.text('Submit Guess');
      await press(tester, submit);
      expect(game.guessesUsed, 0);
      expect(find.text('Fill every slot before submitting.'), findsOneWidget);

      final guess = answer == 'TOWER' ? 'WATER' : 'TOWER';
      await arrange(tester, game, guess);
      expect(game.guessHistory, isEmpty);
      await press(tester, submit);
      final result = game.guessHistory.single;
      expect(result.guess, guess);
      expect(game.guessesUsed, 1);
      expect(game.slots.every((s) => s.tile == null), isTrue);
      for (var i = 0; i < guess.length; i++) {
        // TOWER and WATER each have five distinct letters.
        final expected =
            guess[i] == answer[i]
                ? SlotFeedback.correct
                : answer.contains(guess[i])
                ? SlotFeedback.present
                : SlotFeedback.absent;
        expect(result.feedback[i], expected);
      }

      await arrange(tester, game, answer);
      await press(tester, submit);
      expect(game.isWon, isTrue);
      expect(game.guessesUsed, 2);
      await press(tester, find.text('Retry'));
      expect(game.remainingTime, greaterThan(0));
      expect(game.slots.every((s) => s.tile == null), isTrue);
      expect(game.guessesUsed, 0);
      expect(game.isGameOver, isFalse);
    },
  );
}
