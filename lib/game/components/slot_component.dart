import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../landing.dart';
import 'letter_component.dart';

enum SlotFeedback { none, correct, present, absent }

class SlotComponent extends PositionComponent {
  final int index;
  final Color baseColor;
  final String? objective;
  final Vector2 rest = Vector2.zero();
  final Vector2 velocity = Vector2.zero();
  LandingCue cue = LandingCue.water;
  bool settling = false;
  bool warning = false, unsafe = false;
  LetterComponent? tile;
  String? get currentLetter => tile?.letter;
  final _label = TextPainter(textDirection: TextDirection.ltr);
  final _number = TextPainter(textDirection: TextDirection.ltr);
  double _labelSize = 0;
  static final _socket = Paint()..color = const Color(0xDE153A40);
  static final _rim = Paint()..style = PaintingStyle.stroke;
  static final _badge = Paint()..color = const Color(0xFF183A40);
  static final _mark =
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 2.8;

  SlotComponent({required this.index, required this.baseColor, this.objective})
    : super(anchor: Anchor.center);

  void _layoutLabels() {
    if (_labelSize == width) return;
    _labelSize = width;
    _label.text = TextSpan(
      text: objective,
      style: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: width * .39,
        fontWeight: FontWeight.w800,
        color: const Color(0xCCDCEDDF),
      ),
    );
    _label.layout();
    _number.text = TextSpan(
      text: '${index + 1}',
      style: TextStyle(
        fontFamily: 'DM Sans',
        fontWeight: FontWeight.w800,
        color: const Color(0xFFFFEDCA),
        fontSize: (width * .24).clamp(10, 15).toDouble(),
      ),
    );
    _number.layout();
  }

  @override
  void render(Canvas canvas) {
    final border = RRect.fromRectAndRadius(
      size.toRect().deflate(1.5),
      const Radius.circular(8),
    );
    canvas.drawRRect(border, _socket);
    final active = cue != LandingCue.water;
    final color = switch (cue) {
      LandingCue.aligned => const Color(0xFFADFFE2),
      LandingCue.water =>
        warning || unsafe ? const Color(0xFFFFBD87) : const Color(0xFFFFE2A0),
      _ => const Color(0xFFFFBD87),
    };
    canvas.drawRRect(
      border,
      _rim
        ..color = color
        ..strokeWidth = active ? 4 : 2,
    );
    if (objective == null) return;
    _layoutLabels();
    _label.paint(
      canvas,
      Offset((width - _label.width) / 2, (height - _label.height) / 2),
    );
    // The numbered tab and release cue sit above the tile and the thumb.
    final center = Offset(width / 2, active ? -20 : -9);
    final badge = Rect.fromCenter(
      center: center,
      width: active ? 41 : 22,
      height: 20,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(badge, const Radius.circular(8)),
      _badge,
    );
    _number.paint(
      canvas,
      center - Offset(_number.width / 2 + (active ? 8 : 0), _number.height / 2),
    );
    if (!active && (warning || unsafe)) {
      final y = height * .78;
      final x = width * .78;
      canvas.drawLine(Offset(x, y), Offset(x + 4, y - 7), _mark..color = color);
      canvas.drawLine(Offset(x + 5, y), Offset(x + 9, y - 7), _mark);
    }
    if (!active) return;
    final x = center.dx + 8, y = center.dy;
    _mark.color = color;
    if (cue == LandingCue.aligned) {
      canvas.drawPath(
        Path()
          ..moveTo(x - 5, y)
          ..lineTo(x - 1, y + 4)
          ..lineTo(x + 6, y - 4),
        _mark,
      );
    } else if (cue == LandingCue.fast) {
      canvas.drawLine(Offset(x - 3, y - 4), Offset(x - 3, y + 4), _mark);
      canvas.drawLine(Offset(x + 3, y - 4), Offset(x + 3, y + 4), _mark);
    } else {
      canvas.drawLine(Offset(x - 4, y - 4), Offset(x + 4, y + 4), _mark);
      canvas.drawLine(Offset(x + 4, y - 4), Offset(x - 4, y + 4), _mark);
    }
  }

  @override
  void onRemove() {
    _label.dispose();
    _number.dispose();
    super.onRemove();
  }
}
