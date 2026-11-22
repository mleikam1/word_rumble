import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:word_rumble/core/game_state.dart';
import 'package:word_rumble/data/powerup_definition.dart';
import 'package:word_rumble/ui/screens/support_screens.dart';
import 'package:word_rumble/ui/style.dart';

Future<void> showScreen(
  WidgetTester tester,
  GameState wallet,
  Widget child,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ChangeNotifierProvider<GameState>.value(
      value: wallet,
      child: MaterialApp(
        theme: rumbleTheme(),
        home: Scaffold(body: child),
        routes: {'/worlds': (_) => const Scaffold(body: Text('World list'))},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String text) async {
  final target = find.text(text).last;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Canceled purchases keep coins, confirmed purchases deliver once',
    (tester) async {
      final wallet = GameState()..addCoins(10);
      await showScreen(tester, wallet, const ShopPage(embedded: true));
      await tapText(tester, '10 coins');
      await tapText(tester, 'Cancel');
      expect(wallet.coins, 10);
      await tapText(tester, '10 coins');
      await tapText(tester, 'Spend 10 coins');
      expect(wallet.coins, 0);
      expect(wallet.stock(PowerUpType.hintLetter), 1);
      await tapText(tester, '10 coins');
      await tapText(tester, 'Explore levels');
      expect(find.text('World list'), findsOneWidget);
    },
  );
  testWidgets('Settings, field guide, local-data reset confirmation', (
    tester,
  ) async {
    final wallet = GameState()..addCoins(70);
    await showScreen(tester, wallet, const SettingsPage(embedded: true));
    await tapText(tester, 'Reduced motion');
    expect(wallet.reducedMotion, true);
    await tapText(tester, 'How to play');
    await tapText(tester, 'Rumble');
    expect(find.text('Example answer: WATER'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapText(tester, 'About & local data');
    await tapText(tester, 'Reset local progress');
    await tapText(tester, 'Keep progress');
    expect(wallet.coins, 70);
    await tapText(tester, 'Reset local progress');
    await tapText(tester, 'Reset progress');
    expect(wallet.coins, 0);
  });
  testWidgets('In-game settings omit destructive actions', (tester) async {
    final wallet = GameState();
    await showScreen(tester, wallet, const SettingsPage());
    await tapText(tester, 'About & local data');
    expect(find.text('Open-source licenses'), findsOneWidget);
    expect(find.text('Reset local progress'), findsNothing);
  });
}
