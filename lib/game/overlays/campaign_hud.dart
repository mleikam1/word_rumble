import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/level_repository.dart';
import '../../ui/style.dart';
import '../landing.dart';
import '../word_rumble_game.dart';

/// The arena's constraints depend only on the viewport. Feedback, timer digits
/// and hazard phases can change while a pointer is down.
class CampaignHud extends StatelessWidget {
  const CampaignHud({super.key, required this.game, required this.board});
  final WordRumbleGame game;
  final Widget board;

  @override
  Widget build(BuildContext context) {
    final seconds = game.remainingTime.ceil();
    final urgent = seconds <= 5;
    final clockColor = urgent ? const Color(0xff96391b) : InkColors.ink;
    final header = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${game.currentTheme.name.toUpperCase()}  /  ${LevelRepository.positionOf(game.levelIndex).toString().padLeft(2, '0')}',
                style: tagStyle(InkColors.teal),
                maxLines: 1,
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(game.level.goal, style: heading(36)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          label: urgent ? 'Final seconds' : 'Time remaining',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                game.isFrozen
                    ? 'FROZEN'
                    : urgent
                    ? 'FINAL 5'
                    : 'TIME',
                style: tagStyle(clockColor).copyWith(fontSize: 10),
              ),
              Text(
                '${seconds}s',
                key: const ValueKey('round-clock'),
                style: heading(
                  30,
                  clockColor,
                ).copyWith(fontFeatures: [const FontFeature.tabularFigures()]),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          key: const ValueKey('campaign-pause'),
          tooltip: 'Pause',
          onPressed: game.isReady ? () => game.setRoundPaused(true) : null,
          style: IconButton.styleFrom(
            backgroundColor: InkColors.ink,
            foregroundColor: InkColors.cream,
          ),
          icon: const Icon(Icons.pause_rounded),
        ),
      ],
    );
    final progress = ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        minHeight: 5,
        value: (game.remainingTime / game.totalTime).clamp(0, 1),
        semanticsLabel: 'Time remaining',
        semanticsValue: '$seconds seconds',
        backgroundColor: const Color(0xffddd8c5),
        color: urgent ? clockColor : InkColors.teal,
      ),
    );
    final tip =
        game.isHolding
            ? switch (game.landingCue) {
              LandingCue.aligned => 'Ready. Release to settle.',
              LandingCue.fast => 'Hold steady for the check.',
              LandingCue.edge => 'Move closer to the berth’s center.',
              LandingCue.occupied => 'Occupied. Aim for an empty berth.',
              LandingCue.hazard => 'Hold on. Wait for the calm window.',
              LandingCue.water =>
                game.willReturnTile
                    ? 'Release to return this tile.'
                    : 'Guide the letter to its berth.',
            }
            : game.lastResultMessage ?? game.level.tip;
    final note = Row(
      children: [
        if (game.levelIndex == 1)
          _LandingDemo(reducedMotion: game.reducedMotion)
        else
          Icon(switch (game.currentTheme.id) {
            'lava_core' => Icons.local_fire_department_outlined,
            'wind_peak' => Icons.air_rounded,
            _ => Icons.waves_rounded,
          }, color: InkColors.teal),
        const SizedBox(width: 10),
        Expanded(
          child: Semantics(
            liveRegion: game.lastResultMessage != null,
            child: Text(
              tip,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: InkColors.ink,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                height: 1.2,
              ),
            ),
          ),
        ),
      ],
    );

    final hazard = Text(
      game.hazardLabel,
      key: const ValueKey('hazard-label'),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 13,
        color: InkColors.ink,
        fontWeight: FontWeight.w800,
      ),
    );
    return ColoredBox(
      color: InkColors.cream,
      child: LayoutBuilder(
        builder: (context, bounds) {
          final landscape =
              bounds.maxHeight < 500 && bounds.maxWidth > bounds.maxHeight;
          final top = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 68, child: header),
              progress,
              SizedBox(
                height: 26,
                child: Align(alignment: Alignment.centerLeft, child: hazard),
              ),
            ],
          );
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1030),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child:
                    landscape
                        ? Row(
                          children: [
                            SizedBox(
                              width: math.min(280.0, bounds.maxWidth * .4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  top,
                                  const SizedBox(height: 12),
                                  note,
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: board),
                          ],
                        )
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            top,
                            Expanded(child: board),
                            SizedBox(height: 52, child: note),
                          ],
                        ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A single, silent example of a W slowing down over its berth and catching.
class _LandingDemo extends StatelessWidget {
  const _LandingDemo({required this.reducedMotion});
  final bool reducedMotion;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: 47,
      height: 36,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: reducedMotion ? 0 : 1700),
        builder: (context, t, _) {
          final travel = Curves.easeOut.transform((t / .76).clamp(0, 1));
          return Stack(
            children: [
              Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  width: 25,
                  height: 6,
                  decoration: BoxDecoration(
                    color: InkColors.teal,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Positioned(
                left: 20 * travel,
                top: 2 + 9 * travel,
                child: Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t >= .9 ? InkColors.gold : InkColors.paper,
                    border: Border.all(color: InkColors.ink, width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('W', style: heading(17)),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
