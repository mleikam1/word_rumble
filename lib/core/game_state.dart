import 'package:flutter/foundation.dart';

class GameState extends ChangeNotifier {
  int _coins = 0;

  int get coins => _coins;

  void addCoins(int amount) {
    _coins += amount;
    notifyListeners();
  }

  bool spendCoins(int amount) {
    if (_coins >= amount) {
      _coins -= amount;
      notifyListeners();
      return true;
    }
    return false;
  }

// TODO: Persist unlocked worlds, completed levels, etc.
}
