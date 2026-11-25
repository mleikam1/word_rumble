import 'package:flutter_test/flutter_test.dart';
import 'package:word_rumble/data/level_definition.dart';
import 'package:word_rumble/data/level_repository.dart';

void main() {
  test('every campaign recipe can build its word within a valid chapter', () {
    final seenIds = <int>{};
    final letters = RegExp(r'^[A-Z]+$');
    for (final level in LevelRepository.campaignLevels) {
      expect(seenIds.add(level.index), isTrue);
      if (level.requiresClear case final requiredId?) {
        expect(requiredId, isNot(level.index));
        expect(seenIds, contains(requiredId));
      }
      expect(level.targetWord, matches(letters));
      expect(level.tileLetters, everyElement(matches(RegExp(r'^[A-Z]$'))));
      expect(
        level.tileLetters.length,
        level.targetWord.length + level.decoyCount,
      );
      expect(level.canSpellWith(level.tileLetters), isTrue);
      expect(
        level.hazardPeriod,
        greaterThan(level.warningDuration + level.burstDuration),
      );
      expect(level.settleSeconds, inInclusiveRange(.2, .35));
      expect(level.timeLimitSeconds, inInclusiveRange(20, 40));
    }
    expect(LevelRepository.campaignLevels.map((l) => l.targetWord), [
      'WATER',
      'SHIP',
      'BUOY',
      'FIRE',
      'EMBER',
      'GUST',
      'STORM',
    ]);
    expect(LevelRepository.getCampaignLevel(1).targetWord, 'WATER');
    expect(LevelRepository.getCampaignLevel(2).targetWord, 'FIRE');
    expect(LevelRepository.getCampaignLevel(3).targetWord, 'STORM');
  });

  test(
    'the finale fits two warned bursts, a short landing gap and recovery',
    () {
      final storm = LevelRepository.getCampaignLevel(3);
      final gustPair = 2 * (storm.warningDuration + storm.burstDuration);
      final recovery =
          storm.hazardPeriod -
          storm.stormFirstWarning -
          gustPair -
          storm.stormCalmGap;
      expect(storm.stormFirstWarning, greaterThan(0));
      expect(storm.stormCalmGap, greaterThan(storm.settleSeconds));
      expect(recovery, greaterThan(storm.stormCalmGap));
    },
  );

  test('the rack preserves both copies of a required letter', () {
    final level = LevelRepository.getCampaignLevel(6);
    expect(level.requiredCounts['E'], 2);
    expect(level.canSpellWith('EMBRA'.split('')), isFalse);
    expect(level.canSpellWith(level.tileLetters), isTrue);
    expect(level.tileLetters.where((letter) => letter == 'E'), hasLength(2));
  });

  test('medals distinguish the time threshold and unaided clean landings', () {
    final level = LevelRepository.getCampaignLevel(1);
    final cutoff = level.swiftSecondsLeft.toDouble();
    expect(
      level.medalFor(secondsLeft: cutoff - .001, misses: 0),
      CampaignMedal.clear,
    );
    expect(level.medalFor(secondsLeft: cutoff, misses: 1), CampaignMedal.swift);
    expect(
      level.medalFor(secondsLeft: cutoff, misses: 0, assisted: true),
      CampaignMedal.swift,
    );
    expect(level.medalFor(secondsLeft: cutoff, misses: 0), CampaignMedal.clean);
  });
}
