import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_rumble/core/game_mode.dart';
import 'package:word_rumble/data/level_definition.dart';
import 'package:word_rumble/data/level_repository.dart';
import 'package:word_rumble/data/level_theme.dart';
import 'package:word_rumble/game/word_rumble_game.dart';

void main() {
  testWidgets('Zero-G and Ice behavior can be exercised with fixture levels', (
    tester,
  ) async {
    final shipped = LevelRepository.campaignLevels.map(
      (level) => level.themeId,
    );
    expect(shipped, ['water_bay', 'lava_core', 'wind_peak']);
    expect(
      LevelRepository.themes.any((t) => t.physicsStyle == PhysicsStyle.ice),
      isFalse,
    );

    // Ice has no production theme. Isolate its rebound from gravity in this fixture.
    const ice = LevelTheme(
      id: 'test_ice',
      name: 'Test Ice',
      physicsStyle: PhysicsStyle.ice,
      backgroundColor: Colors.white,
      letterColor: Colors.black,
      slotColor: Colors.blue,
      gravity: 0,
      buoyancy: 0,
    );
    LevelRepository.themes.add(ice);
    addTearDown(() => LevelRepository.themes.remove(ice));

    Future<WordRumbleGame> mount(String theme) async {
      final level = LevelDefinition(
        index: 90 + LevelRepository.campaignLevels.length,
        targetWord: 'TEST',
        themeId: theme,
        timeLimitSeconds: 30,
        rewardCoins: 0,
      );
      LevelRepository.campaignLevels.add(level);
      addTearDown(() => LevelRepository.campaignLevels.remove(level));
      final game = WordRumbleGame(
        mode: GameMode.campaign,
        initialLevelIndex: level.index,
        random: Random(12),
      );
      await tester.pumpWidget(
        MaterialApp(home: GameWidget(key: ObjectKey(game), game: game)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      return game;
    }

    final zeroG = await mount('zero_station');
    final drifting = zeroG.tiles.first;
    final start = drifting.position.clone();
    for (var i = 0; i < 60; i++) {
      zeroG.update(1 / 60);
    }
    expect((drifting.x - start.x).abs(), greaterThan(0.1));
    expect((drifting.y - start.y).abs(), greaterThan(0.1));
    expect(zeroG.slots.every((s) => s.tile == null), isTrue);

    final iceGame = await mount('test_ice');
    final sliding = iceGame.tiles.first;
    sliding.position.y = iceGame.size.y - sliding.height / 2 - 0.1;
    sliding.velocity.y = 100;
    iceGame.update(1 / 60);
    expect(sliding.velocity.y, closeTo(-80, 0.01));
  });
}
