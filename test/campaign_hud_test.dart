import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:word_rumble/core/game_mode.dart';
import 'package:word_rumble/core/game_state.dart';
import 'package:word_rumble/game/word_rumble_game.dart';
import 'package:word_rumble/ui/game_page.dart';

void main() {
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(1280, 720),
  ]) {
    testWidgets('Feedback and final countdown preserve touch at $size', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => GameState(),
          child: const MaterialApp(
            home: GamePage(mode: GameMode.campaign, initialLevelIndex: 1),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final surface = find.byKey(const ValueKey('arena-surface'));
      final original = tester.getRect(surface);
      final game =
          tester
              .widget<GameWidget<WordRumbleGame>>(
                find.byType(GameWidget<WordRumbleGame>),
              )
              .game!;
      final tile = game.tiles.first;
      final touch = await tester.startGesture(
        original.topLeft + Offset(tile.x, tile.y),
      );
      expect(game.isHolding, isTrue);
      game.lastResultMessage = 'Clipped the edge. Aim closer to the center.';
      game.update(game.remainingTime - 4.5);
      await tester.pump();
      expect(tester.getRect(surface), original);
      expect(find.text('FINAL 5'), findsOneWidget);
      expect(game.isHolding, isTrue);
      final berth = game.slots.first;
      await touch.moveTo(original.topLeft + Offset(berth.x, berth.y));
      await tester.pump(const Duration(milliseconds: 120));
      expect(berth.tile, isNull);
      await touch.up();
      expect(berth.tile, isNull);
      await tester.pump(const Duration(milliseconds: 310));
      expect(berth.tile, same(tile));
      expect(tester.takeException(), isNull);
    });
  }
}
