import 'package:flutter/material.dart';
import 'base/voice_controller_base.dart';

class StopwatchVoiceController extends VoiceControllerBase {
  VoidCallback? onBack;
  void Function(String mode)? onSelectMode;

  // ✅ NEW: callback to open stopwatch tab (index 3)
  VoidCallback? onOpenStopwatch;

  @override
  Future<void> handleCommand(String text) async {
    final lower = text.toLowerCase();

    // --- Step 1: Detect any phrase that means "open stopwatch" ---
    if (lower.contains('stopwatch') ||
        lower.contains('create stopwatch') ||
        lower.contains('open stopwatch') ||
        lower.contains('start stopwatch') ||
        lower.contains('go to stopwatch') ||
        lower.contains('launch stopwatch') ||
        lower.contains('show stopwatch')) {

      await speak("You're now in stopwatch mode. Say 'normal' or 'player' mode.");
      onOpenStopwatch?.call();
      return;
    }

    // --- Step 2: Handle mode selection ---
    if (lower.contains('normal')) {
      await speak("Opening normal stopwatch mode.");
      onSelectMode?.call('normal');
      return;
    }

    if (lower.contains('player')) {
      await speak("Opening player stopwatch mode.");
      onSelectMode?.call('player');
      return;
    }

    // --- Step 3: Go back ---
    if (lower.contains('back') || lower.contains('return')) {
      await speak("Returning to stopwatch mode selector.");
      onBack?.call();
      return;
    }

    // --- Default fallback ---
    await speak("I didn’t catch that. Say 'normal' or 'player' mode.");
  }
}
