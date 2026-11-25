import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_rumble/core/game_mode.dart';
import 'package:word_rumble/game/landing.dart';
import 'package:word_rumble/game/components/letter_component.dart';
import 'package:word_rumble/data/powerup_definition.dart';
import 'package:word_rumble/game/word_rumble_game.dart';
import 'package:word_rumble/ui/game_page.dart';

Future<WordRumbleGame> mountBoard(
  WidgetTester tester,
  int level, {
  double width = 360,
}) async {
  final game = WordRumbleGame(
    mode: GameMode.campaign,
    initialLevelIndex: level,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: SizedBox(
          width: width,
          height: 420,
          child: CampaignTouchSurface(
            game: game,
            child: GameWidget(key: ObjectKey(game), game: game),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
  expect(game.isReady, isTrue);
  return game;
}

class PointerScript {
  PointerScript(this.game);
  final WordRumbleGame game;
  int millis = 1000;
  Duration next(int delta) => Duration(milliseconds: millis += delta);

  void grab(LetterComponent tile, {int id = 1}) =>
      game.pointerDown(id, tile.position.clone(), next(10));
  void dragTo(Vector2 point) => game.pointerMove(1, point, next(160));
  void lift(Vector2 point) => game.pointerUp(1, point, next(160));
  void release(LetterComponent tile, Vector2 point) {
    grab(tile);
    dragTo(point);
    lift(point);
  }

  void place(String letter, int index, {bool settle = true}) {
    final t = game.tiles.firstWhere(
      (t) => t.letter == letter && !game.slots.any((s) => s.tile == t),
    );
    release(t, game.slots[index].position.clone());
    if (settle) game.update(.32);
  }
}

void main() {
  testWidgets(
    'WATER touch gate: recover a miss, correct an off-center grab, watch five letters latch',
    (tester) async {
      final game = await mountBoard(tester, 1, width: 320);
      final origin = tester.getTopLeft(find.byType(GameWidget<WordRumbleGame>));
      Offset point(Vector2 p) => origin + Offset(p.x, p.y);
      final w = game.tiles.firstWhere((t) => t.letter == 'W');
      var g = await tester.startGesture(point(w.position));
      expect(game.isHolding, isTrue);
      await g.moveTo(point(Vector2(90, 80)));
      await g.up();
      expect(game.landingMisses, 1);
      expect(game.slots.every((s) => s.tile == null), isTrue);
      for (final s in game.slots) {
        final t = game.tiles.firstWhere(
          (t) => t.letter == game.targetWord[s.index],
        );
        final grab = Vector2(t.width * .24, t.height * .16);
        g = await tester.startGesture(point(t.position + grab));
        // Cross the target, then correct while held. No capture occurs on overlap.
        await g.moveTo(point(s.position + grab + Vector2(0, 55)));
        await tester.pump(const Duration(milliseconds: 32));
        expect(game.landingCue, isNot(LandingCue.aligned));
        await g.moveTo(point(s.position + grab));
        await tester.pump(const Duration(milliseconds: 125));
        expect(game.isHolding, isTrue);
        expect(s.cue, LandingCue.aligned);
        expect(s.tile, isNull);
        await g.up();
        expect(s.settling, isTrue);
        expect(s.tile, isNull);
        await tester.pump(const Duration(milliseconds: 100));
        expect(s.tile, isNull);
        await tester.pump(const Duration(milliseconds: 165));
        expect(s.tile, same(t));
      }
      expect(game.isWon, isTrue);
      expect(game.cleanLandings, 5);
      expect(game.landingMisses, 1);
    },
  );

  testWidgets('release cue predicts a skid or catch across frame schedules', (
    tester,
  ) async {
    for (final hz in [30, 60, 120]) {
      final game = await mountBoard(tester, 1);
      final p = PointerScript(game);
      final w = game.tiles.firstWhere((t) => t.letter == 'W');
      final s = game.slots.first;
      // Same touch samples at each render cadence; finish by flicking 50px.
      p.grab(w);
      final approach = s.position.clone()..y -= 50;
      p.dragTo(approach);
      for (var i = 0; i < hz ~/ 2; i++) {
        game.update(1 / hz);
      }
      game.pointerMove(1, s.position, p.next(35));
      expect(s.cue, LandingCue.fast);
      game.pointerUp(1, s.position, p.next(1));
      expect(s.settling, isFalse);
      game.update(.6);
      final edge =
          s.position.clone()
            ..y += s.width * game.level.landingRadius + 10 + w.width * .12;
      p.grab(w);
      p.dragTo(edge);
      for (var i = 0; i < hz ~/ 5; i++) {
        game.update(1 / hz);
      }
      expect(s.cue, LandingCue.edge);
      p.lift(edge);
      expect(s.settling, isFalse);
      game.update(.4);
      p.grab(w);
      p.dragTo(s.position);
      for (var i = 0; i < hz ~/ 5; i++) {
        game.update(1 / hz);
      }
      expect(s.cue, LandingCue.aligned);
      p.lift(s.position);
      expect(s.tile, isNull);
      for (var i = 0; i < hz ~/ 3; i++) {
        game.update(1 / hz);
      }
      expect(s.tile, w);
      expect(game.landingMisses, 2);
    }
  });

  testWidgets(
    'wrong word remains editable, occupied and out-of-bounds edits restore, deliberate return makes room',
    (tester) async {
      final g = await mountBoard(tester, 1);
      final p = PointerScript(g);
      for (var i = 0; i < 5; i++) {
        p.place('WATRE'[i], i);
      }
      expect(g.lastResultMessage, 'Not quite. Reorder the letters');
      expect(g.isGameOver, isFalse);
      final r = g.slots[3].tile!, e = g.slots[4].tile!;
      p.release(r, g.slots[4].position);
      p.release(r, Vector2(-20, g.size.y + 10));
      expect(g.slots[3].tile, r);
      expect(g.slots[4].tile, e);
      expect(g.slots.map((s) => s.tile!.id).toSet(), hasLength(5));
      p.grab(r);
      p.dragTo(g.returnCenter);
      expect(g.willReturnTile, isTrue);
      p.lift(g.returnCenter);
      expect(g.slots[3].tile, isNull);
      p.release(e, g.slots[3].position);
      expect(g.slots[4].tile, e); // Reserved until the move actually settles.
      p.release(r, g.slots[3].position);
      g.update(.3);
      expect(g.slots[3].tile, e);
      expect(g.slots[4].tile, isNull);
      p.release(r, g.slots[4].position);
      g.update(.3);
      expect(g.isWon, isTrue);
    },
  );

  testWidgets(
    'active drag cancels safely, settlement freezes on pause, retry ignores stale fingers and reservations',
    (tester) async {
      final g = await mountBoard(tester, 1);
      final p = PointerScript(g);
      final tiles = g.tiles;
      final layout = tiles.map((t) => t.letter).toList();
      final s = g.slots.first;
      p.grab(tiles.first);
      g.pointerDown(2, tiles[1].position, p.next(5));
      g.pointerMove(2, s.position, p.next(5));
      g.pointerUp(2, s.position, p.next(5));
      expect(g.isHolding, isTrue);
      p.dragTo(s.position);
      final before = g.remainingTime;
      g.setRoundPaused(true);
      g.update(2);
      expect(g.remainingTime, before);
      g.setRoundPaused(false);
      p.lift(s.position);
      expect(g.landingMisses, 0);
      expect(s.tile, isNull);
      p.release(tiles.first, s.position);
      g.update(.1);
      expect(s.settling, isTrue);
      expect(g.onPowerUpUsed(PowerUpType.hintLetter), isFalse);
      g.setRoundPaused(true);
      final pos = tiles.first.position.clone(), time = g.remainingTime;
      g.update(4);
      expect(tiles.first.position, pos);
      expect(g.remainingTime, time);
      g.setRoundPaused(false);
      g.update(.16);
      expect(s.tile, tiles.first);
      p.release(tiles[1], g.slots[1].position);
      final token = g.campaignAttempt;
      g.restartLevel();
      expect(g.campaignAttempt, isNot(same(token)));
      g.pointerUp(1, s.position, p.next(500));
      g.update(.4);
      expect(g.slots.every((s) => s.tile == null && !s.settling), isTrue);
      expect(g.tiles.map((t) => t.letter), layout);
      expect(g.cleanLandings, 0);
      expect(g.assisted, isFalse);
      expect(g.landingMisses, 0);
      expect(g.onPowerUpUsed(PowerUpType.hintLetter), isTrue);
      expect(g.slots.every((s) => s.tile == null), isTrue);
      expect(g.assisted, isTrue);
    },
  );

  testWidgets(
    'final latch wins strictly before deadline, including with free decoy held',
    (tester) async {
      for (final cushion in [-.001, 0.0, .001]) {
        final g = await mountBoard(tester, 1);
        final p = PointerScript(g);
        for (var i = 0; i < 4; i++) {
          p.place(g.targetWord[i], i);
        }
        g.update(g.remainingTime - g.level.settleSeconds - cushion);
        p.place('R', 4, settle: false);
        p.grab(g.tiles.firstWhere((t) => t.isDecoy));
        expect(g.isHolding, isTrue);
        g.update(.7); // One dropped frame spans both latch and deadline.
        expect(g.isGameOver, isTrue);
        expect(g.isWon, cushion > 0);
        expect(g.slots[4].tile != null, cushion > 0);
        expect(g.isHolding, isFalse);
        if (cushion <= 0) {
          expect(g.continueAfterTimeout((_) => true), isTrue);
          g.update(.5);
          expect(g.slots[4].tile, isNull);
          expect(g.isWon, isFalse);
        }
      }
    },
  );

  testWidgets('final latch waits for a deliberate edit to finish', (
    tester,
  ) async {
    final g = await mountBoard(tester, 1);
    final p = PointerScript(g);
    for (var i = 0; i < 4; i++) {
      p.place(g.targetWord[i], i);
    }
    p.place('R', 4, settle: false);
    p.grab(g.slots.first.tile!);
    p.dragTo(Vector2(30, 40));
    g.update(.4);
    expect(g.isWon, isFalse);
    g.setRoundPaused(true);
    expect(g.isWon, isTrue);
    expect(g.isRoundPaused, isFalse);
    expect(g.landingMisses, 0);
  });

  testWidgets(
    'resize preserves accepted settlement and already latched ownership',
    (tester) async {
      final g = await mountBoard(tester, 1);
      final p = PointerScript(g);
      p.place('W', 0);
      p.place('A', 1, settle: false);
      g.update(.1);
      final original = g.slots.first.tile;
      g.onGameResize(Vector2(615, 304));
      expect(g.slots.first.tile, same(original));
      expect(g.slots[1].settling, isTrue);
      expect(g.slots[1].tile, isNull);
      g.update(.16);
      expect(g.slots[1].currentLetter, 'A');
      expect(g.lastResultMessage, contains('Latched'));
    },
  );

  testWidgets(
    'same between-frame release has the same deadline at regular and stalled cadence',
    (tester) async {
      for (final regular in [true, false]) {
        for (final late in [false, true]) {
          final g = await mountBoard(tester, 1);
          final p = PointerScript(g);
          for (var i = 0; i < 4; i++) {
            p.place(g.targetWord[i], i);
          }
          final r = g.tiles.firstWhere((t) => t.letter == 'R');
          p.grab(r);
          p.dragTo(g.slots[4].position);
          g.update(g.remainingTime - .6);
          // Both schedules start on the same display frame with 600ms left.
          // One has rendered a new frame 300ms later. The other is stalled.
          const origin = Duration(seconds: 50);
          var frame = origin;
          if (regular) {
            g.update(.3);
            frame += const Duration(milliseconds: 300);
          }
          final release = origin + Duration(milliseconds: late ? 365 : 355);
          g.syncPointerClock(release, frame);
          p.lift(g.slots[4].position);
          expect(g.slots[4].settling, isTrue);
          g.update(regular ? .35 : .65);
          expect(g.isGameOver, isTrue);
          expect(g.isWon, !late);
          expect(g.remainingTime, closeTo(late ? 0 : .005, .000001));
        }
      }
    },
  );

  testWidgets(
    'open water release nudges a loose neighbor, both return to reachable water',
    (tester) async {
      final g = await mountBoard(tester, 1);
      final p = PointerScript(g);
      final a = g.tiles[0], b = g.tiles[1];
      final original = b.position.clone();
      p.release(a, b.position + Vector2(8, 0));
      expect(b.velocity.length, greaterThan(65));
      g.update(.12);
      expect(b.position.distanceTo(original), greaterThan(4));
      g.update(1.6);
      for (final t in [a, b]) {
        expect(t.position.distanceTo(t.home), lessThan(10));
        expect(
          t.x,
          inInclusiveRange(t.width / 2 - .001, g.size.x - t.width / 2 + .001),
        );
      }
    },
  );

  testWidgets('width-independent reachability, including both E tiles of EMBER', (
    tester,
  ) async {
    for (final width in [304.0, 374.0, 760.0]) {
      for (final id in [1, 4, 5, 2, 6, 7, 3]) {
        final g = await mountBoard(tester, id, width: width);
        for (var i = 0; i < 120; i++) {
          g.update(.1);
          for (final t in g.tiles) {
            expect(
              t.x,
              inInclusiveRange(
                t.width / 2 - .001,
                g.size.x - t.width / 2 + .001,
              ),
            );
            expect(
              t.y,
              inInclusiveRange(
                t.width / 2 - .001,
                g.size.y - t.width / 2 + .001,
              ),
            );
            for (final o in g.tiles.where((o) => o.id < t.id)) {
              expect(
                (t.x - o.x).abs() >= (t.width - 1) ||
                    (t.y - o.y).abs() >= (t.width - 1),
                isTrue,
                reason:
                    'width $width, ${g.targetWord} ${t.id}/${o.id} at ${i / 10}',
              );
            }
          }
        }
        if (id == 6) {
          final copies = g.tiles.where((t) => t.letter == 'E').toList();
          expect(copies, hasLength(2));
          final p = PointerScript(g);
          for (final t in copies) {
            p.grab(t);
            expect(g.isHolding, isTrue);
            g.pointerCancel(1);
          }
          expect(copies.first.id, isNot(copies.last.id));
        }
      }
    }
  });

  testWidgets(
    'marked swell, alternating vents and opposing gusts change the same held release',
    (tester) async {
      for (final id in [4, 2, 7, 3]) {
        final g = await mountBoard(tester, id);
        final p = PointerScript(g), s = g.slots.first;
        final initial = s.position.clone();
        p.grab(g.tiles.first);
        p.dragTo(s.position);
        g.update(.12);
        expect(s.cue, LandingCue.aligned);
        final level = g.level;
        final warningStart =
            id == 3
                ? level.stormFirstWarning
                : level.hazardPeriod -
                    level.warningDuration -
                    level.burstDuration;
        final before = warningStart + level.warningDuration / 2;
        g.update(before - .12);
        expect(s.warning, isTrue);
        expect(s.unsafe, isFalse);
        final warning = g.hazardLabel;
        g.update(level.warningDuration / 2 + level.burstDuration * .45);
        p.dragTo(s.position);
        expect(s.unsafe, isTrue);
        expect(s.cue, LandingCue.hazard);
        expect(s.position.distanceTo(initial), greaterThan(3));
        expect(g.hazardLabel, isNot(warning));
        if (id == 2) expect(g.slots[1].unsafe, isFalse);
        final firstPhase = g.hazardLabel;
        p.lift(s.position);
        expect(s.settling, isFalse);
        expect(g.landingMisses, 1);
        g.update(level.burstDuration * .7);
        expect(s.unsafe, isFalse);
        p.release(g.tiles.first, s.position);
        g.update(.3);
        expect(s.tile, g.tiles.first);
        if (id == 3 || id == 2) {
          final nextBurst =
              id == 3
                  ? level.warningDuration +
                      level.burstDuration +
                      level.stormCalmGap
                  : level.hazardPeriod;
          g.update(nextBurst - level.burstDuration * .7 - .3);
          expect(s.tile, g.tiles.first);
          if (id == 2) {
            expect(s.unsafe, isFalse);
            expect(g.slots[1].unsafe, isTrue);
          } else {
            expect(g.hazardLabel, isNot(firstPhase));
            expect(g.hazardLabel, contains('2/2'));
          }
        }
      }
    },
  );
}
