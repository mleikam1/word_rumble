import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/level_definition.dart';
import '../data/level_repository.dart';
import '../data/powerup_definition.dart';
import '../data/supplies.dart';

/// A single local profile owns currency, purchases, progress and preferences.
class GameState extends ChangeNotifier {
  GameState([this._prefs]);
  final SharedPreferences? _prefs;
  static const _key = 'word_rumble.profile.v1';
  Future<void> _pending = Future.value();
  bool saveUnavailable = false;
  int _coins = 0;
  int get coins => _coins;
  final Set<int> _completed = {};
  final Set<int> _legacyAccess = {};
  final Map<int, CampaignMedal> _medals = {};
  final _creditedAttempts = Expando<bool>();
  final Map<String, int> _bag = {};
  int campaignWins = 0;
  bool sound = true;
  bool haptics = true;
  bool colorClues = true;
  bool reducedMotion = false;
  String dailyKey = '';
  String dailyStatus = '';
  int dailyGuesses = 0;
  int dailyWins = 0;

  static Future<GameState> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final model = GameState(prefs);
      final raw = prefs.getString(_key);
      if (raw == null) return model;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      int count(Object? v) => v is int && v >= 0 ? v : 0;
      model._coins = count(data['coins']);
      model.campaignWins = count(data['wins']);
      model.dailyWins = count(data['dailyWins']);
      model.dailyGuesses = count(data['dailyGuesses']);
      model.dailyKey = data['dailyKey'] as String? ?? '';
      model.dailyStatus = data['dailyStatus'] as String? ?? '';
      model.sound = data['sound'] as bool? ?? true;
      model.haptics = data['haptics'] as bool? ?? true;
      model.colorClues = data['colorClues'] as bool? ?? true;
      model.reducedMotion = data['reducedMotion'] as bool? ?? false;
      model._completed.addAll(
        (data['completed'] as List? ?? []).whereType<int>(),
      );
      final oldAccess = data['legacyAccess'];
      if (oldAccess is List) {
        model._legacyAccess.addAll(oldAccess.whereType<int>());
      } else {
        // v1 unlocked FIRE from WATER, and STORM from FIRE. Keep those
        // destinations open without inventing clears for the inserted rounds.
        if (model.completed(1)) model._legacyAccess.add(2);
        if (model.completed(2)) model._legacyAccess.add(3);
      }
      final medals = data['medals'];
      if (medals is Map) {
        for (final entry in medals.entries) {
          final id = int.tryParse(entry.key.toString());
          final medal =
              CampaignMedal.values
                  .where((m) => m.name == entry.value)
                  .firstOrNull;
          if (id != null && medal != null) model._medals[id] = medal;
        }
      }
      final stock = data['stock'] as Map? ?? {};
      for (final type in PowerUpType.values) {
        model._bag[type.name] = count(stock[type.name]);
      }
      if (model.dailyStatus == 'playing') {
        model.dailyStatus = 'interrupted';
        model._save();
      }
      return model;
    } on Exception {
      return GameState()..saveUnavailable = true;
    } on TypeError {
      return GameState()..saveUnavailable = true;
    }
  }

  void _save() {
    final prefs = _prefs;
    if (prefs != null) {
      final next = jsonEncode({
        'coins': _coins,
        'wins': campaignWins,
        'completed': _completed.toList(),
        'legacyAccess': _legacyAccess.toList(),
        'medals': _medals.map(
          (id, medal) => MapEntry(id.toString(), medal.name),
        ),
        'stock': _bag,
        'dailyKey': dailyKey,
        'dailyStatus': dailyStatus,
        'dailyGuesses': dailyGuesses,
        'dailyWins': dailyWins,
        'sound': sound,
        'haptics': haptics,
        'colorClues': colorClues,
        'reducedMotion': reducedMotion,
      });
      _pending = _pending.then((_) async {
        try {
          saveUnavailable = !await prefs.setString(_key, next);
        } on Exception {
          saveUnavailable = true;
        }
      });
    }
    notifyListeners();
  }

  bool completed(int level) => _completed.contains(level);
  CampaignMedal? bestMedal(int id) =>
      _medals[id] ?? (completed(id) ? CampaignMedal.clear : null);

  bool unlocked(int id) {
    final level =
        LevelRepository.campaignLevels
            .where((entry) => entry.index == id)
            .firstOrNull;
    if (level == null) return false;
    return completed(id) ||
        _legacyAccess.contains(id) ||
        level.requiresClear == null ||
        completed(level.requiresClear!);
  }

  void winCampaign(
    int index,
    int reward, {
    required Object attempt,
    CampaignMedal medal = CampaignMedal.clear,
  }) {
    if (_creditedAttempts[attempt] == true) return;
    _creditedAttempts[attempt] = true;
    final previous = bestMedal(index);
    if (previous == null || medal.index > previous.index) {
      _medals[index] = medal;
    }
    _completed.add(index);
    campaignWins++;
    _coins += reward;
    _save();
  }

  void addCoins(int amount) {
    if (amount <= 0) return;
    _coins += amount;
    _save();
  }

  bool spendCoins(int amount) {
    if (amount <= 0 || _coins < amount) return false;
    _coins -= amount;
    _save();
    return true;
  }

  int stock(PowerUpType type) => _bag[type.name] ?? 0;
  bool buy(PowerUpType type) {
    final cost = supplies.firstWhere((v) => v.type == type).cost;
    if (_coins < cost) return false;
    _coins -= cost;
    _bag[type.name] = stock(type) + 1;
    _save();
    return true;
  }

  bool useStock(PowerUpType type) {
    if (stock(type) < 1) return false;
    _bag[type.name] = stock(type) - 1;
    _save();
    return true;
  }

  bool beginDaily(String day) {
    if (dailyKey == day ||
        (dailyKey.isNotEmpty && dailyKey.compareTo(day) > 0)) {
      return false;
    }
    dailyKey = day;
    dailyGuesses = 0;
    dailyStatus = 'playing';
    _save();
    return true;
  }

  void finishDaily(String day, bool won, int guesses) {
    if (dailyKey != day || dailyStatus != 'playing') return;
    dailyStatus = won ? 'won' : 'closed';
    dailyGuesses = guesses;
    if (won) dailyWins++;
    _save();
  }

  void setPreference(String key, bool value) {
    switch (key) {
      case 'sound':
        sound = value;
      case 'haptics':
        haptics = value;
      case 'reducedMotion':
        reducedMotion = value;
      case 'colorClues':
        colorClues = value;
      default:
        return;
    }
    _save();
  }

  void feedback() {
    if (sound) unawaited(SystemSound.play(SystemSoundType.click));
    if (haptics) unawaited(HapticFeedback.selectionClick());
  }

  void resetProfile() {
    _coins = 0;
    _completed.clear();
    _legacyAccess.clear();
    _medals.clear();
    _bag.clear();
    campaignWins = 0;
    dailyWins = 0;
    dailyKey = dailyStatus = '';
    dailyGuesses = 0;
    sound = haptics = colorClues = true;
    reducedMotion = false;
    _save();
  }
}
