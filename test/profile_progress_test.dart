import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_rumble/core/game_state.dart';
import 'package:word_rumble/data/powerup_definition.dart';
import 'package:word_rumble/ui/screens/rumble_lobby.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'profile restores campaign unlocks, currency, inventory and preferences',
    () async {
      SharedPreferences.setMockInitialValues({});
      final model = await GameState.load();
      expect(model.unlocked(2), false);
      model.winCampaign(1, 5);
      expect(model.unlocked(2), true);
      model.winCampaign(2, 6);
      expect(model.buy(PowerUpType.hintLetter), true);
      expect(model.buy(PowerUpType.freezeTime), false);
      model.setPreference('reducedMotion', true);
      await Future<void>.delayed(Duration.zero);
      final restored = await GameState.load();
      expect(restored.coins, 1);
      expect(restored.stock(PowerUpType.hintLetter), 1);
      expect(restored.campaignWins, 2);
      expect(restored.unlocked(3), true);
      expect(restored.reducedMotion, true);
      expect(restored.useStock(PowerUpType.hintLetter), true);
      expect(restored.useStock(PowerUpType.hintLetter), false);
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
