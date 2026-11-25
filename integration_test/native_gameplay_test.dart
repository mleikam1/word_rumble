import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:word_rumble/game/components/letter_component.dart';
import 'package:word_rumble/game/components/slot_component.dart';
import 'package:word_rumble/game/landing.dart';
import 'package:word_rumble/game/word_rumble_game.dart';
import 'package:word_rumble/main.dart';

final _board = find.byType(GameWidget<WordRumbleGame>);
final _surface = find.byKey(const ValueKey('arena-surface'));

Future<void> _waitFor(
  WidgetTester tester,
  bool Function() condition,
  String description, {
  Duration timeout = const Duration(seconds: 6),
}) async {
  final watch = Stopwatch()..start();
  while (!condition() && watch.elapsed < timeout) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(condition(), isTrue, reason: description);
}

Future<void> _press(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await _waitFor(tester, () => finder.evaluate().length == 1, key);
  await tester.ensureVisible(finder);
  await _waitFor(
    tester,
    () => finder.hitTestable().evaluate().length == 1,
    'Touchable $key',
  );
  await tester.tap(finder);
  await tester.pump();
}

Future<WordRumbleGame> _ready(
  WidgetTester tester, {
  WordRumbleGame? previous,
}) async {
  WordRumbleGame? current;
  await _waitFor(tester, () {
    if (_board.evaluate().length != 1 || _surface.evaluate().length != 1) {
      return false;
    }
    current = tester.widget<GameWidget<WordRumbleGame>>(_board).game;
    return current != null &&
        current != previous &&
        current!.isReady &&
        current!.tiles.isNotEmpty &&
        ModalRoute.of(tester.element(_board))?.animation?.isCompleted == true;
  }, 'Playable campaign route');
  final game = current!;
  final surfaceSize = tester.getSize(_surface);
  expect(surfaceSize.width, closeTo(game.size.x, .01));
  expect(surfaceSize.height, closeTo(game.size.y, .01));
  return game;
}

// All input travels through the production hit-test tree. Flame coordinates
// are local to the arena under the HUD and the device's safe area.
Offset _toScreen(WidgetTester tester, double x, double y) =>
    tester.renderObject<RenderBox>(_surface).localToGlobal(Offset(x, y));

Future<void> _aim(
  WidgetTester tester,
  LetterComponent tile,
  Offset Function() destination,
  Future<void> Function(TestGesture gesture, Stopwatch watch) release,
) async {
  final offset = Offset(tile.width * .09, tile.height * .04);
  final start = _toScreen(tester, tile.x, tile.y) + offset;
  final watch = Stopwatch()..start();
  final gesture = await tester.createGesture();
  await gesture.down(start, timeStamp: watch.elapsed);
  for (var step = 1; step <= 6; step++) {
    await tester.pump(const Duration(milliseconds: 25));
    await gesture.moveTo(
      Offset.lerp(start, destination() + offset, step / 6)!,
      timeStamp: watch.elapsed,
    );
  }
  await release(gesture, watch);
}

