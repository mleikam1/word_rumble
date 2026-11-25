// Read-only geometry bridge for Chrome touch QA. Start through the production
// entry point so route transitions, profile loads and results run normally.
import 'dart:convert';
import 'dart:js_interop';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:word_rumble/game/word_rumble_game.dart';
import 'package:word_rumble/main.dart' as app;

@JS('readBoard')
external set _readBoard(JSFunction callback);

Future<void> main() async {
  await app.main();
  _readBoard = (() => jsonEncode(_snapshot()).toJS).toJS;
}

Map<String, Object?> _snapshot() {
  final data = <String, Object?>{};
  void visit(Element e) {
    final widget = e.widget;
    if (widget is Offstage && widget.offstage) return;
    if (widget is GameWidget<WordRumbleGame> ||
        widget.key is ValueKey<String>) {
      final box = e.findRenderObject();
      if (box is RenderBox && box.attached && box.hasSize) {
        final origin = box.localToGlobal(Offset.zero);
        if (widget.key case ValueKey<String>(:final value)) {
          data[value] = [origin.dx, origin.dy, box.size.width, box.size.height];
        }
        if (widget is GameWidget<WordRumbleGame> && widget.game!.isReady) {
          final g = widget.game!;
          data.addAll({
            'word': g.targetWord,
            'time': g.remainingTime,
            'won': g.isWon,
            'paused': g.isRoundPaused,
            'ready': g.campaignInputReady,
            'misses': g.landingMisses,
            'cue': g.landingCue.name,
            'hazard': g.hazardLabel,
            'status': g.lastResultMessage,
            'slots': [
              for (final s in g.slots)
                {
                  'x': origin.dx + s.x,
                  'y': origin.dy + s.y,
                  'letter': s.currentLetter,
                  'width': s.width,
                },
            ],
            'tiles': [
              for (final t in g.tiles)
                {
                  'x': origin.dx + t.x,
                  'y': origin.dy + t.y,
                  'letter': t.letter,
                  'id': t.id,
                  'width': t.width,
                  'latched': g.slots.any((s) => s.tile == t),
                },
            ],
          });
        }
      }
    }
    e.visitChildElements(visit);
  }

  final root = WidgetsBinding.instance.rootElement;
  if (root != null) visit(root);
  return data;
}
