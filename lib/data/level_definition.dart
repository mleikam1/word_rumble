import 'level_theme.dart';

class LevelDefinition {
  final int index;
  final String targetWord;
  final String themeId;
  final int timeLimitSeconds;
  final int rewardCoins;

  /// How many decoy letters to spawn in addition to real letters.
  final int decoyCount;

  /// For Word Rumble mode (Wordle-like): max attempts per word.
  final int maxGuesses;

  /// Flag for “boss” levels (longer words / more chaos).
  final bool isBossLevel;

  const LevelDefinition({
    required this.index,
    required this.targetWord,
    required this.themeId,
    required this.timeLimitSeconds,
    required this.rewardCoins,
    this.decoyCount = 0,
    this.maxGuesses = 6,
    this.isBossLevel = false,
  });
}
