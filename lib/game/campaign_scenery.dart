part of 'word_rumble_game.dart';

/// In-world markings use the same cycle and berth poses as release evaluation.
extension _CampaignScenery on _DockRound {
  void _paintHazard(Canvas c) {
    final kind = game.level.hazard;
    if (kind == HazardKind.calm) return;
    const ink = Color(0xFF1B393C),
        canvasColor = Color(0xFFFFDF95),
        red = Color(0xFFE77851);
    final w = game.size.x, h = game.size.y;
    final scale = min(1.15, min(w / 320, h / 280));
    _brush.style = PaintingStyle.fill;
    if (kind == HazardKind.vent) {
      for (final s in game._slots) {
        if (!s.warning && !s.unsafe) continue;
        final y = s.y + s.height * .56, x = s.x;
        c.drawOval(
          Rect.fromCenter(
            center: Offset(x, y),
            width: s.width * .82,
            height: 9,
          ),
          _brush..color = ink,
        );
        c.drawOval(
          Rect.fromCenter(
            center: Offset(x, y),
            width: s.width * .65,
            height: 5,
          ),
          _brush..color = s.unsafe ? red : canvasColor,
        );
        for (final dir in [-1, 1]) {
          final jet =
              Path()
                ..moveTo(x + dir * s.width * .17, y + 3)
                ..relativeLineTo(dir * 6, 8 + 16 * _hazard.lift)
                ..relativeLineTo(-dir * 9, -3)
                ..close();
          c.drawPath(jet, _brush..color = s.unsafe ? red : canvasColor);
        }
      }
      return;
    }
    c.save();
    c.translate(w * .14, h * .15);
    c.scale(scale);
    if (kind == HazardKind.swell) {
      final bob = game.reducedMotion ? 0.0 : -7 * _hazard.lift;
      c.translate(0, bob);
      c.drawOval(
        Rect.fromCenter(center: const Offset(0, 9), width: 32, height: 7),
        _brush..color = ink,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-7, -11, 14, 21),
          const Radius.circular(5),
        ),
        _brush..color = red,
      );
      c.drawRect(
        const Rect.fromLTWH(-7, -5, 14, 5),
        _brush..color = canvasColor,
      );
      c.drawRect(const Rect.fromLTWH(-1.5, -24, 3, 14), _brush..color = ink);
      final pennant =
          Path()
            ..moveTo(0, -25)
            ..lineTo(15, -20)
            ..lineTo(0, -15)
            ..close();
      c.drawPath(pennant, _brush..color = canvasColor);
      if (_hazard.phase != HazardPhase.calm) {
        for (final d in [14.0, 19.0]) {
          final wave =
              Path()
                ..moveTo(-20, d)
                ..quadraticBezierTo(-10, d - 6, 0, d)
                ..quadraticBezierTo(10, d + 5, 20, d);
          c.drawPath(
            wave,
            _brush
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = canvasColor,
          );
        }
      }
    } else {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-2, -13, 4, 41),
          const Radius.circular(2),
        ),
        _brush..color = ink,
      );
      c.drawCircle(const Offset(0, -15), 3, _brush..color = canvasColor);
      c.scale(_hazard.direction.toDouble(), 1);
      final taut = _hazard.phase == HazardPhase.calm ? .32 : 1.0;
      final dx = 16 + taut * 17, drop = 13 * (1 - taut);
      final sock =
          Path()
            ..moveTo(2, -13)
            ..lineTo(dx, -7 + drop)
            ..lineTo(dx, -1 + drop)
            ..lineTo(2, 1)
            ..close();
      c.drawPath(sock, _brush..color = red);
      final stripe =
          Path()
            ..moveTo(dx * .39, -11)
            ..lineTo(dx * .6, -9 + drop * .55)
            ..lineTo(dx * .6, drop * .57)
            ..lineTo(dx * .39, .2 + drop * .35)
            ..close();
      c.drawPath(stripe, _brush..color = canvasColor);
      c.drawPath(
        sock,
        _brush
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = ink,
      );
    }
    c.restore();
  }

  void paint(Canvas canvas) {
    if (game._slots.first.width <= 0) return;
    final slots = game._slots;
    // A single rope threads the floats along their numbered reading path.
    final rope = Path();
    for (final s in slots) {
      final y = s.y + s.height * .38;
      if (s == slots.first) rope.moveTo(s.x - s.width * .49, y);
      rope.lineTo(s.x, y);
      if (s == slots.last) rope.lineTo(s.x + s.width * .49, y);
    }
    canvas.drawPath(
      rope,
      _brush
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = const Color(0xFF493D31),
    );
    canvas.drawPath(
      rope,
      _brush
        ..strokeWidth = 3
        ..color = const Color(0xFFE4B57B),
    );
    for (final s in slots) {
      final sill = Rect.fromCenter(
        center: Offset(s.x, s.y + s.height * .48),
        width: s.width * 1.03,
        height: 8,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(sill, const Radius.circular(3)),
        _brush
          ..style = PaintingStyle.fill
          ..color = const Color(0xFFBE905E),
      );
    }
    _paintHazard(canvas);
    final age = elapsed - _splashAt;
    final length = game.reducedMotion ? .16 : .42;
    if (age >= 0 && age < length) {
      final t = age / length;
      for (var i = 0; i < 2; i++) {
        final r = 10 + i * 6 + t * (game.reducedMotion ? 2 : 15);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(_splash.x, _splash.y + 7),
            width: r * 2,
            height: r * .77,
          ),
          _brush
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..color = const Color(0xFFFFEBCC).withValues(alpha: 1 - t),
        );
      }
    }
    if (held != null && game._slotOf(held!) != null) {
      final rect = _returnZone;
      final shape = RRect.fromRectAndRadius(rect, const Radius.circular(10));
      canvas.drawRRect(
        shape,
        _brush
          ..style = PaintingStyle.fill
          ..color =
              willReturnTile
                  ? const Color(0xFF216352)
                  : const Color(0xEA173E46),
      );
      canvas.drawRRect(
        shape,
        _brush
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFFFE2A0),
      );
      if (_returnLabel.text == null) {
        _returnLabel.text = const TextSpan(
          text: '↶  RETURN TILE',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFFFFF1D1),
          ),
        );
        _returnLabel.layout();
      }
      _returnLabel.paint(
        canvas,
        rect.center - Offset(_returnLabel.width / 2, _returnLabel.height / 2),
      );
    }
  }
}
