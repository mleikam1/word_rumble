import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'letter_component.dart';

enum SlotFeedback { none, correct, present, absent }

class SlotComponent extends PositionComponent {
  final int index;
  final Color baseColor;

  // The tile is the occupant. The slot never stores a second copy of its letter.
  LetterComponent? tile;
  String? get currentLetter => tile?.letter;

  SlotComponent({required this.index, required this.baseColor})
    : super(anchor: Anchor.center);

  @override
  void render(Canvas canvas) {
    final border = RRect.fromRectAndRadius(
      size.toRect().deflate(1.5),
      const Radius.circular(8),
    );
    canvas.drawRRect(border, Paint()..color = const Color(0x30FFFFFF));
    canvas.drawRRect(
      border,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = baseColor,
    );
  }
}
