part of 'word_rumble_game.dart';

class _Settlement {
  final LetterComponent tile;
  final SlotComponent berth;
  final Vector2 relativeStart;
  final double began, due;
  _Settlement(this.tile, this.berth, this.began, this.due)
    : relativeStart = (tile.position - berth.position) / berth.width;
}

typedef _Preview = ({SlotComponent? berth, LandingCue cue});

/// Owns campaign movement and reservations. slot.tile changes only at latch
/// or when the player explicitly releases an existing tile in RETURN TILE.
class _DockRound {
  _DockRound(this.game);
  final WordRumbleGame game;
  final _pending = <_Settlement>[];
  int? pointer;
  LetterComponent? held;
  int misses = 0, cleanLandings = 0;
  double elapsed = 0;
  double _lastStamp = 0, _lastArrival = 0;
  bool _inside = true;
  ReleaseMotion _motion = ReleaseMotion();
  final _offset = Vector2.zero(), _beforeDrag = Vector2.zero();
  final _splash = Vector2.zero();
  double _splashAt = -10;
  final _brush = Paint();
  final _returnLabel = TextPainter(textDirection: TextDirection.ltr);
  _Preview preview = (berth: null, cue: LandingCue.water);
  bool get busy => held != null || _pending.isNotEmpty;
  HazardCycle _hazard = HazardCycle.quiet;
  String get hazardLabel => _hazard.label(game.level.hazard);
  double get _windTravel => min(18.0, game.size.x * .045);
  Vector2 get returnCenter => Vector2(game.size.x / 2, game.size.y * .92);
  Rect get _returnZone {
    final c = returnCenter;
    return Rect.fromCenter(center: Offset(c.x, c.y), width: 128, height: 36);
  }

  bool get willReturnTile {
    final tile = held;
    return _inside &&
        tile != null &&
        game._slotOf(tile) != null &&
        _returnZone.contains(Offset(tile.x, tile.y));
  }

  void reset() {
    _pending.clear();
    pointer = null;
    held = null;
    misses = cleanLandings = 0;
    elapsed = 0;
    _splashAt = -10;
    preview = (berth: null, cue: LandingCue.water);
  }

  void dispose() => _returnLabel.dispose();

  void layout() {
    final w = game.size.x, h = game.size.y;
    final count = game._slots.length;
    final margin = game.level.layout == BerthLayout.ridge ? _windTravel : 0.0;
    final pitch = min(80.0, (w - 14 - 2 * margin) / count);
    final side = min(pitch * .90, h * .15);
    for (final s in game._slots) {
      s.size.setAll(side);
      s.rest.setValues(
        w / 2 + (s.index - (count - 1) / 2) * pitch,
        h * .76 +
            switch (game.level.layout) {
              BerthLayout.dock => sin(s.index * .95) * min(6.0, h * .012),
              BerthLayout.ledges =>
                (s.index.isEven ? 1 : -1) * min(7.0, h * .014),
              BerthLayout.ridge =>
                (0.5 - s.index / max(1, count - 1)) * min(28.0, h * .055),
            },
      );
    }
    _berthsAt(elapsed);
    final tileSide = min(61.0, side * .85);
    final spread = min(w - 10 - 2 * margin, 590.0);
    final capacity = max(1, (spread / (tileSide + 13)).floor());
    final rows = max(
      game._rackCapacity >= 6 ? 2 : 1,
      (game._rackCapacity / capacity).ceil(),
    );
    final columns = (game._rackCapacity / rows).ceil();
    // Keep adjacent rows exposed through the full lift of an alternating vent.
    final ventRoom =
        game.level.hazard == HazardKind.vent ? min(30.0, h * .05) : 0.0;
    final spacing = tileSide + min(21.0, h * .04) + ventRoom;
    final bottomRow = h * .545;
    for (final t in game._tiles) {
      final row = t.homeIndex ~/ columns;
      final col = t.homeIndex % columns;
      final inRow = min(columns, game._rackCapacity - row * columns);
      t.setSide(tileSide);
      t.home.setValues(
        w / 2 + ((col + .5) / inRow - .5) * spread,
        bottomRow -
            (rows - 1 - row) * spacing +
            sin(col * 1.8) * min(3.0, h * .006),
      );
      final owner = game._slotOf(t);
      if (owner == null) {
        t.returnHome();
      } else {
        t.position.setFrom(owner.position);
      }
    }
    for (final settlement in _pending) {
      _placeSettling(settlement);
    }
  }

