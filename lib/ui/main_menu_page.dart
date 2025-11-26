import 'package:flutter/material.dart';
import '../core/game_mode.dart';
import 'game_page.dart';
import 'widgets/banner_ad_slot.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Rumble'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Text(
              'Choose Your Mode',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const GamePage(
                        mode: GameMode.campaign,
                        initialLevelIndex: 1,
                      ),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Campaign Mode\n(Crazy Physics)',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const GamePage(
                        mode: GameMode.wordRumble,
                        initialLevelIndex: 1,
                      ),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Word Rumble Mode\n(Word-Guess Chaos)',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const Spacer(),
            const BannerAdSlot(),
          ],
        ),
      ),
    );
  }
}
