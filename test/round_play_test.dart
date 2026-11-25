import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:word_rumble/core/game_mode.dart';
import 'package:word_rumble/core/game_state.dart';
import 'package:word_rumble/data/guess_words.dart';
import 'package:word_rumble/data/powerup_definition.dart';
import 'package:word_rumble/game/components/letter_component.dart';
import 'package:word_rumble/game/components/slot_component.dart';
import 'package:word_rumble/game/word_rumble_game.dart';
import 'package:word_rumble/main.dart';
import 'package:word_rumble/ui/game_page.dart';

final arena = find.byType(GameWidget<WordRumbleGame>);

Future<void> frames(WidgetTester tester, [int count = 4]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<WordRumbleGame> openMode(WidgetTester tester, String mode) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
  late WordRumbleGame game;
  // Let the actual asset load before advancing the frame clock.
  await tester.pumpWidget(const WordRumbleApp());
  await tester.pumpAndSettle();
  final campaign = mode == 'Crazy Physics';
  final entry = find.text(campaign ? 'Play campaign' : 'WORD GUESS');
  await tester.scrollUntilVisible(entry, 140);
  await tester.pumpAndSettle();
  await tester.tap(entry);
  await tester.pumpAndSettle();
  final start = find.text(campaign ? 'Play level' : 'Start Word Guess');
  await tester.scrollUntilVisible(start, 150);
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    await tester.tap(start);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    game = tester.widget<GameWidget<WordRumbleGame>>(arena).game!;
    await game.toBeLoaded();
  });
  await frames(tester);
  expect(game.isReady, isTrue);
  return game;
}

Future<void> dragTile(
  WidgetTester tester,
  LetterComponent tile,
  Vector2 to,
) async {
  final origin = tester.getTopLeft(arena);
  final start = origin + Offset(tile.position.x, tile.position.y);
  final end = origin + Offset(to.x, to.y);
  final campaign = tile.board.usesBerths;
  final gesture = await tester.startGesture(start);
  await gesture.moveTo(Offset.lerp(start, end, 0.4)!);
  await gesture.moveTo(end);
  if (campaign) {
    await tester.pump(const Duration(milliseconds: 130));
  }
  await gesture.up();
  await tester.pump();
  if (campaign) await frames(tester, 20);
}

Future<void> spell(
  WidgetTester tester,
  WordRumbleGame game,
  String word,
) async {
  for (var i = 0; i < word.length; i++) {
    final slot = game.slots[i];
    if (slot.currentLetter == word[i]) continue;
    final tile = game.tiles.firstWhere(
      (t) =>
          t.letter == word[i] && !game.slots.any((s) => identical(s.tile, t)),
    );
    await dragTile(tester, tile, slot.position);
    expect(slot.tile, same(tile), reason: 'Touch drop at slot $i of $word');
  }
}

Future<void> submit(WidgetTester tester) async {
  await tester.tap(find.text('Submit Guess'));
  await tester.pump();
}

