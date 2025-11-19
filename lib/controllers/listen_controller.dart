// controllers/listen_controller.dart
import 'package:flutter/material.dart';
import 'mic_controller.dart';
import '../timer_models/timer_model.dart';
import '../routines/routines_page.dart';
import 'tutorial_controller.dart';
import '../utils/fuzzy_timer_match.dart';

class ListenController {
  final VoiceController voice;
  final GlobalKey<RoutinesPageState> routinesKey;

  // state accessors
  final bool Function() getIsListening;
  final void Function(bool) setIsListening;

  final TutorialController tutorialController;

  final TimerData? Function() getActiveTimer; // currently unused but kept for future
  final int Function() getTabIndex;

  final void Function(TimerData timer) pauseTimer;
  final void Function(TimerData timer) resumeTimer;
  final void Function(TimerData timer) stopTimer;

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

  // ------------------ MAIN LISTENER ENTRY ------------------
  Future<void> startListening() async {
    // Stop any ongoing TTS
    await stopPageTts();

    if (getIsListening()) return;
    setState(() => setIsListening(true));

    // ---------- CASE 0: Tutorial ----------
    if (tutorialController.isActive) {
      await _handleTutorialCase();
      return;
    }

    // ---------- Unified FLOW: control timers + create timers ----------
    await voice.startListeningForControl(
      onCommand: (cmd) async {
        final lower = cmd.toLowerCase().trim();

        // 1) Try to handle as a TIMER CONTROL (pause/resume/stop/restart/start BY NAME)
        final handledControl = await _tryHandleTimerControl(lower);
        if (handledControl) {
          if (mounted()) setState(() => setIsListening(false));
          return;
        }

        // 2) Not a (valid) control command → try to interpret as CREATE TIMER
        final created = await _handleCreateTimerFromRaw(lower);
        if (created) {
          if (mounted()) setState(() => setIsListening(false));
          return;
        }

        // 3) If still not handled and we are on Routines tab → pass to routines
        if (getTabIndex() == 2) {
          routinesKey.currentState?.handleVoiceCommand(lower);
          if (mounted()) setState(() => setIsListening(false));
          return;
        }

        // 4) Fallback: nothing matched
        await voice.speak("Sorry, I didn't understand that.");
        if (mounted()) setState(() => setIsListening(false));
      },
    );
  }

