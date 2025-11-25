enum PowerUpType {
  hintLetter,      // Reveal a correct letter in its correct slot
  freezeTime,      // Pause the timer for a short duration
  clearDecoys,     // Remove decoy letters
}

class PowerUpDefinition {
  final PowerUpType type;
  final String id;
  final String label;
  final int costCoins;

  const PowerUpDefinition({
    required this.type,
    required this.id,
    required this.label,
    required this.costCoins,
  });
}
