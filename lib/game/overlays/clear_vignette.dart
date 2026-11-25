import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../ui/style.dart';

/// Plays once on the secured result card, leaving all result actions available.
class ClearVignette extends StatelessWidget {
  const ClearVignette({
    super.key,
    required this.word,
    required this.world,
    required this.still,
  });
  final String word, world;
  final bool still;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ClipRect(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: still ? 0 : 1050),
        builder:
            (_, t, _) => CustomPaint(
              painter: _WorldClear(word, world, t),
              size: const Size(104, 66),
            ),
      ),
    ),
  );
}

class _WorldClear extends CustomPainter {
  const _WorldClear(this.word, this.world, this.t);
  final String word, world;
  final double t;

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 104, size.height / 66);
    final fill = Paint()..color = InkColors.ink;
    final line =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = InkColors.teal;
    if (world == 'water_bay') {
      final x = word == 'SHIP' ? 29 + 38 * t : 52.0;
      final y = 43 + math.sin(t * math.pi * 2) * 2;
      for (var i = 0; i < 3; i++) {
        final radius = 11 + 13.0 * i + t * 7;
        c.drawOval(
          Rect.fromCenter(
            center: Offset(x, y + 3),
            width: radius * 2,
            height: radius * .38,
          ),
          line,
        );
      }
      c.save();
      c.translate(x, y);
      if (word == 'SHIP') {
        c.drawPath(
          Path()
            ..moveTo(-23, -5)
            ..lineTo(23, -5)
            ..lineTo(14, 3)
            ..lineTo(-13, 3)
            ..close(),
          fill,
        );
        c.drawLine(
          const Offset(-3, -7),
          const Offset(-3, -38),
          line..color = InkColors.ink,
        );
        c.drawPath(
          Path()
            ..moveTo(0, -37)
            ..lineTo(17, -9)
            ..lineTo(0, -9)
            ..close(),
          fill..color = InkColors.gold,
        );
      } else if (word == 'BUOY') {
        c.rotate(-.65 * (1 - t) + math.sin(t * math.pi * 3) * (1 - t) * .19);
        c.drawPath(
          Path()
            ..moveTo(-6, -26)
            ..lineTo(6, -26)
            ..lineTo(13, -1)
            ..quadraticBezierTo(0, 7, -13, -1)
            ..close(),
          fill..color = const Color(0xffba482c),
        );
        c.drawLine(
          const Offset(-8, -12),
          const Offset(8, -12),
          line
            ..color = InkColors.cream
            ..strokeWidth = 5,
        );
        c.drawCircle(const Offset(0, -29), 4, fill..color = InkColors.ink);
      } else {
        c.drawCircle(
          Offset(0, -7 - 15 * math.sin(t * math.pi)),
          4,
          fill..color = InkColors.teal,
        );
        c.drawLine(const Offset(-8, -10), const Offset(-14, -17), line);
        c.drawLine(const Offset(8, -10), const Offset(14, -17), line);
      }
      c.restore();
    } else if (world == 'lava_core') {
      c.drawPath(
        Path()
          ..moveTo(8, 56)
          ..lineTo(37, 32)
          ..lineTo(59, 32)
          ..lineTo(95, 56)
          ..close(),
        fill,
      );
      line
        ..color = const Color(0xffaf4627)
        ..strokeWidth = 4;
      c.drawLine(const Offset(40, 32), const Offset(56, 32), line);
      for (var i = 0; i < 5; i++) {
        final u = math.sin(t * math.pi);
        c.drawCircle(
          Offset(
            34 + i * 7.0 + (i - 2) * u * 4,
            24 - (i.isOdd ? 11 : 4) - u * (12 + i),
          ),
          i.isEven ? 2 : 3,
          fill..color = const Color(0xffb04a20),
        );
      }
    } else {
      c.drawLine(
        const Offset(32, 58),
        const Offset(32, 12),
        line..color = InkColors.ink,
      );
      c.drawPath(
        Path()
          ..moveTo(32, 12)
          ..quadraticBezierTo(44, 7 - 4 * math.sin(t * math.pi), 52, 13)
          ..lineTo(80, 18)
          ..lineTo(53, 26)
          ..quadraticBezierTo(40, 19, 32, 25)
          ..close(),
        fill..color = InkColors.teal,
      );
      for (var i = 0; i < 3; i++) {
        final x = 40.0 + i * 6 + t * 7, y = 35.0 + i * 6;
        c.drawLine(
          Offset(x, y),
          Offset(x + 24 - i * 3, y - 2),
          line..color = InkColors.teal,
        );
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_WorldClear old) =>
      old.t != t || old.word != word || old.world != world;
}