void main() {
  testWidgets(
    'Campaign wrong word stays editable, retries pay once and advance by touch',
    (tester) async {
      var game = await openMode(tester, 'Crazy Physics');
      expect(game.targetWord, 'WATER');
      expect(game.tiles.where((t) => t.isDecoy), hasLength(1));
      expect(game.totalTime, 35);
      expect(find.text('Submit Guess'), findsNothing);
      game.update(1.25);
      await tester.pump();
      final clock = tester.widget<Text>(
        find.byKey(const ValueKey('round-clock')),
      );
      expect(clock.data, '${game.remainingTime.ceil()}s');
      final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(
        progress.value,
        closeTo(game.remainingTime / game.totalTime, 0.001),
      );
      final wallet = tester.element(arena).read<GameState>();
      await spell(tester, game, 'WATRE');
      expect(game.isGameOver, isFalse);
      final rTile = game.slots[3].tile!;
      final eTile = game.slots[4].tile!;
      expect(game.lastResultMessage, 'Not quite. Reorder the letters');
      await dragTile(tester, rTile, game.returnCenter);
      await dragTile(tester, eTile, game.slots[3].position);
      await dragTile(tester, rTile, game.slots[4].position);
      expect(game.isWon, isTrue);
      expect(wallet.coins, 5);
      game.update(
        31,
      ); // A late timeout must not replace or pay out the result again.
      await tester.pump();
      expect(game.isWon, isTrue);
      expect(wallet.coins, 5);
      await tester.tap(find.text('Retry'));
      await frames(tester);
      expect(game.slots.every((s) => s.tile == null), isTrue);
      expect(game.tiles, hasLength(6));
      expect(game.remainingTime, closeTo(35, 0.2));
      game.update(36);
      await tester.pump();
      expect(game.isGameOver, isTrue);
      expect(game.isWon, isFalse);
      expect(find.text('Retry'), findsOneWidget);
      expect(wallet.coins, 5);
      await tester.tap(find.text('Retry'));
      await frames(tester);
      await spell(tester, game, 'WATER');
      expect(wallet.coins, 10);
      await tester.tap(find.byKey(const ValueKey('campaign-next')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await frames(tester);
      game = tester.widget<GameWidget<WordRumbleGame>>(arena).game!;
      expect(game.targetWord, 'SHIP');
      expect(game.slots.every((s) => s.tile == null), isTrue);
    },
  );

  testWidgets(
    'Word Guess rejects invalid input, wins on six, and reveals six misses',
    (tester) async {
      final game = await openMode(tester, 'Word-Guess Chaos');
      final target = game.targetWord;
      final misses =
          GuessWords.targets.where((w) => w != target).take(6).toList();
      expect(find.textContaining(target), findsNothing);
      await submit(tester);
      expect(game.guessesUsed, 0);
      await spell(tester, game, 'OWTLR');
      final beforeShuffle = game.slots.map((s) => s.tile!.id).toList();
      await tester.tap(find.text('Shuffle'));
      await tester.pump();
      expect(game.slots.map((s) => s.tile!.id), beforeShuffle);
      expect(game.guessesUsed, 0);
      expect(game.targetWord, target);
      await submit(tester);
      expect(game.guessesUsed, 0);
      expect(game.guessHistory, isEmpty);
      await dragTile(
        tester,
        game.slots.first.tile!,
        Vector2(game.size.x / 2, game.size.y / 2),
      );
      expect(game.slots.first.tile, isNull);
      // Reset the invalid row before exercising the complete attempt sequence.
      game.restartLevel();
      await frames(tester);
      for (final word in misses.take(5)) {
        await spell(tester, game, word);
        await submit(tester);
        expect(game.guessHistory.last.guess, word);
        expect(game.slots.every((s) => s.tile == null), isTrue);
      }
      await spell(tester, game, target);
      await submit(tester);
      expect(game.guessesUsed, 6);
      expect(game.isWon, isTrue);
      await tester.tap(find.text('Retry'));
      await frames(tester);
      expect(game.guessHistory, isEmpty);
      for (final word in misses) {
        await spell(tester, game, word);
        await submit(tester);
      }
      expect(game.guessesUsed, 6);
      expect(game.isGameOver, isTrue);
      expect(game.isWon, isFalse);
      expect(find.textContaining(target), findsWidgets);
      await tester.tap(find.text('Retry'));
      await frames(tester);
      game.update(game.totalTime + 1);
      await tester.pump();
      expect(game.isWon, isFalse);
      expect(find.textContaining(target), findsWidgets);
    },
  );

  testWidgets(
    'Only a deliberate drop owns a slot; shuffle and pause preserve it',
    (tester) async {
      final game = WordRumbleGame(
        mode: GameMode.campaign,
        initialLevelIndex: 1,
        random: Random(4),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: CampaignTouchSurface(game: game, child: GameWidget(game: game)),
        ),
      );
      await frames(tester);
      final tile = game.tiles.first;
      final other = game.tiles.last;
      final first = game.slots.first;
      final second = game.slots[1];
      tile.position.setFrom(first.position);
      game.update(0.001);
      expect(first.tile, isNull);
      game.shuffleLetters();
      await dragTile(tester, tile, first.position);
      expect(first.tile, same(tile));
      await dragTile(tester, other, first.position);
      expect(first.tile, same(tile));
      expect(game.slots.where((s) => s.tile != null), hasLength(1));
      game.shuffleLetters();
      expect(tile.position, first.position);
      game.setRoundPaused(true);
      final time = game.remainingTime;
      game.update(3);
      expect(game.remainingTime, time);
      game.setRoundPaused(false);
      await dragTile(tester, tile, second.position);
      expect(first.tile, isNull);
      expect(second.tile, same(tile));
      final beforeFreeze = game.remainingTime;
      expect(game.onPowerUpUsed(PowerUpType.freezeTime), isTrue);
      game.update(3);
      expect(game.remainingTime, closeTo(beforeFreeze, .001));
      game.update(3);
      expect(game.remainingTime, closeTo(beforeFreeze - 1, 0.01));
      game.restartLevel();
      await frames(tester);
      expect(game.isFrozen, isFalse);
      expect(game.slots.every((s) => s.tile == null), isTrue);
    },
  );

  for (final fixture in [
    (
      'WATER',
      'TOWER',
      [
        SlotFeedback.present,
        SlotFeedback.absent,
        SlotFeedback.present,
        SlotFeedback.correct,
        SlotFeedback.correct,
      ],
    ),
    (
      'SWELL',
      'WELLS',
      [
        SlotFeedback.present,
        SlotFeedback.present,
        SlotFeedback.present,
        SlotFeedback.correct,
        SlotFeedback.present,
      ],
    ),
  ]) {
    testWidgets('Physical rack submits ${fixture.$2} against ${fixture.$1}', (
      tester,
    ) async {
      final game = WordRumbleGame(
        mode: GameMode.wordRumble,
        initialLevelIndex: 1,
        random: Random(7),
        targetOverride: fixture.$1,
        guessWords: GuessWords([fixture.$1, fixture.$2]),
      );
      await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
      await frames(tester);
      await spell(tester, game, fixture.$2);
      expect(game.guessHistory, isEmpty);
      game.submitCurrentGuess();
      expect(game.guessHistory.single.guess, fixture.$2);
      expect(game.guessHistory.single.feedback, fixture.$3);
      expect(game.slots.every((s) => s.tile == null), isTrue);
    });
  }

  test(
    'an excess copy is absent when the only target copy matches exactly',
    () {
      const g = SlotFeedback.correct;
      expect(WordRumbleGame.evaluateGuess('WATER', 'EATER'), [
        SlotFeedback.absent,
        g,
        g,
        g,
        g,
      ]);
    },
  );
}
