import 'package:flutter/material.dart';

import '../core/game_mode.dart';
import 'game_page.dart';
import 'widgets/banner_ad_slot.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    Widget modeButton(GameMode mode, String label) => ElevatedButton(
      onPressed:
          () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => GamePage(mode: mode, initialLevelIndex: 1),
            ),
          ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Word Rumble')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Choose Your Mode',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  modeButton(
                    GameMode.campaign,
                    'Campaign Mode\n(Crazy Physics)',
                  ),
                  const SizedBox(height: 16),
                  modeButton(
                    GameMode.wordRumble,
                    'Word Rumble Mode\n(Word-Guess Chaos)',
                  ),
                ],
              ),
            ),
            const BannerAdSlot(),
          ],
        ),
      ),
    );
  }
}
