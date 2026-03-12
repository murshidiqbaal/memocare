// lib/core/utils/vibrate.dart
//
// Safe wrapper around the `vibration` package.
// Fixes:
//   • Vibration.hasVibrator() returns Future<bool?> — null-safe unwrap
//   • Vibration.vibrate(repeat:) parameter removed in newer versions — use a
//     manual loop via a Timer instead
//   • All methods are no-ops on devices without a vibrator

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

abstract final class VibrationHelper {
  // Internal state
  static Timer? _repeatTimer;
  static bool _isVibrating = false;

  /// Vibrates with [pattern] and repeats indefinitely until [cancel] is called.
  /// Pattern = alternating silence/vibration durations in ms.
  /// e.g. [500, 1000] → 500 ms pause, 1000 ms vibrate, repeat.
  static Future<void> startRepeating({
    List<int> pattern = const [0, 500, 300, 500],
  }) async {
    if (_isVibrating) return; // already running

    final bool hasVibrator = await _hasVibrator();
    if (!hasVibrator) return;

    _isVibrating = true;

    // Calculate total cycle duration from the pattern
    final cycleDuration = pattern.fold(0, (sum, ms) => sum + ms);

    // Kick off the first vibration immediately
    _vibrate(pattern);

    // Re-trigger every [cycleDuration] ms
    _repeatTimer = Timer.periodic(
      Duration(milliseconds: cycleDuration),
      (_) {
        if (_isVibrating) _vibrate(pattern);
      },
    );
  }

  /// Stops all vibration and clears the repeat timer.
  static Future<void> cancel() async {
    _isVibrating = false;
    _repeatTimer?.cancel();
    _repeatTimer = null;
    try {
      await Vibration.cancel();
    } catch (e) {
      debugPrint('[VibrationHelper] cancel error: $e');
    }
  }

  /// One-shot vibration for [duration] ms. Safe on devices without a vibrator.
  static Future<void> once({int duration = 400}) async {
    if (!await _hasVibrator()) return;
    try {
      await Vibration.vibrate(duration: duration);
    } catch (e) {
      debugPrint('[VibrationHelper] once error: $e');
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static Future<bool> _hasVibrator() async {
    try {
      return (await Vibration.hasVibrator());
    } catch (_) {
      return false;
    }
  }

  static void _vibrate(List<int> pattern) {
    try {
      // `pattern` parameter accepted by all modern versions of the package
      Vibration.vibrate(pattern: pattern);
    } catch (e) {
      debugPrint('[VibrationHelper] vibrate error: $e');
    }
  }
}
