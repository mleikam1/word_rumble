import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/game_state.dart';
import '../data/level_repository.dart';
import 'home_tab.dart';
import 'screens/rumble_lobby.dart';
import 'screens/support_screens.dart';
import 'screens/worlds.dart';
import 'style.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: homeTab,
    builder: (context, index, _) {
      final tabs = <Widget>[
        const _Home(),
        const WorldsPage(embedded: true),
        const ShopPage(embedded: true),
        const SettingsPage(embedded: true),
      ];
      return PopScope(
        canPop: index == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && index != 0) homeTab.value = 0;
        },
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                DecoratedBox(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: InkColors.line)),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1050),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
                        child: Row(
                          children: [
                            const Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: WordMark(),
                              ),
                            ),
                            Wallet(onPressed: () => homeTab.value = 2),
                            const SizedBox(width: 4),
                            IconButton(
                              tooltip: 'Player passport',
                              onPressed:
                                  () =>
                                      Navigator.pushNamed(context, '/passport'),
                              icon: const Icon(
                                Icons.account_circle_outlined,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (context.select<GameState, bool>((v) => v.saveUnavailable))
                  const Padding(
                    padding: EdgeInsets.all(4),
                    child: Text(
                      'Device storage is unavailable. Progress lasts for this session.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(
                  child: KeyedSubtree(key: ValueKey(index), child: tabs[index]),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Material(
            color: InkColors.ink,
            child: SafeArea(
              top: false,
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: NavigationBarTheme(
                    data: NavigationBarThemeData(
                      backgroundColor: InkColors.ink,
                      indicatorColor: InkColors.gold,
                      iconTheme: WidgetStateProperty.resolveWith(
                        (s) => IconThemeData(
                          color:
                              s.contains(WidgetState.selected)
                                  ? InkColors.ink
                                  : InkColors.cream,
                          size: 22,
                        ),
                      ),
                      labelTextStyle: WidgetStateProperty.resolveWith(
                        (s) => TextStyle(
                          fontFamily: 'DM Sans',
                          color:
                              s.contains(WidgetState.selected)
                                  ? InkColors.gold
                                  : InkColors.cream,
                          fontWeight:
                              s.contains(WidgetState.selected)
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    child: NavigationBar(
                      height: 62,
                      selectedIndex: index,
                      onDestinationSelected: (v) {
                        context.read<GameState>().feedback();
                        homeTab.value = v;
                      },
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.sports_esports_outlined),
                          label: 'Play',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.map_outlined),
                          label: 'Worlds',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.storefront_outlined),
                          label: 'Shop',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.tune_rounded),
                          label: 'Settings',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _Home extends StatelessWidget {
  const _Home();
  @override
  Widget build(BuildContext context) {
    final model = context.watch<GameState>();
    final level = nextStop(model);
    final done =
        LevelRepository.campaignLevels
            .where((l) => model.completed(l.index))
            .length;
    final dailyDone = model.dailyKey == puzzleDay(DateTime.now());
    final heroAction =
        done == 0
            ? 'Play campaign'
            : done == LevelRepository.campaignLevels.length
            ? 'Replay campaign'
            : 'Continue campaign';
    final guess = _ModeCard(
      title: 'WORD GUESS',
      tag: 'RUMBLE MODE',
      detail: 'Five letters. Six guesses.',
      bg: const Color(0xffd2c4e9),
      art: const TileArt(size: 74),
      onTap: () => Navigator.pushNamed(context, '/rumble'),
    );
    final daily = _ModeCard(
      title: 'DAILY RUMBLE',
      tag: dateLabel(DateTime.now().toUtc()),
      detail: dailyDone ? 'View today’s result' : 'One shared puzzle today.',
      bg: const Color(0xffffdfa0),
      art: const DailyArt(size: 66),
      onTap: () => Navigator.pushNamed(context, '/daily'),
    );
    return LayoutBuilder(
      builder: (context, bounds) {
        final wide = bounds.maxWidth >= 780;
        final hero = WorldHero(
          level: level,
          action: heroAction,
          onTap: () => openBrief(context, level),
          tall: wide,
        );
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                wide ? 26 : 17,
                16,
                wide ? 26 : 17,
                20,
              ),
              children: [
                Row(
                  children: [
                    Expanded(child: display('PLAY', size: 39)),
                    TextButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/guide'),
                      icon: const Icon(Icons.help_outline_rounded, size: 17),
                      label: const Text('How to play'),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: hero),
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [guess, const SizedBox(height: 14), daily],
                        ),
                      ),
                    ],
                  )
                else ...[
                  hero,
                  const SizedBox(height: 15),
                  guess,
                  const SizedBox(height: 12),
                  daily,
                ],
                const SizedBox(height: 18),
                InkWell(
                  onTap: () => homeTab.value = 1,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.map_outlined, color: InkColors.teal),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text('World atlas', style: heading(24)),
                        ),
                        Text(
                          '$done / ${LevelRepository.campaignLevels.length} cleared',
                          style: const TextStyle(
                            color: InkColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.east_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.tag,
    required this.detail,
    required this.bg,
    required this.art,
    required this.onTap,
  });
  final String title, tag, detail;
  final Color bg;
  final Widget art;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$title. $detail',
    excludeSemantics: true,
    child: PosterCard(
      color: bg,
      onTap: onTap,
      child: Padding(
        padding:
            MediaQuery.sizeOf(context).width >= 780
                ? const EdgeInsets.fromLTRB(17, 47, 17, 47)
                : const EdgeInsets.fromLTRB(13, 12, 14, 12),
        child: Row(
          children: [
            SizedBox(width: 77, child: Center(child: art)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tag, style: tagStyle()),
                  const SizedBox(height: 4),
                  display(title, size: 32),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.25,
                      color: InkColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 29,
              height: 29,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: InkColors.ink),
              ),
              child: const Icon(Icons.arrow_forward_rounded, size: 18),
            ),
          ],
        ),
      ),
    ),
  );
}

class PassportPage extends StatelessWidget {
  const PassportPage({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final levels = LevelRepository.campaignLevels;
    return Scaffold(
      appBar: AppBar(title: const Text('Player passport')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              children: [
                PosterCard(
                  color: InkColors.ink,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.explore_outlined,
                          color: InkColors.gold,
                          size: 38,
                        ),
                        const SizedBox(height: 14),
                        Text('WORD RUMBLE', style: tagStyle(InkColors.gold)),
                        display(
                          'PLAYER PASSPORT',
                          size: 42,
                          color: InkColors.cream,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Progress on this device',
                          style: TextStyle(color: InkColors.cream),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 19),
                Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    for (final item in [
                      ('Coins', state.coins),
                      ('Campaign wins', state.campaignWins),
                      ('Daily wins', state.dailyWins),
                    ])
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          display('${item.$2}', size: 32),
                          Text(item.$1),
                        ],
                      ),
                  ],
                ),
                const Divider(height: 36),
                display('WORLD STAMPS', size: 30),
                const SizedBox(height: 7),
                const Text('Solve a campaign level to stamp its destination.'),
                const SizedBox(height: 13),
                for (final l in levels)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        WorldPoster.all[l.themeId]!.path,
                        width: 66,
                        height: 47,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      LevelRepository.getThemeById(l.themeId).name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      state.completed(l.index)
                          ? 'Stamp collected'
                          : 'Level ${two(l.index)}',
                    ),
                    trailing: Icon(
                      state.completed(l.index)
                          ? Icons.verified
                          : Icons.radio_button_unchecked,
                      color:
                          state.completed(l.index)
                              ? InkColors.teal
                              : InkColors.muted,
                    ),
                    onTap: () => openBrief(context, l),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
