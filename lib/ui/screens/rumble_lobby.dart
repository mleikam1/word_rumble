import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/game_mode.dart';
import '../../core/game_state.dart';
import '../../data/guess_words.dart';
import '../game_page.dart';
import '../style.dart';
import 'support_screens.dart';

String puzzleDay(DateTime now) =>
    now.toUtc().toIso8601String().substring(0, 10);
String dailyAnswer(String day) {
  final tick =
      DateTime.parse('${day}T00:00:00Z').millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
  return GuessWords.targets[(tick * 7) % GuessWords.targets.length];
}

String dateLabel(DateTime date) {
  const names = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  return '${names[date.month - 1]} ${date.day.toString().padLeft(2, '0')}';
}

class RumbleLobby extends StatefulWidget {
  const RumbleLobby({super.key, this.daily = false});
  final bool daily;
  @override
  State<RumbleLobby> createState() => _RumbleLobbyState();
}

class _RumbleLobbyState extends State<RumbleLobby> with WidgetsBindingObserver {
  Timer? _midnight;
  DateTime _day = DateTime.now().toUtc();
  void _refreshDay() {
    final now = DateTime.now().toUtc();
    if (!mounted) return;
    setState(() => _day = now);
    _midnight?.cancel();
    _midnight = Timer(
      DateTime.utc(now.year, now.month, now.day + 1).difference(now) +
          const Duration(milliseconds: 50),
      _refreshDay,
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.daily) {
      WidgetsBinding.instance.addObserver(this);
      _refreshDay();
    }
  }

  @override
  void dispose() {
    _midnight?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed && widget.daily) _refreshDay();
  }

  String _recap(GameState profile) {
    final answer = dailyAnswer(puzzleDay(_day));
    final attempt =
        profile.dailyStatus == 'interrupted'
            ? 'The app closed during your attempt.'
            : 'You submitted ${profile.dailyGuesses} of 6 guesses.';
    return 'The word was $answer. $attempt The next puzzle opens at midnight UTC.';
  }

  void _start() {
    final model = context.read<GameState>();
    final day = puzzleDay(DateTime.now());
    if (widget.daily && !model.beginDaily(day)) return;
    model.feedback();
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder:
            (_) => GamePage(
              mode: GameMode.wordRumble,
              initialLevelIndex: 1,
              dailyWord: widget.daily ? dailyAnswer(day) : null,
              onDailyFinished:
                  widget.daily
                      ? (won, guesses) => model.finishDaily(day, won, guesses)
                      : null,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<GameState>();
    final daily = widget.daily;
    final used = daily && profile.dailyKey == puzzleDay(_day);
    final playing = used && profile.dailyStatus == 'playing';
    final closed = used && !playing;
    final title = daily ? 'Daily Rumble' : 'Word Guess';
    final accent = daily ? InkColors.gold : const Color(0xffd3c2ef);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Wallet(onPressed: () => Navigator.pushNamed(context, '/shop')),
          const SizedBox(width: 14),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              children: [
                PosterCard(
                  color:
                      daily ? const Color(0xffffda83) : const Color(0xffd2c4e9),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 19, 18, 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                daily
                                    ? 'DAILY PUZZLE   /   ${dateLabel(_day)}'
                                    : 'LEGACY PRACTICE',
                                style: tagStyle(),
                              ),
                              const SizedBox(height: 12),
                              display(
                                daily ? 'DAILY\nRUMBLE' : 'WORD\nGUESS',
                                size: 58,
                              ),
                            ],
                          ),
                        ),
                        daily
                            ? const DailyArt(size: 92)
                            : const TileArt(size: 98),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                display(
                  closed
                      ? (profile.dailyStatus == 'won'
                          ? 'DAILY SOLVED'
                          : 'ATTEMPT COMPLETE')
                      : 'FIND THE HIDDEN WORD',
                  size: 31,
                ),
                const SizedBox(height: 9),
                Text(
                  closed
                      ? _recap(profile)
                      : daily
                      ? 'Everyone gets the same five-letter puzzle today. Starting uses your one daily attempt.'
                      : 'Build a five-letter word from the moving rack. Submit a guess to see which letters belong and where they fit.',
                  style: const TextStyle(height: 1.4, fontSize: 16),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Couplet(text: '5 LETTERS', bg: accent),
                    Couplet(text: '6 GUESSES', bg: accent),
                    Couplet(text: '30 SECONDS', bg: accent),
                  ],
                ),
                const SizedBox(height: 22),
                const _ClueRow(),
                const SizedBox(height: 22),
                if (closed)
                  FilledButton.icon(
                    onPressed:
                        () =>
                            Navigator.pushReplacementNamed(context, '/rumble'),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Play a practice round'),
                  )
                else
                  FilledButton.icon(
                    onPressed: playing ? null : _start,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      playing
                          ? 'Attempt in progress'
                          : daily
                          ? 'Start daily attempt'
                          : 'Start Word Guess',
                    ),
                  ),
                TextButton(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const GuidePage(guess: true),
                        ),
                      ),
                  child: const Text('How to read clues'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClueRow extends StatelessWidget {
  const _ClueRow();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final entry in [
        (
          Icons.check_rounded,
          'Exact',
          'Right letter and slot',
          Color(0xffc0e4c6),
        ),
        (
          Icons.swap_horiz_rounded,
          'Present',
          'Right letter, different slot',
          Color(0xffffdf83),
        ),
        (
          Icons.remove_rounded,
          'Absent',
          'No remaining match',
          Color(0xffdcdedb),
        ),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: entry.$4,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(entry.$1, size: 18),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 65,
                child: Text(
                  entry.$2,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Expanded(
                child: Text(
                  entry.$3,
                  style: const TextStyle(fontSize: 13, color: InkColors.muted),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
