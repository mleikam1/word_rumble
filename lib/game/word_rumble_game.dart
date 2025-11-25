import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/game_mode.dart';
import '../data/level_definition.dart';
import '../data/level_repository.dart';
import '../data/level_theme.dart';
import '../data/powerup_definition.dart';
import 'components/letter_component.dart';
import 'components/slot_component.dart';

class WordRumbleGame extends FlameGame
    with HasCollisionDetection, HasKeyboardHandlerComponents {
  final GameMode mode;
  final int initialLevelIndex;

  late LevelDefinition _currentLevel;
  late LevelTheme _currentTheme;
  late String _targetWord;

  final List<SlotComponent> _slots = [];

  double totalTime = 30.0;
  double remainingTime = 30.0;
  bool _isGameOver = false;

  double _timeFreezeRemaining = 0.0;

  int _guessesUsed = 0;
  int _maxGuesses = 6;

  String? lastResultMessage;

  bool get isWordRumble => mode == GameMode.wordRumble;

  // Needed in HUD Overlay
  int get guessesUsed => _guessesUsed;
  int get maxGuesses => _maxGuesses;

  WordRumbleGame({
    required this.mode,
    required this.initialLevelIndex,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadLevel(initialLevelIndex);
  }

  Future<void> _loadLevel(int levelIndex) async {
    _currentLevel = LevelRepository.getCampaignLevel(levelIndex);
    _currentTheme = LevelRepository.getThemeById(_currentLevel.themeId);
    _targetWord = _currentLevel.targetWord.toUpperCase();

    totalTime = _currentLevel.timeLimitSeconds.toDouble();
    remainingTime = totalTime;

    _isGameOver = false;
    lastResultMessage = null;

    _guessesUsed = 0;
    _maxGuesses = _currentLevel.maxGuesses;

    removeAll(children.toList());
    _slots.clear();

    await _buildScene();
  }

  Future<void> _buildScene() async {
    // Background
    add(
      RectangleComponent(
        position: Vector2.zero(),
        size: size,
        paint: Paint()..color = _currentTheme.backgroundColor,
      ),
    );

    _createSlots();
    _spawnLetters();
  }

  void _createSlots() {
    final wordLength = _targetWord.length;

    const double slotWidth = 120;
    const double slotHeight = 120;
    const double slotSpacing = 16;

    final totalRowWidth =
        wordLength * slotWidth + (wordLength - 1) * slotSpacing;

    final startX = (size.x - totalRowWidth) / 2 + slotWidth / 2;
    final y = size.y * 0.7;

    for (int i = 0; i < wordLength; i++) {
      final position = Vector2(startX + i * (slotWidth + slotSpacing), y);

      final slot = SlotComponent(
        index: i,
        position: position,
        size: Vector2(slotWidth, slotHeight),
        baseColor: _currentTheme.slotColor,
      );

      _slots.add(slot);
      add(slot);
    }
  }

  void _spawnLetters() {
    final rand = Random();
    const double size = 100;

    final shuffled = _shuffleString(_targetWord);

    for (final letter in shuffled.split('')) {
      _spawnLetter(letter: letter, isDecoy: false, rand: rand, letterSize: size);
    }

    final alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    int decoys = 0;

    while (decoys < _currentLevel.decoyCount) {
      final char = alphabet[rand.nextInt(alphabet.length)];
      _spawnLetter(letter: char, isDecoy: true, rand: rand, letterSize: size);
      decoys++;
    }
  }

  void _spawnLetter({
    required String letter,
    required bool isDecoy,
    required Random rand,
    required double letterSize,
  }) {
    final position = Vector2(
      size.x * 0.2 + rand.nextDouble() * size.x * 0.6,
      size.y * 0.05 + rand.nextDouble() * size.y * 0.25,
    );

    add(
      LetterComponent(
        letter: letter,
        color: _currentTheme.letterColor,
        position: position,
        size: Vector2.all(letterSize),
        gravity: _currentTheme.gravity,
        buoyancy: _currentTheme.buoyancy,
        physicsStyle: _currentTheme.physicsStyle,
        isDecoy: isDecoy,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isGameOver) return;

    if (_timeFreezeRemaining > 0) {
      _timeFreezeRemaining -= dt;
      if (_timeFreezeRemaining < 0) _timeFreezeRemaining = 0;
    } else {
      remainingTime -= dt;
      if (remainingTime <= 0) {
        remainingTime = 0;
        _onTimeUp();
      }
    }

    _assignLettersToSlots();
  }

  void _assignLettersToSlots() {
    for (final letter in children.whereType<LetterComponent>()) {
      for (final slot in _slots) {
        final letterRect = Rect.fromLTWH(
          letter.position.x - letter.size.x / 2,
          letter.position.y - letter.size.y / 2,
          letter.size.x,
          letter.size.y,
        );

        final slotRect = Rect.fromLTWH(
          slot.position.x - slot.size.x / 2,
          slot.position.y - slot.size.y / 2,
          slot.size.x,
          slot.size.y,
        );

        if (letterRect.overlaps(slotRect)) {
          slot.currentLetter = letter.letter;
          letter.position = slot.position.clone();
        }
      }
    }

    if (!isWordRumble) {
      final allFilled = _slots.every((s) => s.currentLetter != null);
      if (allFilled) {
        final spelled = _slots.map((s) => s.currentLetter!).join();
        if (spelled == _targetWord) _onWordSolved();
      }
    }
  }

  // --------------------------------------------------------------------------
  //                                WORD RUMBLE GUESS
  // --------------------------------------------------------------------------

  void submitCurrentGuess() {
    if (_isGameOver || !isWordRumble) return;

    if (_slots.any((s) => s.currentLetter == null)) {
      lastResultMessage = 'Fill all slots before submitting!';
      return;
    }

    final guess = _slots.map((s) => s.currentLetter!).join();
    _guessesUsed++;

    _evaluateGuess(guess);

    if (guess == _targetWord) {
      _onWordSolved();
      return;
    }

    if (_guessesUsed >= _maxGuesses) {
      lastResultMessage = 'Out of guesses! Word was $_targetWord';
      _onNoGuessesLeft();
      return;
    }

    for (final slot in _slots) {
      slot.currentLetter = null;
    }

    lastResultMessage =
    'Guess $_guessesUsed/$_maxGuesses – keep going!';
  }

  void _evaluateGuess(String guess) {
    final target = _targetWord.split('');
    final guessChars = guess.split('');

    final feedback = List<SlotFeedback>.filled(
      guessChars.length,
      SlotFeedback.absent,
    );

    // correct
    for (int i = 0; i < guessChars.length; i++) {
      if (guessChars[i] == target[i]) {
        feedback[i] = SlotFeedback.correct;
        target[i] = '*';
      }
    }

    // present
    for (int i = 0; i < guessChars.length; i++) {
      if (feedback[i] == SlotFeedback.correct) continue;

      final idx = target.indexOf(guessChars[i]);
      if (idx != -1) {
        feedback[i] = SlotFeedback.present;
        target[idx] = '*';
      }
    }

    for (int i = 0; i < _slots.length; i++) {
      _slots[i].feedback = feedback[i];
    }
  }

  // --------------------------------------------------------------------------
  //                              GAME END STATES
  // --------------------------------------------------------------------------

  void _onTimeUp() {
    if (_isGameOver) return;
    _isGameOver = true;
    lastResultMessage ??= 'Time is up!';
    overlays.add('GameOverOverlay');
  }

  void _onNoGuessesLeft() {
    if (_isGameOver) return;
    _isGameOver = true;
    overlays.add('GameOverOverlay');
  }

  void _onWordSolved() {
    if (_isGameOver) return;
    _isGameOver = true;
    lastResultMessage = 'Correct: $_targetWord';
    overlays.add('GameOverOverlay');
  }

  // --------------------------------------------------------------------------
  //                                 POWERUPS
  // --------------------------------------------------------------------------

  void onPowerUpUsed(PowerUpType t) {
    switch (t) {
      case PowerUpType.hintLetter:
        _revealOneCorrectLetter();
        break;
      case PowerUpType.freezeTime:
        _timeFreezeRemaining = 5.0;
        break;
      case PowerUpType.clearDecoys:
        _clearDecoys();
        break;
    }
  }

  void _revealOneCorrectLetter() {
    for (int i = 0; i < _slots.length; i++) {
      final correct = _targetWord[i];
      if (_slots[i].currentLetter != correct) {
        _slots[i].currentLetter = correct;
        _slots[i].feedback = SlotFeedback.correct;

        for (final letter in children.whereType<LetterComponent>()) {
          if (!letter.isDecoy && letter.letter == correct) {
            letter.position = _slots[i].position.clone();
            break;
          }
        }
        break;
      }
    }
  }

  void _clearDecoys() {
    final decoys =
    children.whereType<LetterComponent>().where((l) => l.isDecoy).toList();

    for (final d in decoys) {
      d.removeFromParent();
    }
  }

  // --------------------------------------------------------------------------
  //                                  BACKEND
  // --------------------------------------------------------------------------

  void restartLevel() {
    _isGameOver = false;
    _timeFreezeRemaining = 0;
    remainingTime = totalTime;

    removeAll(children.toList());
    _slots.clear();
    lastResultMessage = null;
    _guessesUsed = 0;

    _buildScene();
  }

  // Shuffle helper
  String _shuffleString(String input) {
    final chars = input.split('');
    final rand = Random();
    for (int i = chars.length - 1; i > 0; i--) {
      final j = rand.nextInt(i + 1);
      final tmp = chars[i];
      chars[i] = chars[j];
      chars[j] = tmp;
    }
    return chars.join();
  }
}
