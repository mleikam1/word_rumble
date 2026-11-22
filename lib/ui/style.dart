import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/game_state.dart';

abstract final class InkColors {
  static const ink = Color(0xff102e38);
  static const cream = Color(0xfffff8e7);
  static const teal = Color(0xff007c75);
  static const gold = Color(0xffffcd50);
  static const coral = Color(0xffff735c);
  static const purple = Color(0xff67539b);
  static const paper = Color(0xfffffcf3);
  static const line = Color(0xffcfcbb9);
  static const muted = Color(0xff4d6061);
}

Widget display(String text, {double size = 40, Color? color}) =>
    Text(text, style: heading(size, color));
TextStyle heading(double size, [Color? color]) => TextStyle(
  fontFamily: 'Barlow Condensed',
  fontSize: size,
  height: .98,
  fontWeight: FontWeight.w800,
  color: color ?? InkColors.ink,
);
TextStyle tagStyle([Color color = InkColors.ink]) => TextStyle(
  fontSize: 11.5,
  height: 1.25,
  letterSpacing: 1.35,
  fontWeight: FontWeight.w800,
  color: color,
);
ThemeData rumbleTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: InkColors.teal).copyWith(
    primary: InkColors.teal,
    onPrimary: Colors.white,
    secondary: InkColors.gold,
    onSecondary: InkColors.ink,
    surface: InkColors.cream,
    onSurface: InkColors.ink,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'DM Sans',
    scaffoldBackgroundColor: InkColors.cream,
    appBarTheme: const AppBarTheme(
      backgroundColor: InkColors.cream,
      foregroundColor: InkColors.ink,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    dividerColor: InkColors.line,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 50),
        textStyle: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: InkColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        side: const BorderSide(color: InkColors.line),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: InkColors.ink,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class Wallet extends StatelessWidget {
  const Wallet({super.key, this.onPressed});
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) {
    final amount = context.select<GameState, int>((s) => s.coins);
    final face = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.toll_rounded, size: 20, color: Color(0xff9b6100)),
        const SizedBox(width: 5),
        Text(
          '$amount',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: InkColors.ink,
          ),
        ),
      ],
    );
    return Semantics(
      label: '$amount coins',
      button: onPressed != null,
      child: Material(
        color: const Color(0xffffe9aa),
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: face,
          ),
        ),
      ),
    );
  }
}

class WordMark extends StatelessWidget {
  const WordMark({super.key});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Transform.rotate(
        angle: -.11,
        child: Container(
          width: 35,
          height: 35,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: InkColors.gold,
            border: Border.all(color: InkColors.ink, width: 1.8),
            borderRadius: BorderRadius.circular(7),
            boxShadow: const [
              BoxShadow(color: InkColors.ink, offset: Offset(1.5, 2)),
            ],
          ),
          child: Text('W', style: heading(29)),
        ),
      ),
      const SizedBox(width: 10),
      Text('WORD RUMBLE', style: heading(26)),
    ],
  );
}

class PosterCard extends StatelessWidget {
  const PosterCard({
    super.key,
    required this.child,
    this.color = InkColors.paper,
    this.onTap,
    this.radius = 18,
  });
  final Widget child;
  final Color color;
  final VoidCallback? onTap;
  final double radius;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const [
        BoxShadow(color: Color(0xff263f42), offset: Offset(0, 3)),
      ],
    ),
    child: Material(
      clipBehavior: Clip.antiAlias,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: const BorderSide(color: InkColors.ink, width: 1.5),
      ),
      child: onTap == null ? child : InkWell(onTap: onTap, child: child),
    ),
  );
}

class Couplet extends StatelessWidget {
  const Couplet({
    super.key,
    required this.text,
    required this.bg,
    this.small = false,
  });
  final String text;
  final Color bg;
  final bool small;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: small ? 7 : 10,
      vertical: small ? 3 : 5,
    ),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(text, style: tagStyle().copyWith(fontSize: small ? 10 : 11)),
  );
}

class TileArt extends StatelessWidget {
  const TileArt({super.key, this.size = 90});
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: size,
      height: size * .92,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final tile in [
            (
              x: .06,
              y: .08,
              a: -.22,
              letter: '?',
              color: const Color(0xffb4a4d8),
            ),
            (x: .44, y: .26, a: .18, letter: 'R', color: InkColors.cream),
            (x: .18, y: .47, a: -.10, letter: '?', color: InkColors.gold),
          ])
            Positioned(
              left: size * tile.x,
              top: size * tile.y,
              child: Transform.rotate(
                angle: tile.a,
                child: Container(
                  width: size * .43,
                  height: size * .43,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tile.color,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: InkColors.ink, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: InkColors.ink, offset: Offset(1, 3)),
                    ],
                  ),
                  child: Text(tile.letter, style: heading(size * .35)),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class DailyArt extends StatelessWidget {
  const DailyArt({super.key, this.size = 68});
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: Size.square(size), painter: _StampPainter()),
  );
}

class _StampPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final p = Path();
    for (var i = 0; i < 40; i++) {
      final a = i * math.pi / 20;
      final r = s.width * (i.isEven ? 0.46 : 0.39);
      final x = c.dx + math.cos(a) * r, y = c.dy + math.sin(a) * r;
      if (i == 0) {
        p.moveTo(x, y);
      } else {
        p.lineTo(x, y);
      }
    }
    p.close();
    canvas.drawPath(p, Paint()..color = InkColors.gold);
    canvas.drawPath(
      p,
      Paint()
        ..color = InkColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    canvas.drawCircle(
      c,
      s.width * .28,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = InkColors.ink,
    );
    final clock =
        Paint()
          ..color = InkColors.ink
          ..strokeWidth = 2.7
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(c, c + Offset(0, -s.width * .15), clock);
    canvas.drawLine(c, c + Offset(s.width * .12, s.width * .06), clock);
  }

  @override
  bool shouldRepaint(_StampPainter oldDelegate) => false;
}
