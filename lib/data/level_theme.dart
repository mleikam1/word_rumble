import 'package:flutter/material.dart';

enum PhysicsStyle {
  water,
  ice,
  lava,
  wind,
  zeroG,
}

class LevelTheme {
  final String id;
  final String name;
  final PhysicsStyle physicsStyle;
  final Color backgroundColor;
  final Color letterColor;
  final Color slotColor;

  /// Base gravity pull downward (pixels/s²).
  final double gravity;

  /// Upward buoyancy (negative values float upwards).
  final double buoyancy;

  const LevelTheme({
    required this.id,
    required this.name,
    required this.physicsStyle,
    required this.backgroundColor,
    required this.letterColor,
    required this.slotColor,
    required this.gravity,
    required this.buoyancy,
  });
}