  // ------------------ CASE 0: Tutorial ------------------
  Future<void> _handleTutorialCase() async {
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
        }
      },
    );
  }

  // ------------------ TIMER CONTROL BY NAME ------------------
  /// Returns true if the phrase was handled as a control command
  Future<bool> _tryHandleTimerControl(String spoken) async {
    final controlWords = <String>[
      "pause",
      "resume",
      "continue",
      "stop",
      "end",
      "cancel",
      "start",
      "begin",
      "restart",
      "start again",
      "reset",
    ];

    final isControl = controlWords.any((w) => spoken.contains(w));
    if (!isControl) return false; // Not a control phrase at all

    final timers = getTimers();
    if (timers.isEmpty) {
      await voice.speak("You don't have any timers yet.");
      return true;
    }

    // Strip common action words & filler to get the timer name candidate
    String extracted = spoken.replaceAll(
      RegExp(
        r"(pause|resume|continue|stop|end|cancel|start again|start|restart|begin|timer|the|my|a)",
      ),
      "",
    ).trim();

    if (extracted.isEmpty) {
      await voice.speak("Please say the timer name.");
      return true;
    }

    // Fuzzy match timer name
    final matches = FuzzyTimerMatcher.matchTimers(extracted, timers);

    if (matches.isEmpty) {
      await voice.speak("I couldn't find any timer named $extracted.");
      return true; // we handled by giving feedback
    }

    // Ambiguous between top 2 matches
    if (matches.length > 1 &&
        (matches.first.score - matches[1].score) < 0.15) {
      final names = matches.take(2).map((m) => m.timer.name).join(" or ");
      await voice.speak("Did you mean $names?");
      return true;
    }

    final chosen = matches.first.timer;

    // ----- Determine action -----
    final bool wantsPause = spoken.contains("pause");
    final bool wantsResume =
        spoken.contains("resume") || spoken.contains("continue");
    final bool wantsStop = spoken.contains("stop") ||
        spoken.contains("end") ||
        spoken.contains("cancel");
    final bool wantsRestart = spoken.contains("restart") ||
        spoken.contains("start again") ||
        spoken.contains("reset");
    final bool wantsStart =
        spoken.contains("start") || spoken.contains("begin");

    // Behavior C for "start": start if stopped, resume if paused, deny if running
    if (wantsRestart) {
      // restart = stop + resume (your _stopTimer resets to full duration)
      stopTimer(chosen);
      resumeTimer(chosen);
      await voice.speak("Restarting ${chosen.name}.");
      return true;
    }

    if (wantsPause) {
      if (chosen.isRunning) {
        pauseTimer(chosen);
      } else {
        await voice.speak("${chosen.name} is not running.");
      }
      return true;
    }

    if (wantsResume) {
      if (!chosen.isRunning) {
        resumeTimer(chosen);
      } else {
        await voice.speak("${chosen.name} is already running.");
      }
      return true;
    }

    if (wantsStop) {
      if (chosen.isRunning) {
        stopTimer(chosen);
      } else {
        // your stopTimer also resets + closes countdown etc; still ok
        stopTimer(chosen);
      }
      return true;
    }

    if (wantsStart) {
      // C: start if stopped, resume if paused, deny if already running
      if (!chosen.isRunning) {
        // From your model, resumeTimer will create a ticker from current totalTime
        resumeTimer(chosen);
      } else {
        await voice.speak("${chosen.name} is already running.");
      }
      return true;
    }

    // If somehow we got here (some weird control word), treat as handled
    return true;
  }

  // ------------------ CREATE TIMER FROM RAW SPEECH ------------------
  /// Tries to interpret [spoken] as a "create timer" command.
  /// Returns true if a timer was created / screen was navigated.
  Future<bool> _handleCreateTimerFromRaw(String spoken) async {
    // Use your existing parser
    final parsed = await voice.interpretCommand(spoken);

    // Completely unrecognized pattern
    if (parsed == null) {
      return false; // let caller decide fallback
    }

    // "Incomplete" case: user just said "timer" or similar
    final bool allNull = (parsed.workMinutes == null &&
        parsed.breakMinutes == null &&
        parsed.sets == null &&
        parsed.simpleTimerMinutes == null);

    if (allNull) {
      await voice.speak(
        "Please tell me the timer length. For example, say 'start a 5 minute timer'.",
      );
      return true;
    }

    // We have enough info to build a timer
    final work = parsed.workMinutes ?? parsed.simpleTimerMinutes ?? 0;
    final sets = parsed.sets ?? 1;
    final breaks = parsed.breakMinutes ?? 0;

    if (work <= 0 || sets <= 0) {
      await voice.speak(
        "I couldn't figure out the timer duration. Please try again with a clear time.",
      );
      return true;
    }

    final totalTime = ((work * sets) + (breaks * (sets - 1))) * 60;

    final timerData = TimerData(
      id: DateTime.now().toIso8601String(),
      name: (parsed.name?.trim().isNotEmpty ?? false)
          ? parsed.name!
          : generateUniqueName(getTimers()),
      workInterval: work,
      breakInterval: breaks,
      totalSets: sets,
      totalTime: totalTime,
      currentSet: 1,
    );

    if (!mounted()) return true;

    setState(() {
      setEditingTimer(null);
      setVoiceFilledTimer(timerData);
      setTabIndex(1); // jump to CreateTimerScreen with pre-filled data
    });

    return true;
  }

  // ------------------ STOP LISTENING ------------------
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
