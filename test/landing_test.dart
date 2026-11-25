import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_rumble/game/landing.dart';
import 'package:word_rumble/game/hazard_cycle.dart';
import 'package:word_rumble/data/level_repository.dart';

void main() {
  test('tile pose, relative speed and reservation determine the marker', () {
    LandingCue assess(
      Vector2 p,
      Vector2 v, {
      bool occupied = false,
      bool hazard = false,
    }) => evaluateLanding(
      offset: p,
      relativeVelocity: v,
      radius: 24,
      maxSpeed: 200,
      occupied: occupied,
      hazard: hazard,
    );
    final zero = Vector2.zero();
    expect(assess(zero, zero), LandingCue.aligned);
    expect(assess(Vector2(18, 0), Vector2(0, 100)), LandingCue.aligned);
    expect(assess(Vector2(29, 0), zero), LandingCue.edge);
    expect(assess(Vector2(90, 0), zero), LandingCue.water);
    expect(assess(zero, Vector2(220, 30)), LandingCue.fast);
    expect(assess(zero, zero, occupied: true), LandingCue.occupied);
    expect(assess(zero, zero, hazard: true), LandingCue.hazard);
  });

  test('release motion agrees at 30, 60, 120 Hz and decays during a hold', () {
    for (final hz in [30, 60, 120]) {
      final motion = ReleaseMotion();
      for (var i = 0; i <= hz; i++) {
        motion.sample(i / hz, Vector2(400 * i / hz, 80 * i / hz));
      }
      expect(motion.at(1).x, closeTo(400, .001));
      expect(motion.at(1).y, closeTo(80, .001));
      expect(motion.at(1.105).length, isZero);
      motion.sample(1.106, Vector2(4000, 2000));
      expect(motion.at(1.106).length, closeTo(640, .001));
    }
  });
  test(
    'STORM has two telegraphed opposing gusts, a short opening and a long recovery',
    () {
      final storm = LevelRepository.getCampaignLevel(3);
      final gust = LevelRepository.getCampaignLevel(7);
      final first = storm.stormFirstWarning,
          length = storm.warningDuration + storm.burstDuration;
      final second = first + length + storm.stormCalmGap;
      HazardCycle at(double t) => HazardCycle.at(storm, t);
      expect(at(first - .01).phase, HazardPhase.calm);
      expect(at(first + .01).phase, HazardPhase.warning);
      expect(HazardCycle.at(gust, first + .01).phase, HazardPhase.calm);
      expect(at(first + storm.warningDuration + .01).phase, HazardPhase.burst);
      expect(at(first + length + .01).phase, HazardPhase.calm);
      expect(at(second - .01).phase, HazardPhase.calm);
      expect(at(second + .01).phase, HazardPhase.warning);
      expect(at(second + storm.warningDuration + .01).phase, HazardPhase.burst);
      expect(at(first + .1).direction, -at(second + .1).direction);
      expect(at(second + length + .01).phase, HazardPhase.calm);
      expect(
        storm.hazardPeriod + first - second - length,
        greaterThan(storm.stormCalmGap),
      );
    },
  );
}
