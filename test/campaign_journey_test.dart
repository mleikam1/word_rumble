import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:word_rumble/core/game_mode.dart';
import 'package:word_rumble/core/game_state.dart';
import 'package:word_rumble/data/level_definition.dart';
import 'package:word_rumble/data/level_repository.dart';
import 'package:word_rumble/game/landing.dart';
import 'package:word_rumble/game/word_rumble_game.dart';
import 'package:word_rumble/ui/game_page.dart';

void main() {
  testWidgets('physical drags and Next can bank every round in one chapter', (
    t,
  ) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(320, 640);
    addTearDown(t.view.reset);
    final profile = GameState();
    await t.pumpWidget(
      ChangeNotifierProvider.value(
        value: profile,
        child: const MaterialApp(
          home: GamePage(mode: GameMode.campaign, initialLevelIndex: 1),
        ),
      ),
    );
    final board = find.byType(GameWidget<WordRumbleGame>);
    final surface = find.byKey(const ValueKey('arena-surface'));
    final next = find.byKey(const ValueKey('campaign-next'));
    var expectedCoins = 0;

    for (final level in LevelRepository.campaignLevels) {
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      await t.pump(const Duration(milliseconds: 16));
      final game = t.widget<GameWidget<WordRumbleGame>>(board).game!;
      expect(game.isReady && game.campaignInputReady, isTrue);
      expect(game.levelIndex, level.index);
      final box = t.renderObject<RenderBox>(surface);
      final usedIds = <int>{};
      for (final berth in game.slots) {
        final tile = game.tiles.firstWhere(
          (t) =>
              t.letter == level.targetWord[berth.index] &&
              !usedIds.contains(t.id),
        );
        final start = box.localToGlobal(Offset(tile.x, tile.y));
        final gesture = await t.startGesture(start);
        expect(game.isHolding, isTrue);
        // Follow the actual berth and wait for the same mark the player sees.
        for (var sample = 0; sample < 80; sample++) {
          final at = box.localToGlobal(
            Offset(berth.x, berth.y + tile.height * .12),
          );
          await gesture.moveTo(at);
          await t.pump(const Duration(milliseconds: 80));
          if (game.landingCue == LandingCue.aligned) break;
        }
        expect(
          game.landingCue,
          LandingCue.aligned,
          reason: '${level.targetWord} berth ${berth.index + 1}',
        );
        expect(berth.tile, isNull);
        await gesture.up();
        expect(berth.tile, isNull);
        await t.pump(const Duration(milliseconds: 310));
        expect(berth.tile, same(tile));
        usedIds.add(tile.id);
      }
      await t.pump();
      expect(game.isWon, isTrue);
      expect(usedIds.length, level.targetWord.length);
      expect(game.landingMisses, 0);
      expectedCoins += level.rewardCoins;
      expect(profile.coins, expectedCoins);
      expect(profile.bestMedal(level.index), CampaignMedal.clean);
      if (level.isBossLevel) {
        expect(next, findsNothing);
      } else {
        await t.ensureVisible(next);
        await t.tap(next);
      }
    }
    expect(profile.campaignWins, 7);
  });
}
