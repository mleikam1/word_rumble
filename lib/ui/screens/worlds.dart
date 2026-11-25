import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/game_mode.dart';
import '../../core/game_state.dart';
import '../../data/level_definition.dart';
import '../../data/level_repository.dart';
import '../game_page.dart';
import '../style.dart';

class WorldPoster {
  const WorldPoster(this.art, this.icon, this.tint);
  final String art;
  final IconData icon;
  final Color tint;
  static const all = <String, WorldPoster>{
    'water_bay': WorldPoster(
      'splash_bay',
      Icons.waves_rounded,
      Color(0xffb4e3cf),
    ),
    'lava_core': WorldPoster(
      'lava_core',
      Icons.local_fire_department_outlined,
      Color(0xffffb598),
    ),
    'wind_peak': WorldPoster('wind_peak', Icons.air_rounded, Color(0xffc8d7ef)),
    'zero_station': WorldPoster(
      'zero_g',
      Icons.public_rounded,
      Color(0xffd9c8e8),
    ),
  };
  String get path => 'assets/art/$art.webp';
}

String two(int value) => value.toString().padLeft(2, '0');
LevelDefinition nextStop(GameState profile) =>
    LevelRepository.campaignLevels.firstWhere(
      (l) => profile.unlocked(l.index) && !profile.completed(l.index),
      orElse: () => LevelRepository.campaignLevels.first,
    );
void openBrief(BuildContext context, LevelDefinition level) => Navigator.push(
  context,
  MaterialPageRoute<void>(
    settings: RouteSettings(name: '/campaign/${level.index}'),
    builder: (_) => LevelBriefPage(level: level),
  ),
);

class WorldHero extends StatelessWidget {
  const WorldHero({
    super.key,
    required this.level,
    required this.action,
    required this.onTap,
    this.tall = false,
  });
  final LevelDefinition level;
  final String action;
  final VoidCallback onTap;
  final bool tall;
  @override
  Widget build(BuildContext context) {
    final world = LevelRepository.getThemeById(level.themeId);
    final poster = WorldPoster.all[world.id]!;
    return Semantics(
      button: true,
      label: '$action, ${world.name}, ${level.targetWord}',
      excludeSemantics: true,
      child: PosterCard(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                poster.path,
                fit: BoxFit.cover,
                alignment: const Alignment(.45, 0),
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00071316),
                      Color(0x0A071316),
                      Color(0xee0a252d),
                    ],
                    stops: [0, .36, 1],
                  ),
                ),
              ),
            ),
            Container(
              constraints: BoxConstraints(minHeight: tall ? 338 : 260),
              padding: const EdgeInsets.all(17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Couplet(text: 'CAMPAIGN', bg: InkColors.gold),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: InkColors.cream,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'LEVEL ${two(LevelRepository.positionOf(level.index))}',
                          style: tagStyle(),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: tall ? 114 : 67),
                  Text(
                    world.name.toUpperCase(),
                    style: heading(tall ? 74 : 57, InkColors.cream),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${level.targetWord}   ·   ${level.timeLimitSeconds} seconds',
                    style: const TextStyle(
                      color: InkColors.cream,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: InkColors.gold,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              action,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: InkColors.ink,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 19,
                              color: InkColors.ink,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WorldsPage extends StatelessWidget {
  const WorldsPage({super.key, this.embedded = false});
  final bool embedded;
  @override
  Widget build(BuildContext context) {
    final profile = context.watch<GameState>();
    final levels = LevelRepository.campaignLevels;
    final done = levels.where((l) => profile.completed(l.index)).length;
    final body = ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        Text('CAMPAIGN', style: tagStyle(InkColors.teal)),
        const SizedBox(height: 4),
        display('WORLD ATLAS', size: 46),
        const SizedBox(height: 8),
        Text(
          '$done of ${levels.length} levels completed',
          style: const TextStyle(
            color: InkColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 17),
        for (final theme in LevelRepository.themes)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: PosterCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 96,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          WorldPoster.all[theme.id]!.path,
                          fit: BoxFit.cover,
                          alignment: const Alignment(.5, -.15),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0xe5102e38), Color(0x00102e38)],
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: display(
                              theme.name.toUpperCase(),
                              size: 34,
                              color: InkColors.cream,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!levels.any((l) => l.themeId == theme.id))
                    const ListTile(
                      leading: Icon(Icons.schedule_rounded),
                      title: Text('In development'),
                    ),
                  for (final level in levels.where(
                    (l) => l.themeId == theme.id,
                  ))
                    _MapRound(level: level, profile: profile),
                ],
              ),
            ),
          ),
      ],
    );
    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: body,
      ),
    );
    return embedded
        ? content
        : Scaffold(
          appBar: AppBar(title: const Text('Worlds')),
          body: SafeArea(child: content),
        );
  }
}

