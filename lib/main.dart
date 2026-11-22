import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:provider/provider.dart';
import 'core/game_state.dart';
import 'ui/main_menu_page.dart';
import 'ui/screens/rumble_lobby.dart';
import 'ui/screens/support_screens.dart';
import 'ui/screens/worlds.dart';
import 'ui/style.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    for (final family in ['Barlow', 'DMSans']) {
      final text = await rootBundle.loadString('assets/fonts/OFL-$family.txt');
      yield LicenseEntryWithLineBreaks([family], text);
    }
  });
  runApp(WordRumbleApp(profile: await GameState.load()));
}

class WordRumbleApp extends StatelessWidget {
  const WordRumbleApp({super.key, this.profile});
  final GameState? profile;
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => profile ?? GameState(),
    child: MaterialApp(
      title: 'Word Rumble',
      debugShowCheckedModeBanner: false,
      theme: rumbleTheme(),
      builder: (context, child) {
        final reduced = context.select<GameState, bool>((m) => m.reducedMotion);
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            disableAnimations: media.disableAnimations || reduced,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              pageTransitionsTheme:
                  reduced
                      ? const PageTransitionsTheme(
                        builders: {
                          TargetPlatform.android: _StillTransition(),
                          TargetPlatform.iOS: _StillTransition(),
                          TargetPlatform.macOS: _StillTransition(),
                          TargetPlatform.windows: _StillTransition(),
                          TargetPlatform.linux: _StillTransition(),
                          TargetPlatform.fuchsia: _StillTransition(),
                        },
                      )
                      : null,
            ),
            child: child!,
          ),
        );
      },
      home: const MainMenuPage(),
      routes: {
        '/worlds': (_) => const WorldsPage(),
        '/shop': (_) => const ShopPage(),
        '/settings': (_) => const SettingsPage(),
        '/guide': (_) => const GuidePage(),
        '/passport': (_) => const PassportPage(),
        '/rumble': (_) => const RumbleLobby(),
        '/daily': (_) => const RumbleLobby(daily: true),
      },
    ),
  );
}

class _StillTransition extends PageTransitionsBuilder {
  const _StillTransition();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
