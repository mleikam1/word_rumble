import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum SlotFeedback {
  none,
  correct,   // correct letter & position
  present,   // letter in word but wrong position
  absent,    // not in word
}

class SlotComponent extends PositionComponent {
  final int index; // position in the word
  final Color baseColor;

  String? currentLetter;
  SlotFeedback feedback = SlotFeedback.none;

  SlotComponent({
    required this.index,
    required Vector2 position,
    required Vector2 size,
    required this.baseColor,
  }) : super(position: position, size: size, anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    Color borderColor = baseColor;
    Color fillColor = Colors.transparent;

    switch (feedback) {
      case SlotFeedback.none:
        break;
      case SlotFeedback.correct:
        fillColor = Colors.greenAccent.withOpacity(0.5);
        borderColor = Colors.green;
        break;
      case SlotFeedback.present:
        fillColor = Colors.amberAccent.withOpacity(0.5);
        borderColor = Colors.orange;
        break;
      case SlotFeedback.absent:
        fillColor = Colors.grey.withOpacity(0.4);
        borderColor = Colors.grey.shade700;
        break;
    }

    if (fillColor != Colors.transparent) {
      final fillPaint = Paint()..color = fillColor;
      canvas.drawRRect(rrect, fillPaint);
    }

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rrect, borderPaint);

    if (currentLetter != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: currentLetter,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: size.x);
      final offset = Offset(
        (size.x - textPainter.width) / 2,
        (size.y - textPainter.height) / 2,
      );
      textPainter.paint(canvas, offset);
    }
  }

  void clearLetterAndFeedback() {
    currentLetter = null;
    feedback = SlotFeedback.none;
  }
}
