// controllers/listen_controller.dart
import 'package:flutter/material.dart';
import 'mic_controller.dart';
import '../timer_models/timer_model.dart';
import '../routines/routines_page.dart';
import 'tutorial_controller.dart';

class ListenController {
  final VoiceController voice;
  final GlobalKey<RoutinesPageState> routinesKey;

  // state accessors
  final bool Function() getIsListening;
  final void Function(bool) setIsListening;

  final TutorialController tutorialController;

  final TimerData? Function() getActiveTimer;
  final int Function() getTabIndex;

  final void Function() pauseTimer;
  final void Function() resumeTimer;
  final void Function() stopTimer;

  final void Function(TimerData?) setEditingTimer;
  final void Function(TimerData?) setVoiceFilledTimer;
  final void Function(int) setTabIndex;
  final List<TimerData> Function() getTimers;
  final String Function(List<TimerData>) generateUniqueName;

  final Future<void> Function() stopPageTts;

  final bool Function() mounted;
  final void Function(void Function()) setState;

  ListenController({
    required this.voice,
    required this.routinesKey,
    required this.getIsListening,
    required this.setIsListening,
    required this.tutorialController,
    required this.getActiveTimer,
    required this.getTabIndex,
    required this.pauseTimer,
    required this.resumeTimer,
    required this.stopTimer,
    required this.setEditingTimer,
    required this.setVoiceFilledTimer,
    required this.setTabIndex,
    required this.getTimers,
    required this.generateUniqueName,
    required this.stopPageTts,
    required this.mounted,
    required this.setState,
  });

  // ------------------ MAIN LISTENER ------------------
  Future<void> startListening() async {
    // stop any speaking first
    await stopPageTts();

    if (getIsListening()) return;
    setState(() => setIsListening(true));

    // ---------- CASE 0: tutorial ----------
    if (tutorialController.isActive) {
      debugPrint('Case 0 - Tutorial');

      await voice.startListeningRaw(
        onCommand: (String heard) async {
          final words = heard.toLowerCase().trim();
          setState(() => setIsListening(false));

          if (words.contains("skip") ||
              words.contains("stop tutorial") ||
              words.contains("end tutorial") ||
              words.contains("cancel tutorial") ||
              words.contains("done")) {
            tutorialController.stop();
            return;
          }

        },
      );
      return;
    }

    // ---------- CASE 1: Active Timer ----------
    final active = getActiveTimer();
    if (active != null) {
      debugPrint('Case 1 - Active Timer');

      await voice.startListeningForControl(
        onCommand: (cmd) async {
          setState(() => setIsListening(false));
          final words = cmd.toLowerCase();

          if (words.contains("pause") || words.contains("hold")) {
            pauseTimer();
          } else if (words.contains("resume") || words.contains("continue")) {
            resumeTimer();
          } else if (words.contains("stop") || words.contains("end")) {
            stopTimer();
          } else if (words.contains("timer")) {
            voice.speak(
              "Please stop the current timer before running a new timer.",
            );
          } else {
            voice.speak("Command not recognized while timer is running.");
          }
        },
      );
      return;
    }

    // ---------- CASE 2: Routines Tab ----------
    if (getTabIndex() == 2) {
      debugPrint('Case 2 - Routines Tab');

      await voice.startListeningRaw(
        onCommand: (String cmd) async {
          setState(() => setIsListening(false));
          routinesKey.currentState?.handleVoiceCommand(cmd);
        },
      );
      return;
    }

    // ---------- CASE 3: Create Timer / global create ----------
    debugPrint('Case 3 - Create Timer');

    await voice.startListeningForTimer(
      onCommand: (ParsedVoiceCommand data) async {
        await voice.stopListening();

        if (!mounted()) return;
        setState(() => setIsListening(false));

        final work = data.workMinutes ?? data.simpleTimerMinutes ?? 0;
        final sets = data.sets ?? 1;
        final breaks = data.breakMinutes ?? 0;
        final totalTime = ((work * sets) + (breaks * (sets - 1))) * 60;

        final timerData = TimerData(
          id: DateTime.now().toIso8601String(),
          name: (data.name?.trim().isNotEmpty ?? false)
              ? data.name!
              : generateUniqueName(getTimers()),
          workInterval: work,
          breakInterval: breaks,
          totalSets: sets,
          totalTime: totalTime,
          currentSet: 1,
        );

        if (!mounted()) return;
        setState(() {
          setEditingTimer(null);
          setVoiceFilledTimer(timerData);
          setTabIndex(1);
        });
      },
      onUnrecognized: (spoken) async {
        if (spoken == "incomplete") {
          await voice.speak(
            "Please tell me the timer length. For example, say 'start a 5 minute timer'.",
          );
        } else {
          await voice.speak("Sorry, I didn't understand that.");
        }
      },
    );
  }

  Future<void> stopListening() async {
    if (!getIsListening()) return;

    try {
      await voice.stopListening();
    } finally {
      if (mounted()) {
        setState(() => setIsListening(false));
      }
    }
  }
}
