import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_rumble/core/game_state.dart';
import 'package:word_rumble/data/powerup_definition.dart';
import 'package:word_rumble/data/level_definition.dart';
import 'package:word_rumble/data/level_repository.dart';
import 'package:word_rumble/ui/screens/rumble_lobby.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'profile restores campaign unlocks, currency, inventory and preferences',
    () async {
      SharedPreferences.setMockInitialValues({});
      final model = await GameState.load();
      final second = LevelRepository.campaignLevels[1].index;
      expect(model.unlocked(second), false);
      model.winCampaign(1, 5, attempt: Object());
      expect(model.unlocked(second), true);
      model.winCampaign(2, 6, attempt: Object());
      expect(model.buy(PowerUpType.hintLetter), true);
      expect(model.buy(PowerUpType.freezeTime), false);
      model.setPreference('reducedMotion', true);
      await Future<void>.delayed(Duration.zero);
      final restored = await GameState.load();
      expect(restored.coins, 1);
      expect(restored.stock(PowerUpType.hintLetter), 1);
      expect(restored.campaignWins, 2);
      expect(restored.completed(2), true);
      expect(restored.reducedMotion, true);
      expect(restored.useStock(PowerUpType.hintLetter), true);
      expect(restored.useStock(PowerUpType.hintLetter), false);
    },
  );

  test(
    'new profiles unlock each configured ID, including after reopening',
    () async {
      SharedPreferences.setMockInitialValues({});
      var profile = await GameState.load();
      for (final level in LevelRepository.campaignLevels) {
        final before = LevelRepository.campaignLevels.where(
          (entry) =>
              profile.unlocked(entry.index) && !profile.completed(entry.index),
        );
        expect(before.map((entry) => entry.index), [level.index]);
        profile.winCampaign(level.index, level.rewardCoins, attempt: Object());
        await Future<void>.delayed(Duration.zero);
        profile = await GameState.load();
      }
      expect(profile.campaignWins, 7);
      expect(profile.coins, 42);
    },
  );

  test(
    'an old v1 profile keeps unlocked destinations and every saved value',
    () async {
      SharedPreferences.setMockInitialValues({
        'word_rumble.profile.v1': jsonEncode({
          'coins': 37,
          'wins': 6,
          'completed': [1, 2],
          'stock': {'freezeTime': 2},
          'colorClues': false,
          'haptics': false,
          'sound': false,
          'reducedMotion': true,
          'dailyKey': '2026-11-20',
          'dailyStatus': 'won',
          'dailyGuesses': 3,
          'dailyWins': 4,
        }),
      });
      final old = await GameState.load();
      expect(old.unlocked(3), isTrue);
      expect(old.completed(3), isFalse);
      expect(old.bestMedal(1), CampaignMedal.clear);
      old.setPreference('haptics', true);
      await Future<void>.delayed(Duration.zero);
      final saved = await GameState.load();
      expect(saved.unlocked(3), isTrue);
      expect(saved.completed(2), isTrue);
      expect(saved.completed(4), isFalse);
      expect(saved.coins, 37);
      expect(saved.campaignWins, 6);
      expect(saved.stock(PowerUpType.freezeTime), 2);
      expect(saved.colorClues, false);
      expect(saved.sound, false);
      expect(saved.reducedMotion, true);
      expect(saved.haptics, true);
      expect(
        [
          saved.dailyKey,
          saved.dailyStatus,
          saved.dailyGuesses,
          saved.dailyWins,
        ],
        ['2026-11-20', 'won', 3, 4],
      );
    },
  );

  test(
    'a win pays once per attempt, replays pay and the best medal survives',
    () async {
      SharedPreferences.setMockInitialValues({});
      final state = await GameState.load();
      final a = Object(), b = Object(), c = Object();
      state.winCampaign(1, 5, attempt: a, medal: CampaignMedal.swift);
      state.winCampaign(1, 5, attempt: a, medal: CampaignMedal.clean);
      expect(state.bestMedal(1), CampaignMedal.swift);
      state.winCampaign(1, 5, attempt: b, medal: CampaignMedal.clean);
      state.winCampaign(1, 5, attempt: c, medal: CampaignMedal.clear);
      expect(state.coins, 15);
      expect(state.campaignWins, 3);
      await Future<void>.delayed(Duration.zero);
      final restored = await GameState.load();
      expect(restored.bestMedal(1), CampaignMedal.clean);
      expect(restored.coins, 15);
      restored.resetProfile();
      expect(restored.bestMedal(1), isNull);
      expect(restored.coins, 0);
    },
  );

  test(
    'daily admission, day boundary, interruption, and result credit',
    () async {
      SharedPreferences.setMockInitialValues({});
      final state = await GameState.load();
      expect(
        puzzleDay(DateTime.parse('2026-11-22T21:30:00-06:00')),
        '2026-11-23',
      );
      expect(dailyAnswer('2026-11-22'), isNot(dailyAnswer('2026-11-23')));
      expect(state.beginDaily('2026-11-22'), true);
      expect(state.beginDaily('2026-11-22'), false);
      await Future<void>.delayed(Duration.zero);
      final restored = await GameState.load();
      expect(restored.dailyStatus, 'interrupted');
      expect(restored.beginDaily('2026-11-22'), false);
      expect(restored.beginDaily('2026-11-23'), true);
      restored.finishDaily('2026-11-22', true, 2);
      expect(restored.dailyStatus, 'playing');
      restored.finishDaily('2026-11-23', true, 6);
      restored.finishDaily('2026-11-23', true, 6);
      expect(restored.dailyWins, 1);
      expect(restored.dailyGuesses, 6);
    },
  );
}
