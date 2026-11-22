import 'dart:math';
import 'dart:ui' show Canvas, Color, Offset, Paint;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../core/game_mode.dart';
import '../data/guess_words.dart';
import '../data/level_definition.dart';
import '../data/level_repository.dart';
import '../data/level_theme.dart';
import '../data/powerup_definition.dart';
import 'components/letter_component.dart';
import 'components/slot_component.dart';

class GuessResult {
  final String guess;
  final List<SlotFeedback> feedback;

  GuessResult({required this.guess, required List<SlotFeedback> feedback})
    : feedback = List.unmodifiable(feedback);
}

class WordRumbleGame extends FlameGame {
  final GameMode mode;
  final int initialLevelIndex;
  final void Function(int)? onCoinsEarned;
  final Random _random;
  GuessWords? _guessWords;

  final ValueNotifier<int> hudTicker = ValueNotifier(0);
  late final LevelDefinition _level;
  late final LevelTheme currentTheme;
  late final String targetWord;
  late final double totalTime;
  late double remainingTime;

  final List<SlotComponent> _slots = [];
  final List<LetterComponent> _tiles = [];
  final List<GuessResult> _history = [];
  int _nextTileId = 0;
  int _rackCapacity = 0;
  double _layoutWidth = 0;
  double _layoutHeight = 0;
  double _freeze = 0;
  double _hudElapsed = 0;
  double _motionTime = 0;
  final List<double> _shelfEdges = [];
  double lavaKickSpeed = 350;
  double get windOffset => min(24.0, size.x * 0.07) * sin(_motionTime * 1.4);
  LetterComponent? _dragged;
  final Vector2 _dragOrigin = Vector2.zero();

  bool _ready = false;
  bool _over = false;
  bool _won = false;
  bool _roundPaused = false;
  bool _deferredHud = false;
  bool _disposed = false;
  String? lastResultMessage;

  List<SlotComponent> get slots => List.unmodifiable(_slots);
  List<LetterComponent> get tiles => List.unmodifiable(_tiles);
  List<GuessResult> get guessHistory => List.unmodifiable(_history);
  bool get isWordRumble => mode == GameMode.wordRumble;
  int get levelIndex => _level.index;
  int get maxGuesses => _level.maxGuesses;
  int get guessesUsed => _history.length;
  bool get isFrozen => _freeze > 0;
  bool get isReady => _ready;
  bool get isGameOver => _over;
  bool get isWon => _won;
  bool get isRoundPaused => _roundPaused;
  bool get _playing => _ready && !_roundPaused && !_over && !_disposed;

  WordRumbleGame({
    required this.mode,
    required this.initialLevelIndex,
    this.onCoinsEarned,
    Random? random,
    GuessWords? guessWords,
    String? targetOverride,
  }) : _random = random ?? Random(),
       _guessWords = guessWords {
    _level = LevelRepository.getCampaignLevel(initialLevelIndex);
    currentTheme = LevelRepository.getThemeById(_level.themeId);
    targetWord =
        isWordRumble
            ? targetOverride ??
                GuessWords.targets[_random.nextInt(GuessWords.targets.length)]
            : _level.targetWord;
    totalTime = _level.timeLimitSeconds.toDouble();
    remainingTime = totalTime;
  }