  void _berthsAt(double time) {
    final kind = game.level.hazard;
    _hazard = HazardCycle.at(game.level, time);
    for (final s in game._slots) {
      final affects = _hazard.affects(kind, s.index);
      s.warning = affects && _hazard.phase == HazardPhase.warning;
      s.unsafe = affects && _hazard.phase == HazardPhase.burst;
      final a = time * 1.15 + s.index * .47;
      final rock = sin(a) * 3.4, rate = cos(a) * 3.4 * 1.15;
      double dx = 0, dy = 0, vx = 0, vy = 0;
      switch (kind) {
        case HazardKind.calm:
        case HazardKind.swell:
          final rise = min(23.0, game.size.y * .041);
          dy = rock - rise * _hazard.lift;
          vy = rate - rise * _hazard.speed;
        case HazardKind.vent:
          if (affects) {
            final rise = min(15.0, game.size.y * .028);
            dy = -rise * _hazard.lift;
            vy = -rise * _hazard.speed;
          }
        case HazardKind.gust:
        case HazardKind.storm:
          final travel = _windTravel;
          dx =
              travel *
              (.21 * sin(time * .8) + .79 * _hazard.direction * _hazard.lift);
          vx =
              travel *
              (.168 * cos(time * .8) + .79 * _hazard.direction * _hazard.speed);
      }
      s.position.setValues(s.rest.x + dx, s.rest.y + dy);
      s.velocity.setValues(vx, vy);
    }
  }

  double _timestamp(Duration stamp) =>
      stamp == Duration.zero ? elapsed : stamp.inMicroseconds / 1e6;

  void down(int id, Vector2 point, Duration stamp) {
    if (pointer != null) return;
    for (final tile in game._tiles.reversed) {
      if (_pending.any((p) => p.tile == tile)) continue;
      final delta = tile.position - point;
      if (delta.x.abs() > tile.width / 2 + 2 ||
          delta.y.abs() > tile.height / 2 + 2) {
        continue;
      }
      pointer = id;
      held = tile;
      _beforeDrag.setFrom(tile.position);
      _offset.setFrom(delta);
      // Lift the face slightly above the thumb, retaining off-center grabs.
      _offset.y -= tile.height * .12;
      _motion = ReleaseMotion();
      _lastStamp = _timestamp(stamp);
      tile.priority = 5;
      tile.velocity.setZero();
      move(id, point, stamp);
      game._notifyHud();
      return;
    }
  }

  void move(int id, Vector2 point, Duration stamp) {
    final tile = held;
    if (id != pointer || tile == null) return;
    if (stamp != Duration.zero && _timestamp(stamp) < _lastStamp) return;
    final wasReturning = willReturnTile;
    tile.position.setFrom(point + _offset);
    _bound(tile);
    _lastStamp = _timestamp(stamp);
    _lastArrival = elapsed;
    _inside =
        point.x >= 0 &&
        point.x <= game.size.x &&
        point.y >= 0 &&
        point.y <= game.size.y;
    _motion.sample(_lastStamp, tile.position);
    _showPreview(_assess(tile, _motion.at(_lastStamp)));
    if (wasReturning != willReturnTile) game._notifyHud();
  }

  void _bound(LetterComponent tile) {
    final half = tile.width / 2;
    tile.position.setValues(
      tile.x.clamp(half, max(half, game.size.x - half)),
      tile.y.clamp(half, max(half, game.size.y - half)),
    );
  }

