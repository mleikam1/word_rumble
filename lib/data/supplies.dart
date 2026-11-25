import 'package:flutter/material.dart';
import 'powerup_definition.dart';

class Supply {
  const Supply(
    this.type,
    this.label,
    this.description,
    this.cost,
    this.icon,
    this.color,
  );
  final PowerUpType type;
  final String label;
  final String description;
  final int cost;
  final IconData icon;
  final Color color;
}

const supplies = [
  Supply(
    PowerUpType.hintLetter,
    'Hint',
    'Reveal the next landing in Campaign, or place a letter in Word Guess.',
    10,
    Icons.lightbulb_outline_rounded,
    Color(0xffffcd50),
  ),
  Supply(
    PowerUpType.freezeTime,
    'Freeze',
    'Stop the round clock for five seconds.',
    20,
    Icons.ac_unit_rounded,
    Color(0xffa7deee),
  ),
  Supply(
    PowerUpType.clearDecoys,
    'Clear decoys',
    'Remove up to three loose decoys in Campaign.',
    20,
    Icons.layers_clear_outlined,
    Color(0xffddc7f2),
  ),
];
