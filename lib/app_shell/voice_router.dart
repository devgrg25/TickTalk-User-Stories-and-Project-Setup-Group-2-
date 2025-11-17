import '../logic/timer/timer_manager.dart';
import '../logic/timer/timer_controller.dart';
import '../logic/routines/routine_storage.dart';
import '../logic/routines/routine_model.dart';
import '../logic/voice/voice_tts_service.dart';

/// Callback so the router can switch tabs in MainShell.
typedef TabNavigator = void Function(int index);

/// Optional AI fallback. Later you can connect this to an API (OpenAI, etc).
typedef AiFallback = Future<void> Function(String rawText);

class VoiceRouter {
  VoiceRouter({
    required this.onNavigateTab,
    this.aiFallback,
  });

  final TabNavigator onNavigateTab;
  final AiFallback? aiFallback;

  /// Entry point: call this with the final recognized speech.
  Future<void> handle(String rawText) async {
    final input = rawText.toLowerCase().trim();
    if (input.isEmpty) return;

    // 1) Timer commands (check FIRST)
    if (await _handleTimerCommands(input)) return;

// 2) Navigation (SECOND)
    if (await _handleNavigation(input)) return;


    // 3) Routine commands (start routine, list routines)
    if (await _handleRoutineCommands(input)) return;

    // 4) Nothing matched → AI fallback (Hybrid C2)
    if (aiFallback != null) {
      await aiFallback!(rawText);
      return;
    }

    // 5) No AI configured yet → generic response
    await VoiceTtsService.instance
        .speak("Sorry, I didn't understand that command.");
  }

  // ---------------- NAVIGATION ----------------

  Future<bool> _handleNavigation(String input) async {
    // Examples:
    // "go home", "back home"
    if (input.contains("home")) {
      onNavigateTab(0);
      await VoiceTtsService.instance.speak("Going home.");
      return true;
    }

    // "open timer", "go to timer"
    if (input.contains("timer")) {
      onNavigateTab(1);
      await VoiceTtsService.instance.speak("Opening timer.");
      return true;
    }

    // "open routines", "go to routines"
    if (input.contains("routine")) {
      onNavigateTab(2);
      await VoiceTtsService.instance.speak("Opening routines.");
      return true;
    }

    // "open settings"
    if (input.contains("setting")) {
      onNavigateTab(3);
      await VoiceTtsService.instance.speak("Opening settings.");
      return true;
    }

    return false;
  }

  // ---------------- TIMERS ----------------

  Future<bool> _handleTimerCommands(String input) async {
    final timers = TimerManager.instance.timers;
    final ActiveTimer? active =
    timers.isNotEmpty ? timers.last : null;

    // --- Control existing timer if there is one ---
    if (active != null) {
      final c = active.controller;

      if (input.contains("pause")) {
        c.pause();
        await VoiceTtsService.instance.speak("Timer paused.");
        return true;
      }

      if (input.contains("resume") || input.contains("continue")) {
        c.resume();
        await VoiceTtsService.instance.speak("Resuming timer.");
        return true;
      }

      if (input.contains("stop") ||
          input.contains("cancel") ||
          input.contains("end")) {
        TimerManager.instance.stopTimer(active.id);
        await VoiceTtsService.instance.speak("Timer stopped.");
        return true;
      }

      // "add 10 seconds", "add 1 minute"
      if (input.contains("add")) {
        final extra = _extractDurationInSeconds(input);
        if (extra != null && extra > 0) {
          c.addTime(extra);
          await VoiceTtsService.instance
              .speak("Adding ${_spokenDuration(extra)} to the timer.");
          return true;
        }
      }
    }

    // --- Create a new timer if user mentions "timer" or "countdown" ---
    if (input.contains("timer") || input.contains("countdown")) {
      final seconds = _extractDurationInSeconds(input);
      if (seconds == null || seconds <= 0) return false;

      final label = _extractLabel(input) ?? "TIMER";

      final intervals = [
        TimerInterval(name: label.toUpperCase(), seconds: seconds),
      ];

      TimerManager.instance.startTimer(label.toUpperCase(), intervals);

      await VoiceTtsService.instance
          .speak("Starting $label for ${_spokenDuration(seconds)}.");
      return true;
    }

    return false;
  }

