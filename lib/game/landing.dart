import 'dart:math' as math;

import 'package:flame/components.dart';

enum LandingCue { water, aligned, edge, fast, occupied, hazard }

/// Both the live berth marker and release commit use this same assessment.
LandingCue evaluateLanding({
  required Vector2 offset,
  required Vector2 relativeVelocity,
  required double radius,
  required double maxSpeed,
  required bool occupied,
  required bool hazard,
}) {
  final distance = offset.x * offset.x + offset.y * offset.y * 1.12;
  if (distance > radius * radius * 2.4) return LandingCue.water;
  if (occupied) return LandingCue.occupied;
  if (hazard) return LandingCue.hazard;
  if (distance > radius * radius) return LandingCue.edge;
  if (relativeVelocity.length2 > maxSpeed * maxSpeed) return LandingCue.fast;
  return LandingCue.aligned;
}

/// Distance over a fixed trailing interval, including time spent holding still.
/// Event timestamps are used directly, independent of how many frames or moves
/// the device delivers. Interpolation keeps the window's leading edge stable.
class ReleaseMotion {
  static const window = .09;
  final _samples = <({double time, Vector2 point})>[];

  void sample(double time, Vector2 point) {
    if (_samples.isNotEmpty && time < _samples.last.time) return;
    if (_samples.isNotEmpty && time == _samples.last.time) {
      _samples.removeLast();
    }
    _samples.add((time: time, point: point.clone()));
    while (_samples.length > 2 && _samples[1].time <= time - window) {
      _samples.removeAt(0);
    }
  }

  Vector2 at(double time) {
    if (_samples.length < 2) return Vector2.zero();
    final last = _samples.last;
    time = math.max(time, last.time);
    final start = math.max(_samples.first.time, time - window);
    if (last.time <= start || time - start < .001) return Vector2.zero();
    var i = 1;
    while (_samples[i].time < start) {
      i++;
    }
    final a = _samples[i - 1], b = _samples[i];
    final fraction = (start - a.time) / (b.time - a.time);
    final startPoint = a.point + (b.point - a.point) * fraction;
    return ((last.point - startPoint) / (time - start))..clampLength(0, 640);
  }
}
