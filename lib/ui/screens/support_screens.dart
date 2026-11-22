import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/game_state.dart';
import '../../data/supplies.dart';
import '../style.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({super.key, this.embedded = false});
  final bool embedded;

  Future<void> _purchase(BuildContext context, Supply item) async {
    final wallet = context.read<GameState>();
    if (wallet.coins < item.cost) {
      final explore = await showDialog<bool>(
        context: context,
        builder:
            (dialog) => AlertDialog(
              icon: const Icon(Icons.savings_outlined),
              title: const Text('A few coins short'),
              content: Text(
                'You need ${item.cost - wallet.coins} more coins for ${item.label}. '
                'Finish campaign levels to earn coins.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialog, false),
                  child: const Text('Back to shop'),
                ),
                if (embedded)
                  FilledButton(
                    onPressed: () => Navigator.pop(dialog, true),
                    child: const Text('Explore levels'),
                  ),
              ],
            ),
      );
      if (context.mounted && explore == true) {
        await Navigator.of(context).pushNamed('/worlds');
      }
      return;
    }

    final approved = await showDialog<bool>(
      context: context,
      builder:
          (dialog) => AlertDialog(
            icon: Icon(item.icon, color: InkColors.ink),
            title: Text('Add ${item.label}?'),
            content: Text(
              'Spend ${item.cost} coins for one use. Your balance will be '
              '${wallet.coins - item.cost} coins.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialog, true),
                child: Text('Spend ${item.cost} coins'),
              ),
            ],
          ),
    );
    if (!context.mounted || approved != true) return;
    final bought = wallet.buy(item.type);
    if (bought) wallet.feedback();
    _notice(
      context,
      bought
          ? '${item.label} added to your inventory.'
          : 'Your balance is too low.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<GameState>();
    return _SupportPage(
      title: 'Shop',
      embedded: embedded,
      children: [
        display('POWER-UP SHOP'),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: InkColors.ink,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const _CoinSeal(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COIN BALANCE',
                      style: TextStyle(
                        color: Color(0xffd0dfd6),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                    display(
                      '${wallet.coins}',
                      size: 38,
                      color: InkColors.cream,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionLabel('Single-use supplies'),
        for (final item in supplies)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _Surface(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 14, 13, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Mark(icon: item.icon, color: item.color),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.label, style: _subhead),
                              const SizedBox(height: 2),
                              Text(item.description, style: _copy),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${wallet.stock(item.type)} in inventory',
                            style: _small,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: InkColors.ink,
                            foregroundColor: InkColors.cream,
                            minimumSize: const Size(0, 44),
                          ),
                          onPressed: () => _purchase(context, item),
                          icon: const Icon(Icons.toll, size: 16),
                          label: Text('${item.cost} coins'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        const _SectionLabel('Coin packs'),
        const _Surface(
          child: ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('Real-money purchases are unavailable'),
            subtitle: Text('Earn coins by completing campaign levels.'),
          ),
        ),
      ],
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, this.embedded = false});
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<GameState>();
    Widget toggle(
      IconData icon,
      String title,
      String detail,
      String key,
      bool value,
    ) {
      return SwitchListTile(
        secondary: Icon(icon, color: InkColors.ink),
        title: Text(title, style: _rowTitle),
        subtitle: Text(detail, style: _copy),
        value: value,
        onChanged: (enabled) {
          profile.setPreference(key, enabled);
          profile.feedback();
        },
      );
    }

    return _SupportPage(
      title: 'Settings',
      embedded: embedded,
      children: [
        display('SETTINGS'),
        const SizedBox(height: 24),
        const _SectionLabel('Sound & touch'),
        _Surface(
          child: Column(
            children: [
              toggle(
                Icons.volume_up_outlined,
                'Sound effects',
                'Play interface feedback.',
                'sound',
                profile.sound,
              ),
              const Divider(height: 1),
              toggle(
                Icons.vibration,
                'Haptics',
                'Use touch feedback on supported devices.',
                'haptics',
                profile.haptics,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionLabel('Accessibility'),
        _Surface(
          child: Column(
            children: [
              toggle(
                Icons.motion_photos_off_outlined,
                'Reduced motion',
                'Limit decorative movement.',
                'reducedMotion',
                profile.reducedMotion,
              ),
              const Divider(height: 1),
              toggle(
                Icons.category_outlined,
                'Clue symbols',
                'Add position markers to guess feedback.',
                'colorClues',
                profile.colorClues,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionLabel('Game information'),
        _Surface(
          child: Column(
            children: [
              _LinkRow(
                icon: Icons.menu_book_outlined,
                title: 'How to play',
                onTap:
                    () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const GuidePage(),
                      ),
                    ),
              ),
              const Divider(height: 1),
              _LinkRow(
                icon: Icons.info_outline,
                title: 'About & local data',
                onTap:
                    () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _AboutPage(canReset: embedded),
                      ),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AboutPage extends StatelessWidget {
  const _AboutPage({required this.canReset});
  final bool canReset;

  Future<void> _reset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialog) => AlertDialog(
            icon: const Icon(Icons.restart_alt),
            title: const Text('Reset local progress?'),
            content: const Text(
              'Your coin balance, power-up inventory, level progress and preferences '
              'will return to their starting values on this device. This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog, false),
                child: const Text('Keep progress'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xff963e37),
                ),
                onPressed: () => Navigator.pop(dialog, true),
                child: const Text('Reset progress'),
              ),
            ],
          ),
    );
    if (!context.mounted || confirmed != true) return;
    context.read<GameState>().resetProfile();
    _notice(context, 'Local progress reset.');
  }

  @override
  Widget build(BuildContext context) => _SupportPage(
    title: 'About & local data',
    children: [
      display('WORD RUMBLE'),
      const SizedBox(height: 8),
      const Text('Physics-driven word puzzles', style: _subhead),
      const SizedBox(height: 24),
      const _SectionLabel('Local data'),
      const _Surface(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text(
            'This device holds your level progress, coins, power-up inventory '
            'and settings. On the web, clearing site data also clears this progress.',
            style: _copy,
          ),
        ),
      ),
      const SizedBox(height: 20),
      _Surface(
        child: Column(
          children: [
            _LinkRow(
              icon: Icons.article_outlined,
              title: 'Open-source licenses',
              onTap:
                  () => showLicensePage(
                    context: context,
                    applicationName: 'Word Rumble',
                  ),
            ),
            if (canReset) ...[
              const Divider(height: 1),
              _LinkRow(
                icon: Icons.restart_alt,
                title: 'Reset local progress',
                onTap: () => _reset(context),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

class GuidePage extends StatefulWidget {
  const GuidePage({super.key, this.guess = false});
  final bool guess;

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  late bool _guess = widget.guess;

  @override
  Widget build(BuildContext context) => _SupportPage(
    title: 'How to play',
    children: [
      display('FIELD GUIDE'),
      const SizedBox(height: 18),
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(
            value: false,
            icon: Icon(Icons.map_outlined),
            label: Text('Campaign'),
          ),
          ButtonSegment(
            value: true,
            icon: Icon(Icons.grid_view),
            label: Text('Rumble'),
          ),
        ],
        showSelectedIcon: false,
        selected: {_guess},
        onSelectionChanged: (values) => setState(() => _guess = values.first),
      ),
      const SizedBox(height: 24),
      if (_guess) ...[
        const _SectionLabel('Find the hidden word'),
        const _GuideStep(
          icon: Icons.touch_app_outlined,
          title: 'Build a five-letter guess',
          body:
              'Drag tiles from the rack into the slots. Pull a tile out to change the word.',
        ),
        const _GuideStep(
          icon: Icons.check_circle_outline,
          title: 'Submit a valid word',
          body:
              'You have six accepted guesses and a countdown. An incomplete or unlisted word costs no guess.',
        ),
        const SizedBox(height: 14),
        const _Surface(child: _FeedbackExample()),
        const SizedBox(height: 18),
        const _GuideStep(
          icon: Icons.replay_outlined,
          title: 'Use what you learn',
          body:
              'The rack replenishes after a guess. Check your previous rows before you choose the next word.',
        ),
      ] else ...[
        const _SectionLabel('Spell the target'),
        const _GuideStep(
          icon: Icons.visibility_outlined,
          title: 'Read the target word',
          body:
              'Find the matching letters among the loose tiles. Watch the countdown bar at the top.',
        ),
        const _GuideStep(
          icon: Icons.touch_app_outlined,
          title: 'Drag letters into place',
          body:
              'Release each tile inside an empty slot. To change its position, drag it out or move it to another empty slot.',
        ),
        const _GuideStep(
          icon: Icons.landscape_outlined,
          title: 'Read the terrain',
          body:
              'Tiles bob in water, bounce above lava and slide with wind gusts. Spare letters can be decoys.',
        ),
        const _GuideStep(
          icon: Icons.flag_outlined,
          title: 'Finish before time runs out',
          body:
              'Filling the row with the target word completes the level and awards campaign coins.',
        ),
      ],
      const SizedBox(height: 22),
      const _SectionLabel('Power-ups'),
      _Surface(
        child: Column(
          children: [
            const ListTile(
              leading: _Mark(
                icon: Icons.shuffle,
                color: Color(0xff9dc7b5),
                small: true,
              ),
              title: Text('Shuffle', style: _rowTitle),
              subtitle: Text(
                'Rearrange the loose tiles for free. Slotted letters stay put.',
                style: _copy,
              ),
            ),
            for (var i = 0; i < supplies.length; i++) ...[
              const Divider(height: 1),
              ListTile(
                leading: _Mark(
                  icon: supplies[i].icon,
                  color: supplies[i].color,
                  small: true,
                ),
                title: Text(supplies[i].label, style: _rowTitle),
                subtitle: Text(supplies[i].description, style: _copy),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

class _FeedbackExample extends StatelessWidget {
  const _FeedbackExample();

  @override
  Widget build(BuildContext context) {
    const letters = ['T', 'O', 'W', 'E', 'R'];
    const colors = [
      Color(0xffffcd50),
      Color(0xff52656a),
      Color(0xffffcd50),
      Color(0xff007c75),
      Color(0xff007c75),
    ];
    const marks = [
      Icons.swap_horiz,
      Icons.remove,
      Icons.swap_horiz,
      Icons.check,
      Icons.check,
    ];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Example answer: WATER', style: _rowTitle),
          const SizedBox(height: 12),
          Semantics(
            label:
                'TOWER. T and W are elsewhere. O is absent. E and R are correct.',
            child: ExcludeSemantics(
              child: Row(
                children: [
                  for (var i = 0; i < letters.length; i++)
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i == 4 ? 0 : 5),
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          color: colors[i],
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Column(
                          children: [
                            Text(
                              letters[i],
                              style: _subhead.copyWith(
                                color:
                                    marks[i] == Icons.swap_horiz
                                        ? InkColors.ink
                                        : Colors.white,
                              ),
                            ),
                            Icon(
                              marks[i],
                              size: 13,
                              color:
                                  marks[i] == Icons.swap_horiz
                                      ? InkColors.ink
                                      : Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Teal means correct position. Gold means elsewhere. Gray means no unmatched copy remains. Each letter in the answer counts once.',
            style: _copy,
          ),
        ],
      ),
    );
  }
}

class _SupportPage extends StatelessWidget {
  const _SupportPage({
    required this.title,
    required this.children,
    this.embedded = false,
  });
  final String title;
  final bool embedded;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final body = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: children,
        ),
      ),
    );
    if (embedded) return body;
    return Scaffold(
      backgroundColor: InkColors.cream,
      appBar: AppBar(
        backgroundColor: InkColors.cream,
        foregroundColor: InkColors.ink,
        title: Text(title),
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xfffffcf1),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xffcdd2c5)),
    ),
    child: child,
  );
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Mark(icon: icon, color: const Color(0xffdcebdd), small: true),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _rowTitle),
              const SizedBox(height: 3),
              Text(body, style: _copy),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Mark extends StatelessWidget {
  const _Mark({required this.icon, required this.color, this.small = false});
  final IconData icon;
  final Color color;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 38.0 : 52.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: .44), InkColors.cream),
        border: Border.all(color: InkColors.ink.withValues(alpha: .12)),
        borderRadius: BorderRadius.circular(small ? 9 : 13),
      ),
      child: Icon(icon, size: small ? 21 : 28, color: InkColors.ink),
    );
  }
}

class _CoinSeal extends StatelessWidget {
  const _CoinSeal();

  @override
  Widget build(BuildContext context) => Container(
    width: 47,
    height: 47,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: InkColors.gold,
      border: Border.all(color: const Color(0xffd1902b), width: 3),
    ),
    alignment: Alignment.center,
    child: const Icon(Icons.bolt_rounded, size: 26, color: Color(0xff654509)),
  );
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: InkColors.ink),
    title: Text(title, style: _rowTitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Color(0xff45665c),
        fontWeight: FontWeight.w800,
        letterSpacing: 1.65,
        fontSize: 12,
      ),
    ),
  );
}

const _subhead = TextStyle(
  color: Color(0xff153732),
  fontSize: 21,
  fontWeight: FontWeight.w800,
);
const _rowTitle = TextStyle(
  color: Color(0xff153732),
  fontSize: 16,
  fontWeight: FontWeight.w700,
);
const _copy = TextStyle(color: Color(0xff405b54), fontSize: 14, height: 1.4);
const _small = TextStyle(
  color: Color(0xff405b54),
  fontSize: 12,
  fontWeight: FontWeight.w600,
);

void _notice(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(message)));
}
