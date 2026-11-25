import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:word_rumble/core/game_state.dart';
import 'package:word_rumble/data/level_definition.dart';
import 'package:word_rumble/data/level_repository.dart';
import 'package:word_rumble/ui/screens/worlds.dart';

void main() {
  testWidgets('each atlas stop has its own briefing, unlock and best medal', (
    t,
  ) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(320, 670);
    addTearDown(t.view.reset);
    final profile = GameState();
    final first = LevelRepository.campaignLevels.first;
    final second = LevelRepository.campaignLevels[1];
    final secondEntry = find.byKey(ValueKey('campaign-map-${second.index}'));
    await t.pumpWidget(
      ChangeNotifierProvider.value(
        value: profile,
        child: const MaterialApp(home: WorldsPage()),
      ),
    );
    await t.scrollUntilVisible(secondEntry, 150);
    await t.tap(secondEntry);
    await t.pumpAndSettle();
    final play = find.byKey(const ValueKey('campaign-start'));
    await t.scrollUntilVisible(play, 100);
    expect(t.widget<FilledButton>(play).onPressed, isNull);
    expect(find.text('Clear ${first.targetWord} to unlock'), findsOneWidget);
    await t.pageBack();
    await t.pumpAndSettle();
    profile.winCampaign(
      first.index,
      first.rewardCoins,
      medal: CampaignMedal.clean,
      attempt: Object(),
    );
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('Clean medal · Replay'), -120);
    expect(find.text('Clean medal · Replay'), findsOneWidget);
    await t.scrollUntilVisible(secondEntry, 120);
    await t.tap(secondEntry);
    await t.pumpAndSettle();
    expect(find.text(second.targetWord), findsOneWidget);
    await t.scrollUntilVisible(play, 100);
    expect(t.widget<FilledButton>(play).onPressed, isNotNull);
  });
}
