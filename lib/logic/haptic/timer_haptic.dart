import 'package:flutter/services.dart';

/// ------------------------------------------------------------
/// TIMER HAPTIC FEEDBACK MODULE
/// ------------------------------------------------------------
/// Provides tactile feedback cues during voice-driven or
/// touch-based timer creation and playback flows.
///
/// The goal is to make the app blind-friendly by combining
/// short, meaningful vibrations with spoken feedback.
///
/// Each method is async-safe and may be awaited by controllers.
///
/// Example usage:
///   final haptics = TimerHaptic();
///   await haptics.confirmMinor();
/// ------------------------------------------------------------
class TimerHaptic {
  /// A soft prompt — e.g. when app is waiting for input
  Future<void> promptType() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Light confirmation (minor success) — e.g. user response accepted
  Future<void> confirmMinor() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Strong confirmation — e.g. timer successfully created or saved
  Future<void> confirmStrong() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Mild error feedback — something missing or invalid input
  Future<void> errorSoft() async {
    try {
      await HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 80));
    } catch (_) {}
  }

  /// Strong error — operation cancelled or failed
  Future<void> errorHard() async {
    try {
      await HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 180));
      await HapticFeedback.vibrate();
    } catch (_) {}
  }

  /// Optional: custom multi-pulse pattern for advanced tactile cues.
  /// Requires the `vibration` package to be installed if you want
  /// longer sequences (optional, not required for current build).
  ///
  /// Example:
  ///   await customPattern([0, 50, 60, 100, 200, 50]);
  ///
  Future<void> customPattern(List<int> patternMs) async {
    // Placeholder — uncomment if you use the vibration package.
    // if (await Vibration.hasVibrator() ?? false) {
    //   await Vibration.vibrate(pattern: patternMs);
    // }
  }
}
