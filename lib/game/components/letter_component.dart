import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../data/level_theme.dart';

class LetterComponent extends PositionComponent
    with DragCallbacks, HasGameRef<FlameGame> {
  final String letter;
  final Color color;
  final double gravity;
  final double buoyancy;
  final PhysicsStyle physicsStyle;
  final bool isDecoy;

  Vector2 velocity = Vector2.zero();
  bool _isDragging = false;
  final Random _rand = Random();

  LetterComponent({
    required this.letter,
    required this.color,
    required Vector2 position,
    required Vector2 size,
    required this.gravity,
    required this.buoyancy,
    required this.physicsStyle,
    this.isDecoy = false,
  }) : super(
    position: position,
    size: size,
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Hitbox so drag events work properly when using event system.
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isDragging) return;

    // Base vertical motion
    final double netAccelY = gravity + buoyancy;
    velocity.y += netAccelY * dt;

    // Theme-specific chaos
    switch (physicsStyle) {
      case PhysicsStyle.water:
      // Small horizontal drift like currents
        velocity.x += (_rand.nextDouble() - 0.5) * 50 * dt;
        break;
      case PhysicsStyle.lava:
      // Occasional upward bursts (eruption feel)
        if (_rand.nextDouble() < 0.01) {
          velocity.y -= 300;
        }
        break;
      case PhysicsStyle.wind:
      // Stronger horizontal wind gusts
        velocity.x += (_rand.nextDouble() - 0.5) * 200 * dt;
        break;
      case PhysicsStyle.zeroG:
      // Gentle random drift
        velocity.x += (_rand.nextDouble() - 0.5) * 60 * dt;
        velocity.y += (_rand.nextDouble() - 0.5) * 60 * dt;
        break;
      case PhysicsStyle.ice:
      // Slightly “bouncy” feeling is handled in floor collision below
        break;
    }

    position += velocity * dt;

    // Bounds based on game size (not parent).
    final gameSize = gameRef.size;
    final double floorY = gameSize.y;
    const double topY = 0;
    const double leftX = 0;
    final double rightX = gameSize.x;

    if (position.y + size.y / 2 > floorY) {
      position.y = floorY - size.y / 2;
      velocity.y *= physicsStyle == PhysicsStyle.ice ? -0.8 : -0.4;
    } else if (position.y - size.y / 2 < topY) {
      position.y = topY + size.y / 2;
      velocity.y *= -0.3;
    }

    if (position.x - size.x / 2 < leftX) {
      position.x = leftX + size.x / 2;
      velocity.x *= -0.3;
    } else if (position.x + size.x / 2 > rightX) {
      position.x = rightX - size.x / 2;
      velocity.x *= -0.3;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = size.toRect();
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    final baseColor = isDecoy ? color.withOpacity(0.7) : color;
    final paint = Paint()..color = baseColor;
    canvas.drawRRect(rrect, paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: letter,
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

  // New Flame event signatures
  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _isDragging = true;
    velocity = Vector2.zero();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    // localDelta is movement in game coordinates
    position += event.localDelta;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _isDragging = false;
    // event.velocity is a Vector2 in game units per second
    velocity = event.velocity;
  }
}