Future<void> _land(
  WidgetTester tester,
  WordRumbleGame game,
  LetterComponent tile,
  SlotComponent berth, {
  bool waitThroughHazard = false,
}) async {
  final rect = tester.getRect(_surface);
  Offset target() => _toScreen(tester, berth.x, berth.y);
  await _aim(tester, tile, target, (gesture, watch) async {
    // Track a moving target with the same finger. Only the rendered berth
    // cue authorizes release. A few designated drops wait through a full puff,
    // swell or gust even when we could have caught an earlier calm interval.
    var sawHazard = false;
    final offset = Offset(tile.width * .09, tile.height * .04);
    final limit = Duration(
      milliseconds: (game.level.hazardPeriod * 2000).ceil() + 900,
    );
    while (watch.elapsed < limit) {
      await tester.pump(const Duration(milliseconds: 45));
      await gesture.moveTo(target() + offset, timeStamp: watch.elapsed);
      if (berth.cue == LandingCue.hazard && !sawHazard) {
        sawHazard = true;
        if (game.targetWord == 'STORM' && waitThroughHazard) {
          expect(game.hazardLabel, contains('Gust ${berth.index + 1}/2'));
        }
        debugPrint(
          'NATIVE_TOUCH ${game.targetWord} held • ${game.hazardLabel}',
        );
      }
      if (berth.cue == LandingCue.aligned &&
          (sawHazard || !waitThroughHazard)) {
        break;
      }
    }
    if (waitThroughHazard) expect(sawHazard, isTrue);
    expect(
      berth.cue,
      LandingCue.aligned,
      reason: '${game.targetWord} berth ${berth.index + 1}',
    );
    expect(game.isHolding, isTrue);
    expect(tester.getRect(_surface), rect);
    expect(berth.tile, isNull, reason: 'No capture while holding');
    await gesture.up(timeStamp: watch.elapsed);
    expect(berth.tile, isNull, reason: 'Settling precedes latching');
  });
  await _waitFor(
    tester,
    () => berth.tile == tile,
    '${tile.letter} latches in berth ${berth.index + 1}',
    timeout: const Duration(seconds: 1),
  );
  expect(tile.position.distanceTo(berth.position), lessThan(1));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('native campaign touch through the STORM finale', (tester) async {
    // A fresh in-memory profile makes this repeatable on an existing simulator.
    await tester.pumpWidget(const WordRumbleApp());
    await _press(tester, 'campaign-play');
    await _press(tester, 'campaign-start');
    final game = await _ready(tester);
    expect(game.targetWord, 'WATER');
    debugPrint('NATIVE_TOUCH WATER arena ready.');
    expect(find.text('Submit Guess'), findsNothing);
    final w = game.tiles.firstWhere((t) => t.letter == 'W');
    final rect = tester.getRect(_surface);
    final seconds = game.remainingTime;

    // Cross the dock with the letter still in hand, then release in open water.
    final first = game.slots.first;
    await _aim(tester, w, () => _toScreen(tester, first.x, first.y), (
      gesture,
      watch,
    ) async {
      await tester.pump(const Duration(milliseconds: 1100));
      expect(first.tile, isNull);
      expect(tester.getRect(_surface), rect, reason: 'Clock tick during aim');
      expect(game.remainingTime, lessThan(seconds));
      await gesture.moveTo(rect.center, timeStamp: watch.elapsed);
      await gesture.up(timeStamp: watch.elapsed);
    });
    await tester.pump(const Duration(milliseconds: 320));
    expect(game.slots.every((s) => s.tile == null), isTrue);
    expect(rect.contains(_toScreen(tester, w.x, w.y)), isTrue);
    expect(tester.getRect(_surface), rect, reason: 'Miss status');
    debugPrint('NATIVE_TOUCH WATER missed in open water; W reachable.');

    await _land(tester, game, w, first);
    final a = game.tiles.firstWhere((t) => t.letter == 'A');
    await _aim(tester, a, () => _toScreen(tester, first.x, first.y), (
      gesture,
      watch,
    ) async {
      await tester.pump(const Duration(milliseconds: 180));
      await gesture.up(timeStamp: watch.elapsed);
    });
    expect(first.tile, same(w), reason: 'Occupied berth retains its owner');
    await _aim(tester, w, () => rect.center, (gesture, watch) async {
      await gesture.cancel(timeStamp: watch.elapsed);
    });
    expect(first.tile, same(w), reason: 'Canceled edit restores origin');
    debugPrint(
      'NATIVE_TOUCH WATER latched W, rejected occupied drop, restored canceled edit.',
    );

    for (var i = 1; i < game.targetWord.length; i++) {
      final tile = game.tiles.firstWhere((t) => t.letter == game.targetWord[i]);
      await _land(tester, game, tile, game.slots[i]);
    }
    expect(game.isWon, isTrue, reason: 'Final latch banks the word');
    debugPrint(
      'NATIVE_TOUCH WATER banked with ${game.remainingTime.toStringAsFixed(2)} seconds left.',
    );
    var previous = game;
    for (final word in ['SHIP', 'BUOY', 'FIRE', 'EMBER', 'GUST', 'STORM']) {
      await _press(tester, 'campaign-next');
      final next = await _ready(tester, previous: previous);
      expect(next.targetWord, word);
      expect(next.slots.every((s) => s.tile == null), isTrue);
      final acquired = <int>{};
      for (final berth in next.slots) {
        final tile = next.tiles.firstWhere(
          (t) => !acquired.contains(t.id) && t.letter == word[berth.index],
        );
        final hazardTrial =
            berth.index == 0 && {'SHIP', 'FIRE', 'STORM'}.contains(word) ||
            berth.index == 1 && word == 'STORM';
        await _land(tester, next, tile, berth, waitThroughHazard: hazardTrial);
        acquired.add(tile.id);
        if (hazardTrial) {
          debugPrint('NATIVE_TOUCH $word recovered • ${next.hazardLabel}');
        }
      }
      expect(next.isWon, isTrue);
      expect(
        acquired.length,
        word.length,
        reason: 'A distinct physical tile for each letter',
      );
      debugPrint(
        'NATIVE_TOUCH $word banked with ${next.remainingTime.toStringAsFixed(2)} seconds left.',
      );
      previous = next;
    }
    expect(find.byKey(const ValueKey('campaign-next')), findsNothing);
  });
}