  // ---------------- ROUTINES ----------------

  Future<bool> _handleRoutineCommands(String input) async {
    // "list routines", "show routines", "what routines do I have"
    if (input.contains("list routines") ||
        input.contains("show routines") ||
        input.contains("what routines")) {
      final routines = await RoutineStorage.instance.loadRoutines();
      if (routines.isEmpty) {
        await VoiceTtsService.instance
            .speak("You have no routines saved yet.");
        return true;
      }

      final names = routines.map((r) => r.name).join(", ");
      await VoiceTtsService.instance.speak("Your routines are: $names.");
      return true;
    }

    // "start morning routine", "start workout routine"
    if (input.contains("start") && input.contains("routine")) {
      final routines = await RoutineStorage.instance.loadRoutines();
      if (routines.isEmpty) {
        await VoiceTtsService.instance
            .speak("You have no routines saved yet.");
        return true;
      }

      final lower = input.toLowerCase();
      Routine? chosen;

      // Try to match routine name inside the text
      for (final r in routines) {
        if (lower.contains(r.name.toLowerCase())) {
          chosen = r;
          break;
        }
      }

      // If no exact text match, just use the first one
      chosen ??= routines.first;

      final cloned = chosen.intervals
          .map((i) => TimerInterval(name: i.name, seconds: i.seconds))
          .toList();

      TimerManager.instance.startTimer(chosen.name, cloned);

      await VoiceTtsService.instance
          .speak("Starting routine ${chosen.name}.");
      return true;
    }

    return false;
  }

  // ---------------- HELPERS ----------------

  /// Extract a duration like "10 seconds", "1 minute" from text and convert to seconds.
  int? _extractDurationInSeconds(String input) {
    final regex = RegExp(
      r'(\d+)\s*(second|seconds|sec|secs|s)\b|(\d+)\s*(minute|minutes|min|m)\b',
      caseSensitive: false,
    );

    final match = regex.firstMatch(input);
    if (match == null) return null;

    // First check seconds group
    final secValue = match.group(1);
    final secUnit = match.group(2);

    if (secValue != null && secUnit != null) {
      final value = int.tryParse(secValue);
      return value; // already seconds
    }

    // Then check minutes group
    final minValue = match.group(3);
    final minUnit = match.group(4);

    if (minValue != null && minUnit != null) {
      final value = int.tryParse(minValue);
      return value != null ? value * 60 : null;
    }

    return null;
  }


  /// Try to extract a label like "plank", "breathing", etc. from the sentence.
  String? _extractLabel(String input) {
    String cleaned = input.toLowerCase();

    // Remove duration info
    cleaned = cleaned.replaceAll(
        RegExp(r'\b\d+\s*(second|seconds|sec|secs|s|minute|minutes|min|m)\b'),
        '');

    // Remove common command words
    cleaned = cleaned.replaceAll(
        RegExp(r'\b(start|set|make|create|begin|run|a|an|the|timer|countdown|for|please|to)\b'),
        '');

    cleaned = cleaned.trim();
    if (cleaned.isEmpty) return null;

    // Normalize spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    // Capitalize first letter
    return cleaned.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    }).join(' ');
  }


  /// Human-friendly string for speech: "1 minute and 30 seconds"
  String _spokenDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;

    if (m > 0 && s > 0) {
      return "$m minute${m == 1 ? '' : 's'} and "
          "$s second${s == 1 ? '' : 's'}";
    } else if (m > 0) {
      return "$m minute${m == 1 ? '' : 's'}";
    } else {
      return "$s second${s == 1 ? '' : 's'}";
    }
  }
}
