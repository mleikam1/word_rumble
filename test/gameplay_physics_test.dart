import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_rumble/core/game_mode.dart';
import 'package:word_rumble/data/powerup_definition.dart';
import 'package:word_rumble/game/word_rumble_game.dart';

Future<WordRumbleGame> mountBoard(
  WidgetTester tester,
  int level, {
  double width = 360,
}) async {
  final game = WordRumbleGame(
    mode: GameMode.campaign,
    initialLevelIndex: level,
    random: Random(23),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: SizedBox(
          width: width,
          height: 420,
          child: GameWidget(key: ObjectKey(game), game: game),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  expect(game.isReady, isTrue);
  return game;
}

void main() {
  testWidgets(
    'Wind and Lava keep every free tile exposed throughout a phone round',
    (tester) async {
      for (final width in [304.0, 374.0]) {
        for (final level in [2, 3]) {
          final game = await mountBoard(tester, level, width: width);
          final tiles = game.tiles;
          for (var frame = 0; frame < 24 * 60; frame++) {
            game.update(1 / 60);
            if (frame % 6 != 0) continue;
            for (var i = 0; i < tiles.length; i++) {
              for (var j = i + 1; j < tiles.length; j++) {
                final delta = tiles[i].position - tiles[j].position;
                final separation = max(delta.x.abs(), delta.y.abs());
                expect(
                  separation,
                  greaterThanOrEqualTo(tiles[i].width - 1),
                  reason:
                      'level $level, width $width, frame $frame, tiles $i and $j',
                );
              }
            }
          }
        }
      }
    },
  );
  testWidgets(
    'water restores buoyancy, lava kicks upward, wind pushes sideways',
    (tester) async {
      final water = await mountBoard(tester, 1);
      final floating = water.tiles.first;
      floating.position.y = floating.home.y + 45;
      floating.velocity.setZero();
      for (var i = 0; i < 24; i++) {
        water.update(1 / 60);
      }
      expect(floating.velocity.y, lessThan(0));
      expect(floating.y, lessThan(floating.home.y + 45));

      final lava = await mountBoard(tester, 2);
      final falling = lava.tiles.first;
      falling.position.y = falling.height;
      falling.velocity.setZero();
      lava.update(1 / 60);
      expect(falling.velocity.y, closeTo(900 / 60, 0.01));
      var sawKick = false;
      for (var i = 0; i < 180; i++) {
        lava.update(1 / 60);
        if (falling.velocity.y < -250) sawKick = true;
      }
      expect(sawKick, isTrue);

      final wind = await mountBoard(tester, 3);
      final blown = wind.tiles[4];
      final startX = blown.x;
      var maxExcursion = 0.0;
      for (var i = 0; i < 180; i++) {
        wind.update(1 / 60);
        maxExcursion = max(maxExcursion, (blown.x - startX).abs());
      }
      expect(maxExcursion, greaterThan(12));
      expect(wind.slots.every((s) => s.tile == null), isTrue);
    },
  );

  testWidgets(
    'overlapping tiles, canceled touches and a fast invalid drop preserve ownership',
    (tester) async {
      final game = await mountBoard(tester, 1);
      final origin = tester.getTopLeft(find.byType(GameWidget<WordRumbleGame>));
      final top = game.tiles.last;
      final under = game.tiles.first;
      Offset point(Vector2 v) => origin + Offset(v.x, v.y);
      top.position.setValues(180, 190);
      under.position.setFrom(top.position);
      final first = game.slots.first;
      final g = await tester.startGesture(point(top.position));
      await g.moveTo(point(first.position));
      await g.up();
      await tester.pump();
      expect(first.tile, same(top));
      expect(game.slots.any((s) => s.tile == under), isFalse);

      // Cancellation must never commit a target, even after returning from pause.
      final interrupted = await tester.startGesture(point(first.position));
      await interrupted.moveTo(point(game.slots[1].position));
      game.setRoundPaused(true);
      game.setRoundPaused(false);
      await interrupted.cancel();
      await tester.pump();
      expect(first.tile, same(top));
      expect(game.slots[1].tile, isNull);
      expect(top.position, first.position);

      final out = await tester.startGesture(point(first.position));
      await out.moveTo(point(Vector2(-30, game.size.y + 10)));
      await out.up();
      expect(first.tile, same(top));
      expect(top.position, first.position);

      await tester.flingFrom(point(under.position), const Offset(63, 56), 5000);
      for (var i = 0; i < 90; i++) {
        game.update(1 / 60);
        final half = under.width / 2;
        expect(under.x, inInclusiveRange(half, game.size.x - half));
        expect(under.y, inInclusiveRange(half, game.size.y - half));
      }
      expect(first.tile, same(top));
      expect(game.slots.where((s) => s.tile != null), hasLength(1));
    },
  );

  testWidgets(
    'Clear 3 skips occupied decoys and hints place actual distinct tiles',
    (tester) async {
      final game = await mountBoard(tester, 3);
      final decoy = game.tiles.firstWhere((t) => t.isDecoy);
      final occupied = game.slots.first;
      final origin = tester.getTopLeft(find.byType(GameWidget<WordRumbleGame>));
      final gesture = await tester.startGesture(
        origin + Offset(decoy.x, decoy.y),
      );
      await gesture.moveTo(origin + Offset(occupied.x, occupied.y));
      await gesture.up();
      await tester.pump();
      expect(occupied.tile, same(decoy));
      expect(game.onPowerUpUsed(PowerUpType.clearDecoys), isTrue);
      expect(game.tiles.where((t) => t.isDecoy), [decoy]);
      expect(game.canUsePowerUp(PowerUpType.clearDecoys), isFalse);
      expect(occupied.tile, same(decoy));
      for (var i = 0; i < game.targetWord.length && !game.isGameOver; i++) {
        expect(game.onPowerUpUsed(PowerUpType.hintLetter), isTrue);
      }
      expect(game.isWon, isTrue);
      expect(
        game.slots.map((s) => s.tile!.id).toSet(),
        hasLength(game.targetWord.length),
      );
      expect(game.slots.map((s) => s.currentLetter).join(), game.targetWord);
    },
  );
}