  _Preview _assess(LetterComponent tile, Vector2 velocity) {
    if (!_inside) return (berth: null, cue: LandingCue.water);
    SlotComponent? closest;
    var best = double.infinity;
    for (final berth in game._slots) {
      final d = berth.position.distanceToSquared(tile.position);
      if (d < best) {
        best = d;
        closest = berth;
      }
    }
    final s = closest!;
    final cue = evaluateLanding(
      offset: tile.position - s.position,
      relativeVelocity: velocity - s.velocity,
      radius: s.width * game.level.landingRadius,
      maxSpeed: game.level.maxLandingSpeed,
      occupied: (s.tile != null && s.tile != tile) || s.settling,
      hazard: s.unsafe,
    );
    return (berth: cue == LandingCue.water ? null : s, cue: cue);
  }

  void _showPreview(_Preview next) {
    if (preview == next) return;
    preview.berth?.cue = LandingCue.water;
    preview = next;
    next.berth?.cue = next.cue;
    game._notifyHud();
  }

  void _endHold() {
    held?.priority = 2;
    held = null;
    pointer = null;
    _showPreview((berth: null, cue: LandingCue.water));
  }

  void cancel() {
    final tile = held;
    if (tile == null) return;
    tile.position.setFrom(game._slotOf(tile)?.position ?? _beforeDrag);
    tile.velocity.setZero();
    _endHold();
    _reviewRow();
    game._notifyHud();
  }

  void up(int id, Vector2 point, Duration stamp) {
    final tile = held;
    if (id != pointer || tile == null) return;
    if (stamp != Duration.zero && _timestamp(stamp) < _lastStamp) return;
    move(id, point, stamp);
    final result = preview;
    final velocity = _motion.at(_lastStamp);
    final origin = game._slotOf(tile);
    final inside = _inside;
    final returning = willReturnTile;
    _endHold();
    if (returning) {
      origin!.tile = null;
      tile.returnHome();
      game.lastResultMessage = 'Tile returned. Move another letter into place.';
    } else if (inside && result.cue == LandingCue.aligned) {
      final berth = result.berth!;
      berth.settling = true;
      tile.priority = 3;
      _pending.add(
        _Settlement(tile, berth, elapsed, elapsed + game.level.settleSeconds),
      );
      game.lastResultMessage = 'Settling…';
    } else {
      misses++;
      _splash.setFrom(tile.position);
      _splashAt = elapsed;
      if (origin != null) {
        tile.position.setFrom(origin.position);
        tile.velocity.setZero();
      } else {
        tile.velocity.setFrom(velocity * .28);
        tile.velocity.y -= 32;
        if (game.currentTheme.physicsStyle == PhysicsStyle.water && inside) {
          _nudge(tile);
        }
      }
      game.lastResultMessage = switch (result.cue) {
        LandingCue.fast => 'Too fast. Hold steady for the check.',
        LandingCue.edge => 'Clipped the edge. Aim closer to the center.',
        LandingCue.occupied => 'Berth occupied. Return a tile to make room.',
        LandingCue.hazard => 'Wait for the calm window.',
        _ =>
          origin == null
              ? 'Missed. Catch the letter and try again.'
              : 'Back in place. Use RETURN TILE to clear it.',
      };
    }
    _reviewRow();
    game._notifyHud();
  }

  void _nudge(LetterComponent source) {
    LetterComponent? nearby;
    var best = source.width * source.width * 3.5;
    for (final t in game._tiles) {
      if (t == source ||
          game._slotOf(t) != null ||
          _pending.any((p) => p.tile == t)) {
        continue;
      }
      final d = source.position.distanceToSquared(t.position);
      if (d < best) {
        best = d;
        nearby = t;
      }
    }
    if (nearby == null) return;
    final direction = nearby.position - source.position;
    if (direction.length2 < .001) {
      direction.setValues(nearby.home.x < source.home.x ? -1 : 1, 0);
    }
    direction.normalize();
    nearby.velocity.addScaled(direction, 92);
    nearby.velocity.clampLength(0, 190);
    source.velocity.addScaled(direction, -46);
  }

  void abortSettlements() {
    for (final p in _pending) {
      p.berth.settling = false;
      p.tile.priority = 2;
      p.tile.position.setFrom(game._slotOf(p.tile)?.position ?? p.tile.home);
      p.tile.velocity.setZero();
    }
    _pending.clear();
  }