  @override
  Color backgroundColor() => currentTheme.backgroundColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (isWordRumble) _guessWords ??= await GuessWords.load();
    if (_disposed) return;
    _buildBoard();
    _ready = true;
    _notifyHud();
  }

  void _buildBoard() {
    for (var i = 0; i < targetWord.length; i++) {
      final slot = SlotComponent(index: i, baseColor: currentTheme.slotColor);
      _slots.add(slot);
      add(slot);
    }
    final rack = <({String letter, bool decoy})>[
      for (final char in (isWordRumble ? GuessWords.rack : targetWord).split(
        '',
      ))
        (letter: char, decoy: false),
      if (!isWordRumble)
        for (var i = 0; i < _level.decoyCount; i++)
          (letter: String.fromCharCode(65 + _random.nextInt(26)), decoy: true),
    ]..shuffle(_random);
    _rackCapacity = rack.length;
    for (final entry in rack) {
      final tile = LetterComponent(
        board: this,
        id: _nextTileId++,
        letter: entry.letter,
        isDecoy: entry.decoy,
        homeIndex: _tiles.length,
        phase: _random.nextDouble() * 2 * pi,
      );
      _tiles.add(tile);
      add(tile);
    }
    _layoutBoard();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_tiles.isEmpty || size.x <= 0 || size.y <= 0) return;
    if (size.x == _layoutWidth && size.y == _layoutHeight) return;
    cancelDrag();
    _layoutBoard(preservePositions: true);
  }

  void _layoutBoard({bool preservePositions = false}) {
    final width = size.x;
    final height = size.y;
    if (width <= 0 || height <= 0) return;
    final gap = min(8.0, min(height * 0.04, width * 0.018));
    final side = min(
      68.0,
      min(height * .25, (width - gap * (_slots.length + 1)) / _slots.length),
    );
    final left =
        (width - (_slots.length * side + (_slots.length - 1) * gap)) / 2;
    for (final slot in _slots) {
      slot.size.setAll(side);
      slot.position.setValues(
        left + slot.index * (side + gap) + side / 2,
        gap + side / 2,
      );
    }

    final tileSize = min(58.0, side * 0.92);
    final half = tileSize / 2;
    final bottom = height - half;
    final top = min(bottom, gap * 2 + side + half);
    final shelves =
        currentTheme.physicsStyle == PhysicsStyle.wind ||
        currentTheme.physicsStyle == PhysicsStyle.lava;
    // Leave room on both sides for a whole row to move with the same gust.
    final inset = shelves ? min(24.0, width * 0.07) : 0.0;
    final rackWidth = width - inset * 2;
    final columns = max(1, ((rackWidth + gap) / (tileSize + gap)).floor());
    final rows = (_rackCapacity / columns).ceil();
    final lowestShelf = max(top, bottom - gap);
    final rowPitch = min(tileSize + 78, (lowestShelf - top) / max(1, rows - 1));
    final topShelf = lowestShelf - rowPitch * (rows - 1);
    final spawnLift = min(48.0, topShelf - top);
    final kickRoom = rows == 1 ? lowestShelf - top : rowPitch - tileSize - gap;
    if (currentTheme.physicsStyle == PhysicsStyle.lava) {
      lavaKickSpeed = min(
        350.0,
        sqrt(2 * currentTheme.gravity * max(0.0, kickRoom)),
      );
    }
    _shelfEdges.clear();
    if (shelves) {
      for (var row = 0; row < rows; row++) {
        _shelfEdges.add(topShelf + rowPitch * row + half);
      }
    }
    for (final tile in _tiles) {
      tile.setSide(tileSize);
      if (shelves) {
        final row = tile.homeIndex ~/ columns;
        final rowCount = min(columns, _rackCapacity - row * columns);
        final column = tile.homeIndex % columns;
        final floor = _shelfEdges[row] - half;
        tile.landingY = floor;
        tile.home.setValues(
          inset + rackWidth * (column + 0.5) / rowCount,
          floor - spawnLift,
        );
      } else {
        final fraction = (tile.homeIndex + 0.5) / _rackCapacity;
        final row = tile.homeIndex % rows;
        tile.home.setValues(
          half + fraction * (width - tileSize),
          top + (bottom - top) * (row + 0.65) / (rows + 0.4),
        );
      }
      final slot = _slotOf(tile);
      if (slot != null) {
        tile.position.setFrom(slot.position);
      } else if (preservePositions && _layoutWidth > 0 && _layoutHeight > 0) {
        tile.position.setValues(
          (tile.x * width / _layoutWidth).clamp(half, width - half),
          (tile.y * height / _layoutHeight).clamp(half, height - half),
        );
      } else {
        tile.returnHome();
      }
    }
    _layoutWidth = width;
    _layoutHeight = height;
  }

  @override
  void render(Canvas canvas) {
    if (_shelfEdges.isNotEmpty) {
      final paint =
          Paint()
            ..color = currentTheme.slotColor.withValues(alpha: .28)
            ..strokeWidth = 2;
      for (final edge in _shelfEdges) {
        canvas.drawLine(
          Offset(6, edge + 1),
          Offset(size.x - 6, edge + 1),
          paint,
        );
      }
    }
    super.render(canvas);
  }

  SlotComponent? _slotOf(LetterComponent tile) {
    for (final slot in _slots) {
      if (slot.tile == tile) return slot;
    }
    return null;
  }

  bool canMove(LetterComponent tile) =>
      _playing &&
      _dragged != tile &&
      _tiles.contains(tile) &&
      _slotOf(tile) == null;

  bool beginDrag(LetterComponent tile) {
    if (!_playing || _dragged != null || !_tiles.contains(tile)) return false;
    _dragged = tile;
    _dragOrigin.setFrom(tile.position);
    return true;
  }

  void cancelDrag() {
    final tile = _dragged;
    if (tile == null) return;
    tile.position.setFrom(_slotOf(tile)?.position ?? _dragOrigin);
    tile.velocity.setZero();
    tile.forgetPointer();
    _dragged = null;
  }

  void releaseDrag(LetterComponent tile, Vector2 finger, Vector2 velocity) {
    if (!_playing || _dragged != tile) return;
    if (finger.x < 0 ||
        finger.x > size.x ||
        finger.y < 0 ||
        finger.y > size.y) {
      cancelDrag();
      return;
    }
    SlotComponent? destination;
    for (final slot in _slots) {
      if ((finger.x - slot.x).abs() <= slot.width / 2 &&
          (finger.y - slot.y).abs() <= slot.height / 2) {
        destination = slot;
        break;
      }
    }
    if (destination?.tile != null && destination!.tile != tile) {
      cancelDrag();
      return;
    }
    final origin = _slotOf(tile);
    origin?.tile = null;
    tile.forgetPointer();
    _dragged = null;
    if (destination == null) {
      tile.velocity.setFrom(velocity);
      tile.velocity.clampLength(0, 550);
    } else {
      destination.tile = tile;
      tile.position.setFrom(destination.position);
      tile.velocity.setZero();
    }
    lastResultMessage = null;
    _checkCampaignRow();
    _notifyHud();
  }

  String get _row => _slots.map((s) => s.currentLetter ?? '').join();

  void _checkCampaignRow() {
    if (!isWordRumble && _row == targetWord) _finish(won: true);
  }

  void submitCurrentGuess() {
    if (!_playing || !isWordRumble || _dragged != null) return;
    final guess = _row;
    if (guess.length != targetWord.length) {
      lastResultMessage = 'Fill every slot before submitting.';
    } else if (!_guessWords!.accepts(guess)) {
      lastResultMessage = 'That word is not in the word list.';
    } else {
      _history.add(
        GuessResult(guess: guess, feedback: evaluateGuess(targetWord, guess)),
      );
      if (guess == targetWord) {
        _finish(won: true);
      } else if (guessesUsed == maxGuesses) {
        _finish(won: false);
      } else {
        for (final slot in _slots) {
          slot.tile!.returnHome();
          slot.tile = null;
        }
        lastResultMessage = null;
      }
    }
    _notifyHud();
  }

  static List<SlotFeedback> evaluateGuess(String target, String guess) {
    final result = List.filled(guess.length, SlotFeedback.absent);
    final remaining = <String, int>{};
    for (var i = 0; i < target.length; i++) {
      if (target[i] == guess[i]) {
        result[i] = SlotFeedback.correct;
      } else {
        remaining.update(target[i], (n) => n + 1, ifAbsent: () => 1);
      }
    }
    for (var i = 0; i < guess.length; i++) {
      final letter = guess[i];
      final count = remaining[letter] ?? 0;
      if (result[i] != SlotFeedback.correct && count > 0) {
        result[i] = SlotFeedback.present;
        remaining[letter] = count - 1;
      }
    }
    return result;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_playing || dt <= 0) return;
    _motionTime += min(dt, .05);
    final frozen = min(_freeze, dt);
    _freeze -= frozen;
    remainingTime = max(0, remainingTime - (dt - frozen));
    if (remainingTime == 0) {
      _finish(won: false);
      return;
    }
    _hudElapsed += dt;
    if (_hudElapsed >= .1) {
      _hudElapsed = 0;
      _notifyHud();
    }
  }

  void _finish({required bool won}) {
    if (_over) return;
    cancelDrag();
    _over = true;
    _won = won;
    lastResultMessage =
        won
            ? 'You spelled $targetWord!'
            : remainingTime <= 0
            ? 'Time is up! The word was $targetWord.'
            : 'Out of guesses! The word was $targetWord.';
    if (won && !isWordRumble) onCoinsEarned?.call(_level.rewardCoins);
    _notifyHud();
  }

  void setRoundPaused(bool paused) {
    if (_over || _roundPaused == paused) return;
    cancelDrag();
    _roundPaused = paused;
    _notifyHud();
  }

  bool canUsePowerUp(PowerUpType type) {
    if (!_playing || _dragged != null) return false;
    return switch (type) {
      PowerUpType.freezeTime => !isFrozen,
      PowerUpType.hintLetter => _slots.any(
        (s) => s.currentLetter != targetWord[s.index],
      ),
      PowerUpType.clearDecoys =>
        !isWordRumble && _tiles.any((t) => t.isDecoy && _slotOf(t) == null),
    };
  }

  bool onPowerUpUsed(PowerUpType type) {
    if (!canUsePowerUp(type)) return false;
    switch (type) {
      case PowerUpType.freezeTime:
        _freeze = 5;
      case PowerUpType.hintLetter:
        final slot = _slots.firstWhere(
          (s) => s.currentLetter != targetWord[s.index],
        );
        final correct = targetWord[slot.index];
        // Protect already-correct copies when choosing between duplicate tiles.
        final tile = _tiles.firstWhere((t) {
          if (t.letter != correct) return false;
          final other = _slotOf(t);
          return other == null || targetWord[other.index] != correct;
        });
        _slotOf(tile)?.tile = null;
        slot.tile?.returnHome();
        slot.tile = tile;
        tile.position.setFrom(slot.position);
        tile.velocity.setZero();
        _checkCampaignRow();
      case PowerUpType.clearDecoys:
        final clear =
            _tiles
                .where((t) => t.isDecoy && _slotOf(t) == null)
                .take(3)
                .toList();
        for (final tile in clear) {
          _tiles.remove(tile);
          tile.removeFromParent();
        }
    }
    _notifyHud();
    return true;
  }

  void shuffleLetters() {
    if (!_playing || _dragged != null) return;
    final free =
        _tiles.where((t) => _slotOf(t) == null).toList()..shuffle(_random);
    if (free.isEmpty) return;
    if (free.length > 1) {
      final homes = free.map((t) => t.home.clone()).toList();
      final indices = free.map((t) => t.homeIndex).toList();
      final landings = free.map((t) => t.landingY).toList();
      for (var i = 0; i < free.length; i++) {
        final next = (i + 1) % free.length;
        free[i].home.setFrom(homes[next]);
        free[i].homeIndex = indices[next];
        free[i].landingY = landings[next];
        free[i].returnHome();
      }
    } else {
      final tile = free.single;
      tile.returnHome();
      tile.position.y = (tile.y + tile.height * 0.5).clamp(
        tile.height / 2,
        size.y - tile.height / 2,
      );
      tile.velocity.y = -80;
    }
    _notifyHud();
  }

  void restartLevel() {
    if (!_ready || _disposed) return;
    cancelDrag();
    for (final tile in _tiles) {
      tile.removeFromParent();
    }
    for (final slot in _slots) {
      slot.removeFromParent();
    }
    _tiles.clear();
    _slots.clear();
    _history.clear();
    _freeze = 0;
    _hudElapsed = 0;
    _motionTime = 0;
    remainingTime = totalTime;
    _over = false;
    _won = false;
    _roundPaused = false;
    lastResultMessage = null;
    _buildBoard();
    _notifyHud();
  }

  void _notifyHud() {
    if (_disposed) return;
    final scheduler = SchedulerBinding.instance;
    if (scheduler.schedulerPhase != SchedulerPhase.persistentCallbacks) {
      hudTicker.value++;
    } else if (!_deferredHud) {
      _deferredHud = true;
      scheduler.addPostFrameCallback((_) {
        _deferredHud = false;
        if (!_disposed) hudTicker.value++;
      });
    }
  }

  @override
  void onDispose() {
    _disposed = true;
    hudTicker.dispose();
    super.onDispose();
  }
}
