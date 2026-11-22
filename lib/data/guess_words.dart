import 'package:flutter/services.dart';

/// Word Guess is played with one physical tile for each letter in this rack.
/// Keeping the rack the same across answers also keeps it from revealing them.
class GuessWords {
  static const rack = 'WATERSOLL';
  static const targets = [
    'WATER',
    'TOWER',
    'STARE',
    'LATER',
    'STEAL',
    'SWEAR',
    'WASTE',
    'WROTE',
    'SOLAR',
    'SWELL',
    'LOWER',
    'ALERT',
  ];

  final Set<String> _allowed;

  GuessWords(Iterable<String> words) : _allowed = words.toSet();

  static Future<GuessWords> load() async {
    final text = await rootBundle.loadString('assets/words/enable_five.txt');
    return GuessWords(text.split('\n').where((word) => word.isNotEmpty));
  }

  bool accepts(String word) => _allowed.contains(word);
}
