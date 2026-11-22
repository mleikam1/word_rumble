import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../data/level_theme.dart';
import '../word_rumble_game.dart';

class LetterComponent extends PositionComponent with DragCallbacks {
  final WordRumbleGame board;
  final int id;
  final String letter;
  final bool isDecoy;
  final double phase;
  int homeIndex;
  double? landingY;
  final Vector2 home = Vector2.zero();
  final Vector2 velocity = Vector2.zero();
  final TextPainter _label = TextPainter(textDirection: TextDirection.ltr);

  // Flame's dispatcher can deliver two pointer streams to one component.
  int? _pointer;
  final Vector2 _finger = Vector2.zero();
  final Vector2 _grabOffset = Vector2.zero();
  double _age = 0;
  double _nextKick;

  LetterComponent({
    required this.board,
    required this.id,
    required this.letter,
    required this.isDecoy,
    required this.homeIndex,
    required this.phase,
  }) : _nextKick = 0.65 + phase / 4,
       super(anchor: Anchor.center, priority: 2);

  void setSide(double side) {
    if (width == side && _label.text != null) return;
    size.setAll(side);
    final rect = size.toRect().deflate(2);
    _baseShape = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    _faceShape = RRect.fromRectAndRadius(
      Rect.fromLTRB(rect.left, rect.top, rect.right, rect.bottom - side * .09),
      const Radius.circular(9),
    );
    _label.text = TextSpan(
      text: letter,
      style: TextStyle(
        fontFamily: 'DM Sans',
        fontSize: side * 0.53,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF102E38),
      ),
    );
    _label.layout();
  }

  @override
  void onRemove() {
    _label.dispose();
    super.onRemove();
  }

  void returnHome() {
    position.setFrom(home);
    velocity.setZero();
  }

  void forgetPointer() {
    _pointer = null;
    priority = 2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!board.canMove(this)) return;

    // Limit physics travel after a stalled frame. The round timer uses real dt.
    final step = math.min(dt, 0.05);
    _age += step;
    final theme = board.currentTheme;
    final dy = theme.gravity + theme.buoyancy;
    final time = _age + phase;
    var ax = (home.x - position.x) * 5 - velocity.x * 3;
    var ay = dy;
    switch (theme.physicsStyle) {
      case PhysicsStyle.water:
        // A damped, oscillating waterline gives each tile a restoring force.
        ax += 38 * math.sin(time);
        ay =
            (home.y + 8 * math.sin(time * 1.5) - position.y) * 8 -
            velocity.y * 3 +
            dy * 0.08;
      case PhysicsStyle.lava:
        if (_age >= _nextKick) {
          velocity.y = -board.lavaKickSpeed;
          _nextKick += 1.6 + phase * 0.18;
        }
      case PhysicsStyle.wind:
        ax = (home.x + board.windOffset - position.x) * 9 - velocity.x * 5;
      case PhysicsStyle.zeroG:
        ax = 32 * math.cos(time * 0.9) - velocity.x * 0.5;
        ay = 28 * math.sin(time) - velocity.y * 0.5;
      case PhysicsStyle.ice:
        break;
    }

    velocity.x += ax * step;
    velocity.y += ay * step;
    final floor = landingY;
    final previousY = position.y;
    if (floor != null && previousY > floor && velocity.y >= 0) {
      // A tile released underneath its shelf returns smoothly after release.
      velocity.y = -math.min(270.0, (previousY - floor) * 8 + 14);
    }
    position.addScaled(velocity, step);
    if (floor != null && previousY <= floor && position.y >= floor) {
      position.y = floor;
      velocity.y *= -0.35;
      if (velocity.y.abs() < 10) velocity.y = 0;
    }

    final half = size.x / 2;
    final right = math.max(half, board.size.x - half);
    final bottom = math.max(half, board.size.y - half);
    if (position.x < half || position.x > right) {
      position.x = position.x.clamp(half, right);
      velocity.x *= -0.35;
    }
    if (position.y < half || position.y > bottom) {
      position.y = position.y.clamp(half, bottom);
      velocity.y *= theme.physicsStyle == PhysicsStyle.ice ? -0.8 : -0.35;
      if (velocity.y.abs() < 10) velocity.y = 0;
    }
  }

  late RRect _baseShape;
  late RRect _faceShape;
  static final _ripplePaint =
      Paint()
        ..color = const Color(0xB8D9F6D6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7;
  static final _basePaint = Paint()..color = const Color(0xFFCE9D52);
  static final _facePaint = Paint()..color = const Color(0xFFFFF4D6);
  static final _edgePaint =
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF173E46);

  @override
  void render(Canvas canvas) {
    if (board.currentTheme.physicsStyle == PhysicsStyle.water &&
        _pointer == null &&
        y > board.size.y * .32) {
      final ripple = Rect.fromCenter(
        center: Offset(width / 2, height * .9),
        width: width * 1.28,
        height: height * .25,
      );
      canvas.drawOval(ripple, _ripplePaint);
    }
    canvas.drawRRect(_baseShape, _basePaint);
    canvas.drawRRect(_faceShape, _facePaint);
    canvas.drawRRect(_baseShape, _edgePaint);
    _label.paint(
      canvas,
      Offset((width - _label.width) / 2, (height * .91 - _label.height) / 2),
    );
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_pointer != null || !board.beginDrag(this)) return;
    _pointer = event.pointerId;
    _finger.setFrom(event.canvasPosition);
    _grabOffset.setFrom(position - _finger);
    velocity.setZero();
    priority = 3;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_pointer != event.pointerId) return;
    // canvasDelta is valid even when a fast pointer leaves the component.
    _finger.add(event.canvasDelta);
    final half = size.x / 2;
    position.setValues(
      (_finger.x + _grabOffset.x).clamp(half, board.size.x - half),
      (_finger.y + _grabOffset.y).clamp(half, board.size.y - half),
    );
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (_pointer == event.pointerId) {
      board.releaseDrag(this, _finger, event.velocity);
    }
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    if (_pointer == event.pointerId) board.cancelDrag();
    // The base implementation forwards to onDragEnd. Clearing our pointer
    // first ensures cancellation cannot be interpreted as a deliberate drop.
    super.onDragCancel(event);
  }
}
