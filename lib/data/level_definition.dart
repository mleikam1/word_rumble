enum HazardKind { calm, swell, vent, gust, storm }

enum BerthLayout { dock, ledges, ridge }

enum CampaignMedal {
  clear('Clear'),
  swift('Swift'),
  clean('Clean');

  final String label;
  const CampaignMedal(this.label);
}

class LevelDefinition {
  /// Permanent save and route ID, independent of chapter order.
  final int index;
  final int? requiresClear;
  final String targetWord;
  final String themeId;
  final int timeLimitSeconds;
  final int rewardCoins;

  /// Each character adds one physical tile, even if the glyph repeats.
  final String decoyLetters;
  final String tip;
  final BerthLayout layout;
  final HazardKind hazard;
  final double hazardPeriod, warningDuration, burstDuration;

  /// In a storm cycle the first warning follows a short calm. The second
  /// warning starts after the first burst and the gap between gusts.
  final double stormFirstWarning, stormCalmGap;
  final double settleSeconds, landingRadius, maxLandingSpeed;
  final int swiftSecondsLeft;

  /// Attempt limit in legacy deduction rounds.
  final int maxGuesses;
  final bool isBossLevel;

  const LevelDefinition({
    required this.index,
    required this.targetWord,
    required this.themeId,
    required this.timeLimitSeconds,
    required this.rewardCoins,
    this.requiresClear,
    this.decoyLetters = '',
    this.tip = 'Hold a letter steady over its numbered berth, then release.',
    this.layout = BerthLayout.dock,
    this.hazard = HazardKind.calm,
    this.hazardPeriod = 4.8,
    this.warningDuration = 1.0,
    this.burstDuration = 0.9,
    this.stormFirstWarning = .75,
    this.stormCalmGap = .9,
    this.settleSeconds = .24,
    this.landingRadius = .57,
    this.maxLandingSpeed = 260,
    this.swiftSecondsLeft = 10,
    this.maxGuesses = 6,
    this.isBossLevel = false,
  });

  String get goal => 'Spell $targetWord';
  int get decoyCount => decoyLetters.length;

  /// Stable across Dart VM and web builds.
  int get seed => 73001 + index * 131;
  List<String> get tileLetters => (targetWord + decoyLetters).split('');

  Map<String, int> get requiredCounts => _counts(targetWord.split(''));

  bool canSpellWith(Iterable<String> rack) {
    final available = _counts(rack);
    return requiredCounts.entries.every(
      (entry) => (available[entry.key] ?? 0) >= entry.value,
    );
  }

  static Map<String, int> _counts(Iterable<String> letters) {
    final counts = <String, int>{};
    for (final letter in letters) {
      counts.update(letter, (n) => n + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  CampaignMedal medalFor({
    required double secondsLeft,
    required int misses,
    bool assisted = false,
  }) {
    if (secondsLeft < swiftSecondsLeft) return CampaignMedal.clear;
    return misses == 0 && !assisted ? CampaignMedal.clean : CampaignMedal.swift;
  }
}