  void _freeMotion(LetterComponent tile, double dt) {
    final phase = elapsed * 1.5 + tile.phase;
    var targetX = tile.home.x + sin(phase * .72) * 3;
    var targetY = tile.home.y + sin(phase) * 4;
    final kind = game.level.hazard;
    switch (kind) {
      case HazardKind.swell:
        targetY -= _hazard.lift * min(17, game.size.y * .032);
      case HazardKind.vent:
        // A heating set of vents lifts its column of loose letters together.
        if (_hazard.affects(kind, tile.homeIndex)) {
          targetY -= _hazard.lift * min(30, game.size.y * .05);
        }
      case HazardKind.gust:
      case HazardKind.storm:
        targetX +=
            _hazard.direction * _hazard.lift * min(24.0, game.size.x * .055);
      case HazardKind.calm:
        break;
    }
    tile.velocity.x += ((targetX - tile.x) * 38 - tile.velocity.x * 10) * dt;
    tile.velocity.y += ((targetY - tile.y) * 38 - tile.velocity.y * 10) * dt;
    tile.velocity.clampLength(0, 520);
    tile.position.addScaled(tile.velocity, dt);
    _bound(tile);
  }

  void _placeSettling(_Settlement p) {
    final progress = ((elapsed - p.began) / (p.due - p.began)).clamp(0.0, 1.0);
    // Pose is relative to the moving berth, including across a genuine resize.
    final scale = (1 - progress) * (1 - progress) * p.berth.width;
    p.tile.position.setValues(
      p.berth.x + p.relativeStart.x * scale,
      p.berth.y +
          p.relativeStart.y * scale +
          sin(progress * pi) * (game.reducedMotion ? 1 : 4),
    );
  }

  void advance(double dt) {
    const epsilon = 1e-9;
    var available = dt;
    // Split at deadlines as well as at the integration limit. Strict ties go
    // to the clock, even if one display frame spans both release and timeout.
    while (available > epsilon && game._playing) {
      final untilTimeout = game.remainingTime + game._freeze;
      var step = min(1 / 90, min(available, untilTimeout));
      if (_pending.isNotEmpty) {
        step = min(step, max(0, _pending.first.due - elapsed));
      }
      final frozen = min(game._freeze, step);
      game._freeze -= frozen;
      game.remainingTime = max(0, game.remainingTime - step + frozen);
      elapsed += step;
      available -= step;
      _berthsAt(elapsed);
      if (game.remainingTime <= epsilon) {
        game.remainingTime = 0;
        game._finish(won: false);
        return;
      }
      for (final tile in game._tiles) {
        if (tile == held) continue;
        final s = game._slotOf(tile);
        if (_pending.any((p) => p.tile == tile)) continue;
        if (s != null) {
          tile.position.setFrom(s.position);
        } else {
          _freeMotion(tile, step);
        }
      }
      for (final p in _pending) {
        _placeSettling(p);
      }
      while (_pending.isNotEmpty && _pending.first.due <= elapsed + epsilon) {
        final p = _pending.removeAt(0);
        game._slotOf(p.tile)?.tile = null;
        p.berth.tile = p.tile;
        p.berth.settling = false;
        p.tile.position.setFrom(p.berth.position);
        p.tile.priority = 2;
        p.tile.velocity.setZero();
        cleanLandings++;
        game.lastResultMessage =
            'Latched · ${p.tile.letter} in berth ${p.berth.index + 1}';
        game.onLatch?.call();
        _reviewRow();
        if (game.isGameOver) return;
        game._notifyHud();
      }
    }
    if (held != null) {
      _showPreview(
        _assess(held!, _motion.at(_lastStamp + elapsed - _lastArrival)),
      );
    }
    game._hudElapsed += dt;
    if (game._hudElapsed >= .15) {
      game._hudElapsed = 0;
      game._notifyHud();
    }
  }

  void _reviewRow() {
    if (!game._playing ||
        _pending.isNotEmpty ||
        (held != null && game._slotOf(held!) != null) ||
        game._slots.any((s) => s.tile == null)) {
      return;
    }
    if (game._row == game.targetWord) {
      game._finish(won: true);
    } else {
      game.lastResultMessage = 'Not quite. Reorder the letters';
    }
  }
}
