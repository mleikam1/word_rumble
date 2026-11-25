import 'dart:math' as math;
import '../data/level_definition.dart';

enum HazardPhase { calm, warning, burst }

/// One announced event per period. The wind finale pairs two opposing gusts.
/// Continuous displacement and derivative are shared by the art, target and
/// relative-velocity check; ownership never depends on a future phase.
class HazardCycle {
  final HazardPhase phase;
  final int cycle;
  final double lift, speed;
  const HazardCycle(this.phase, this.cycle, this.lift, this.speed);
  static const quiet = HazardCycle(HazardPhase.calm, 0, 0, 0);

  factory HazardCycle.at(LevelDefinition level, double elapsed) {
    if (level.hazard == HazardKind.calm) return quiet;
    final period = level.hazardPeriod;
    final cycle = (elapsed / period).floor();
    final position = elapsed - cycle * period;
    final eventLength = level.warningDuration + level.burstDuration;
    var event = cycle;
    var progress = position - (period - eventLength);
    if (level.hazard == HazardKind.storm) {
      // A quick first gust, one short landing window, then the countergust.
      // The remaining interval is a longer recovery before the next pair.
      final first = level.stormFirstWarning;
      final second = first + eventLength + level.stormCalmGap;
      if (position < first + eventLength) {
        event = 2 * cycle;
        progress = position - first;
      } else if (position < second + eventLength) {
        event = 2 * cycle + 1;
        progress = position - second;
      } else {
        return HazardCycle(HazardPhase.calm, 2 * cycle + 2, 0, 0);
      }
    }
    if (progress < 0) return HazardCycle(HazardPhase.calm, event, 0, 0);
    if (progress < level.warningDuration) {
      final u = progress / level.warningDuration;
      final lift = .075 * (1 - math.cos(math.pi * u));
      final speed =
          .075 * math.pi * math.sin(math.pi * u) / level.warningDuration;
      return HazardCycle(HazardPhase.warning, event, lift, speed);
    }
    final u = (progress - level.warningDuration) / level.burstDuration;
    final lift =
        .075 * (1 + math.cos(math.pi * u)) +
        .425 * (1 - math.cos(2 * math.pi * u));
    final speed =
        math.pi *
        (-.075 * math.sin(math.pi * u) + .85 * math.sin(2 * math.pi * u)) /
        level.burstDuration;
    return HazardCycle(HazardPhase.burst, event, lift, speed);
  }

  int get direction => cycle.isEven ? 1 : -1;

  /// Alternating vents heat different ledges. Players can move to the next
  /// cool ledge during a puff. Swells and gusts move the connected structure.
  bool affects(HazardKind kind, int index) =>
      kind != HazardKind.vent || (index + cycle).isEven;

  String label(HazardKind kind) {
    final arrow = direction == 1 ? '→' : '←';
    final gust =
        kind == HazardKind.storm
            ? 'Gust ${cycle.isEven ? 1 : 2}/2 $arrow'
            : 'Gust $arrow';
    return switch (kind) {
      HazardKind.calm => 'Calm water',
      HazardKind.swell => switch (phase) {
        HazardPhase.calm => 'Low swell · land now',
        HazardPhase.warning => 'Buoy rising · swell ahead',
        HazardPhase.burst => 'Swell crest · wait',
      },
      HazardKind.vent => switch (phase) {
        HazardPhase.calm => 'Vents cooling · land now',
        HazardPhase.warning => 'Marked vents heating',
        HazardPhase.burst => 'Vent puff · use a cool ledge',
      },
      HazardKind.gust || HazardKind.storm => switch (phase) {
        HazardPhase.calm =>
          kind == HazardKind.storm
              ? 'Slack wind · next $gust'
              : 'Slack wind · land now',
        HazardPhase.warning => '$gust approaching',
        HazardPhase.burst => '$gust · wait for slack',
      },
    };
  }
}
