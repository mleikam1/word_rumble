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
      timeLimitSeconds: 35,
      rewardCoins: 5,
      decoyLetters: 'S',
      tip: 'Aim at a numbered berth. Hold steady, then release.',
      swiftSecondsLeft: 12,
    ),
    LevelDefinition(
      index: 4,
      requiresClear: 1,
      targetWord: 'SHIP',
      themeId: 'water_bay',
      timeLimitSeconds: 35,
      rewardCoins: 5,
      decoyLetters: 'A',
      hazard: HazardKind.swell,
      hazardPeriod: 6.0,
      warningDuration: 1.3,
      burstDuration: 1.1,
      tip: 'Watch the swell rise. Release when the dock lies low.',
      swiftSecondsLeft: 12,
    ),
    LevelDefinition(
      index: 5,
      requiresClear: 4,
      targetWord: 'BUOY',
      themeId: 'water_bay',
      timeLimitSeconds: 35,
      rewardCoins: 5,
      decoyLetters: 'S',
      landingRadius: .53,
      hazard: HazardKind.swell,
      hazardPeriod: 6.0,
      warningDuration: 1.3,
      burstDuration: 1.1,
      tip: 'Ride out the swell and settle BUOY as the dock steadies.',
      swiftSecondsLeft: 12,
    ),
    LevelDefinition(
      index: 2,
      requiresClear: 5,
      targetWord: 'FIRE',
      themeId: 'lava_core',
      timeLimitSeconds: 25,
      rewardCoins: 6,
      decoyLetters: 'A',
      layout: BerthLayout.ledges,
      hazard: HazardKind.vent,
      hazardPeriod: 5.6,
      warningDuration: 1.2,
      burstDuration: .9,
      landingRadius: .53,
      tip: 'A glowing vent is about to puff. Land in the quiet interval.',
      swiftSecondsLeft: 7,
    ),
    LevelDefinition(
      index: 6,
      requiresClear: 2,
      targetWord: 'EMBER',
      themeId: 'lava_core',
      timeLimitSeconds: 30,
      rewardCoins: 6,
      decoyLetters: 'A',
      layout: BerthLayout.ledges,
      hazard: HazardKind.vent,
      hazardPeriod: 5.6,
      warningDuration: 1.2,
      burstDuration: .9,
      landingRadius: .53,
      tip: 'Catch both Es. The ledges steady after each vent puff.',
      swiftSecondsLeft: 9,
    ),
    LevelDefinition(
      index: 7,
      requiresClear: 6,
      targetWord: 'GUST',
      themeId: 'wind_peak',
      timeLimitSeconds: 35,
      rewardCoins: 7,
      decoyLetters: 'A',
      layout: BerthLayout.ridge,
      hazard: HazardKind.gust,
      hazardPeriod: 6.2,
      warningDuration: 1.2,
      burstDuration: 1.15,
      landingRadius: .53,
      tip: 'Follow the flag. Set a letter down as the wind eases.',
      swiftSecondsLeft: 11,
    ),
    LevelDefinition(
      index: 3,
      requiresClear: 7,
      targetWord: 'STORM',
      themeId: 'wind_peak',
      timeLimitSeconds: 35,
      rewardCoins: 8,
      decoyLetters: 'A',
      layout: BerthLayout.ridge,
      hazard: HazardKind.storm,
      hazardPeriod: 8.0,
      stormFirstWarning: .75,
      stormCalmGap: .9,
      warningDuration: 1.2,
      burstDuration: 1.15,
      landingRadius: .53,
      tip: 'Two gusts blow in opposite directions. Land in the calm between.',
      swiftSecondsLeft: 10,
      isBossLevel: true,
    ),
  ];

  static int positionOf(int id) =>
      campaignLevels.indexWhere((l) => l.index == id) + 1;

  static LevelTheme getThemeById(String id) {
    return themes.firstWhere((t) => t.id == id);
  }

  static LevelDefinition getCampaignLevel(int index) {
    return campaignLevels.firstWhere((l) => l.index == index);
  }
}
