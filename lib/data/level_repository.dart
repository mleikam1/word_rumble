import 'package:flutter/material.dart';
import 'level_theme.dart';
import 'level_definition.dart';

class LevelRepository {
  static final List<LevelTheme> themes = [
    LevelTheme(
      id: 'water_bay',
      name: 'Splash Bay',
      physicsStyle: PhysicsStyle.water,
      backgroundColor: Colors.lightBlueAccent,
      letterColor: Colors.white,
      slotColor: Colors.blueGrey.shade800,
      gravity: 600.0,
      buoyancy: -300.0, // float upwards a bit
    ),
    LevelTheme(
      id: 'lava_core',
      name: 'Lava Core',
      physicsStyle: PhysicsStyle.lava,
      backgroundColor: Colors.deepOrange,
      letterColor: Colors.yellowAccent,
      slotColor: Colors.brown.shade900,
      gravity: 900.0,
      buoyancy: 0.0,
    ),
    LevelTheme(
      id: 'wind_peak',
      name: 'Wind Peak',
      physicsStyle: PhysicsStyle.wind,
      backgroundColor: Colors.lightGreenAccent,
      letterColor: Colors.black87,
      slotColor: Colors.green.shade900,
      gravity: 500.0,
      buoyancy: -150.0,
    ),
    LevelTheme(
      id: 'zero_station',
      name: 'Zero-G Station',
      physicsStyle: PhysicsStyle.zeroG,
      backgroundColor: Colors.deepPurple.shade700,
      letterColor: Colors.white,
      slotColor: Colors.deepPurple.shade200,
      gravity: 0.0,
      buoyancy: 0.0,
    ),
  ];

  static final List<LevelDefinition> campaignLevels = [
    LevelDefinition(
      index: 1,
      targetWord: 'WATER',
      themeId: 'water_bay',
      timeLimitSeconds: 30,
      rewardCoins: 5,
      decoyCount: 2,
    ),
    LevelDefinition(
      index: 2,
      targetWord: 'FIRE',
      themeId: 'lava_core',
      timeLimitSeconds: 25,
      rewardCoins: 6,
      decoyCount: 3,
    ),
    LevelDefinition(
      index: 3,
      targetWord: 'STORM',
      themeId: 'wind_peak',
      timeLimitSeconds: 35,
      rewardCoins: 8,
      decoyCount: 4,
      isBossLevel: true,
    ),
  ];

  static LevelTheme getThemeById(String id) {
    return themes.firstWhere((t) => t.id == id);
  }

  static LevelDefinition getCampaignLevel(int index) {
    return campaignLevels.firstWhere((l) => l.index == index);
  }
}
