import 'dart:async';
import 'package:flutter/material.dart';

// Import your voice controllers
import '../stopwatch_voice_controller.dart';
import '../timer_voice_controller.dart';
import '../routines_voice_controller.dart';
import '../tutorial_voice_controller.dart';

/// Central router for all app-wide voice commands.
/// Keeps an active domain context (sticky) but can switch domains dynamically.
class GlobalVoiceRouter {
  final StopwatchVoiceController stopwatchController;
  final TimerVoiceController timerController;
  final RoutinesVoiceController routinesController;
  final TutorialVoiceController tutorialController;

  String? _activeDomain;
  // Allow UI to explicitly activate a domain after navigation
  void activateDomain(String domain) {
    _activeDomain = domain;
    debugPrint("🔒 Voice locked to domain: $_activeDomain");
  }


  GlobalVoiceRouter({
    required this.stopwatchController,
    required this.timerController,
    required this.routinesController,
    required this.tutorialController,
  });

  /// Listens for a single user command and routes it smartly.
  Future<void> listenAndRoute() async {
    try {
      final text = await stopwatchController.listenOnce();
      if (text == null || text.isEmpty) {
        await stopwatchController.speak("I didn't catch that. Please try again.");
        return;
      }

      final lower = text.toLowerCase().trim();
      debugPrint("🎙 GlobalVoiceRouter recognized: $lower");
      debugPrint("🧭 Current active domain: $_activeDomain");

      // =====================================================
      // 1️⃣ UNIVERSAL SWITCHING COMMANDS (available anytime)
      // =====================================================
      if (_containsAny(lower, [
        'timer',
        'create timer',
        'go to timer',
        'open timer',
        'start timer',
      ])) {
        _activeDomain = 'timer';
        debugPrint("🔁 Switching to TIMER domain");

        // ✅ Tell UI to switch first
        timerController.onOpenTimer?.call();

        // ✅ Wait for tab to update
        await Future.delayed(const Duration(milliseconds: 500));

        // ✅ Now process the command
        await timerController.handleCommand(lower);

        return;
      }


      if (_containsAny(lower, [
        'stopwatch',
        'create stopwatch',
        'open stopwatch',
        'start stopwatch',
        'go to stopwatch',
        'launch stopwatch',
      ])) {
        debugPrint("🔁 Detected STOPWATCH command (UI will handle navigation)");
        await stopwatchController.handleCommand(lower);
        // The UI will later call _voiceRouter.activateDomain('stopwatch')
        return;
      }


      if (_containsAny(lower, ['routine', 'routines'])) {
        _activeDomain = 'routine';
        debugPrint("🔁 Switching to ROUTINE domain");
        await routinesController.handleCommand(lower);
        return;
      }

      if (_containsAny(lower, ['tutorial'])) {
        _activeDomain = 'tutorial';
        debugPrint("🔁 Switching to TUTORIAL domain");
        await tutorialController.handleCommand(lower);
        return;
      }

      // =====================================================
      // 2️⃣ ROUTE BASED ON ACTIVE CONTEXT
      // =====================================================
      switch (_activeDomain) {
        case 'stopwatch':
          await stopwatchController.handleCommand(lower);
          break;
        case 'timer':
          await timerController.handleCommand(lower);
          break;
        case 'routine':
          await routinesController.handleCommand(lower);
          break;
        case 'tutorial':
          await tutorialController.handleCommand(lower);
          break;
        default:
          await stopwatchController.speak(
            "Sorry, I didn’t understand. Try saying stopwatch, timer, routine, or tutorial.",
          );
      }
    } catch (e, st) {
      debugPrint("⚠️ Voice routing error: $e\n$st");
      await stopwatchController.speak("An error occurred while processing your command.");
    }
  }

  /// Stops all listening sessions and clears context.
  Future<void> stopListening() async {
    _activeDomain = null;
    await Future.wait([
      stopwatchController.stopListening(),
      timerController.stopListening(),
      routinesController.stopListening(),
      tutorialController.stopListening(),
    ]);
  }

  // Small helper
  bool _containsAny(String input, List<String> patterns) {
    for (final p in patterns) {
      if (input.contains(p)) return true;
    }
    return false;
  }
}