String _unlockText(LevelDefinition level) {
  final prerequisite = LevelRepository.getCampaignLevel(level.requiresClear!);
  return 'Clear ${prerequisite.targetWord} to unlock';
}

class _MapRound extends StatelessWidget {
  const _MapRound({required this.level, required this.profile});
  final LevelDefinition level;
  final GameState profile;

  @override
  Widget build(BuildContext context) {
    final medal = profile.bestMedal(level.index);
    final open = profile.unlocked(level.index);
    return ListTile(
      key: ValueKey('campaign-map-${level.index}'),
      leading: Text(
        two(LevelRepository.positionOf(level.index)),
        style: heading(25, InkColors.teal),
      ),
      title: Text(
        level.targetWord,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        !open
            ? _unlockText(level)
            : medal == null
            ? '${level.timeLimitSeconds}s · Ready to play'
            : '${medal.label} medal · Replay',
      ),
      trailing: Icon(
        !open
            ? Icons.lock_outline_rounded
            : medal != null
            ? Icons.workspace_premium_outlined
            : Icons.arrow_forward_rounded,
      ),
      onTap: () => openBrief(context, level),
    );
  }
}

class LevelBriefPage extends StatelessWidget {
  const LevelBriefPage({super.key, required this.level});
  final LevelDefinition level;
  @override
  Widget build(BuildContext context) {
    final world = LevelRepository.getThemeById(level.themeId);
    final spec = WorldPoster.all[world.id]!;
    final open = context.watch<GameState>().unlocked(level.index);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Level briefing'),
        actions: [
          Wallet(onPressed: () => Navigator.pushNamed(context, '/shop')),
          const SizedBox(width: 14),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 660),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
              children: [
                PosterCard(
                  child: AspectRatio(
                    aspectRatio: 2.05,
                    child: Image.asset(spec.path, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'CAMPAIGN    /    LEVEL ${two(LevelRepository.positionOf(level.index))}',
                  style: tagStyle(InkColors.teal),
                ),
                const SizedBox(height: 5),
                display(world.name.toUpperCase(), size: 52),
                const SizedBox(height: 14),
                PosterCard(
                  color: spec.tint,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(spec.icon, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('TARGET WORD', style: tagStyle()),
                              display(level.targetWord, size: 36),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 17),
                Text(
                  level.tip,
                  style: const TextStyle(fontSize: 16, height: 1.38),
                ),
                const SizedBox(height: 17),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _Fact(Icons.timer_outlined, '${level.timeLimitSeconds}s'),
                    _Fact(
                      Icons.filter_none_rounded,
                      '${level.decoyCount} decoys',
                    ),
                    _Fact(Icons.toll_rounded, '+${level.rewardCoins} coins'),
                  ],
                ),
                const SizedBox(height: 23),
                Text(
                  'Swift medal · finish with ${level.swiftSecondsLeft}s left. Clean medal · earn Swift with no misses or assists.',
                  style: const TextStyle(color: InkColors.muted),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  key: const ValueKey('campaign-start'),
                  onPressed:
                      open
                          ? () {
                            context.read<GameState>().feedback();
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder:
                                    (_) => GamePage(
                                      mode: GameMode.campaign,
                                      initialLevelIndex: level.index,
                                    ),
                              ),
                            );
                          }
                          : null,
                  icon: Icon(
                    open ? Icons.play_arrow_rounded : Icons.lock_outline,
                  ),
                  label: Text(open ? 'Play level' : _unlockText(level)),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/guide'),
                  child: const Text('How to play'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: InkColors.teal, size: 19),
      const SizedBox(width: 5),
      Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
}
