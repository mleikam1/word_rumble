import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/game_state.dart';
import 'ui/main_menu_page.dart';

void main() {
  runApp(const WordRumbleApp());
}

class WordRumbleApp extends StatelessWidget {
  const WordRumbleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameState(),
      child: MaterialApp(
        title: 'Word Rumble',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MainMenuPage(),
      ),
    );
  }
}
