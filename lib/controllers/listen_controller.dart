// controllers/listen_controller.dart
import 'package:flutter/material.dart';
import 'mic_controller.dart';
import '../timer_models/timer_model.dart';
import '../routines/routines_page.dart';
import 'tutorial_controller.dart';

class ListenController {
  final VoiceController voice;
  final GlobalKey<RoutinesPageState> routinesKey;

  final bool Function() getIsListening;
  final void Function(bool) setIsListening;

  final TutorialController tutorialController;

  final TimerData? Function() getActiveTimer;
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

  // ---------------- MAIN LISTENER ENTRY ----------------
  Future<void> startListening() async {
    await stopPageTts();

    if (getIsListening()) return;
    setState(() => setIsListening(true));

    if (tutorialController.isActive) {
      await _handleTutorialCase();
      return;
    }

    await voice.startListeningForControl(
      onCommand: (cmd) async {
        final lower = cmd.toLowerCase().trim();
        debugPrint(lower);

        final handledControl = await _tryHandleTimerControl(lower);
        if (handledControl) {
          if (mounted()) setState(() => setIsListening(false));
          return;
        }

        final created = await _handleCreateTimerFromRaw(lower);
        if (created) {
          if (mounted()) setState(() => setIsListening(false));
          return;
        }

        if (getTabIndex() == 2) {
          routinesKey.currentState?.handleVoiceCommand(lower);
          if (mounted()) setState(() => setIsListening(false));
          return;
        }

        await Future.delayed(const Duration(milliseconds: 200));
        await voice.speakQueued("Sorry, I didn't understand that.");
        if (mounted()) setState(() => setIsListening(false));
      },
    );
  }

  // ---------------- TUTORIAL CASE ----------------
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

  // ---------------- NUMBER-WORD CONVERSION ----------------
  String convertNumberWords(String text) {
    final map = {
      "zero": "0",
      "one": "1",
      "two": "2",
      "three": "3",
      "four": "4",
      "five": "5",
      "six": "6",
      "seven": "7",
      "eight": "8",
      "nine": "9",
      "ten": "10",
      "first": "1",
      "second": "2",
      "third": "3",
      "fourth": "4",
    };

    var result = text;
    map.forEach((word, digit) {
      result = result.replaceAll(RegExp("\\b$word\\b"), digit);
    });

    return result;
  }

  // ---------------- SMART NAME EXTRACTION ----------------
  String extractName(String spoken, List<TimerData> timers) {
    // Remove action words first
    String cleaned = spoken.replaceAll(
      RegExp(
        r"\b(pause|resume|continue|stop|end|cancel|restart|start again|start|begin|timer|please|the|my|a|number|to)\b",
      ),
      "",
    );

    cleaned = cleaned.trim();

    // Convert number words to digits
    cleaned = convertNumberWords(cleaned);

    // Split into words
    final words = cleaned.split(" ");

    // Try to isolate meaningful keywords:
    // - number: "1", "2"
    // - match words that appear inside timer names
    final timerNames = timers.map((t) => t.name.toLowerCase()).toList();

    // Try each word individually
    for (final w in words) {
      if (w.isEmpty) continue;

      // If timer name contains this word, return it
      for (final tName in timerNames) {
        if (tName.contains(w)) return w;
      }
    }

    // If nothing matched: fall back to full cleaned text
    return cleaned;
  }

  // ---------------- TIMER CONTROL (NAME-ONLY, SMART EXTRACTION) ----------------
  Future<bool> _tryHandleTimerControl(String spoken) async {
    final timers = getTimers();
    if (timers.isEmpty) {
      await voice.speakQueued("You don't have any timers yet.");
      return true;
    }

    // Detect action
    final lc = spoken.toLowerCase().trim();

    final wantsPause   = lc.contains("pause") || lc.contains("freeze");
    final wantsResume  = lc.contains("resume") || lc.contains("continue");
    final wantsStop    = lc.contains("stop") || lc.contains("end") || lc.contains("cancel");
    final wantsRestart = lc.contains("restart") || lc.contains("start again") || lc.contains("reset");
    final wantsStart   = lc.contains("start") || lc.contains("begin");

    final isControl = wantsPause || wantsResume || wantsStop || wantsRestart || wantsStart;
    if (!isControl) return false;

    // ⭐ SMART NAME-EXTRACTION
    final extracted = extractName(lc, timers);

    if (extracted.isEmpty) {
      await voice.speakQueued("Please say the timer name.");
      return true;
    }

    // NAME MATCHING
    TimerData? chosen;
    for (final t in timers) {
      final name = t.name.toLowerCase();
      if (name.contains(extracted)) {
        chosen = t;
        break;
      }
    }

    if (chosen == null) {
      await voice.speakQueued("I couldn't find any timer matching $extracted.");
      return true;
    }

    // Execute action
    await _executeTimerAction(
      timer: chosen,
      wantsPause: wantsPause,
      wantsResume: wantsResume,
      wantsStop: wantsStop,
      wantsRestart: wantsRestart,
      wantsStart: wantsStart,
    );

    return true;
  }

  // ---------------- EXECUTE ACTION ----------------
  Future<void> _executeTimerAction({
    required TimerData timer,
    required bool wantsPause,
    required bool wantsResume,
    required bool wantsStop,
    required bool wantsRestart,
    required bool wantsStart,
  }) async {
    if (wantsRestart) {
      stopTimer(timer);
      resumeTimer(timer);
      await voice.speakQueued("Restarting ${timer.name}.");
      return;
    }

    if (wantsPause) {
      if (timer.isRunning) {
        pauseTimer(timer);
      } else {
        await voice.speakQueued("${timer.name} is not running.");
      }
      return;
    }

    if (wantsResume) {
      if (!timer.isRunning) {
        resumeTimer(timer);
      } else {
        await voice.speakQueued("${timer.name} is already running.");
      }
      return;
    }

    if (wantsStop) {
      stopTimer(timer);
      await voice.speakQueued("Stopped ${timer.name}.");
      return;
    }

    if (wantsStart) {
      if (!timer.isRunning) {
        resumeTimer(timer);
        await voice.speakQueued("Starting ${timer.name}.");
      } else {
        await voice.speakQueued("${timer.name} is already running.");
      }
      return;
    }
  }

  // ---------------- CREATE TIMER ----------------
  Future<bool> _handleCreateTimerFromRaw(String spoken) async {
    final parsed = await voice.interpretCommand(spoken);

    if (parsed == null) return false;

    final allNull = parsed.workMinutes == null &&
        parsed.breakMinutes == null &&
        parsed.sets == null &&
        parsed.simpleTimerMinutes == null;

    if (allNull) {
      await voice.speakQueued("Please tell me the timer length.");
      return true;
    }

    final work = parsed.workMinutes ?? parsed.simpleTimerMinutes ?? 0;
    final sets = parsed.sets ?? 1;
    final breaks = parsed.breakMinutes ?? 0;

    if (work <= 0 || sets <= 0) {
      await voice.speakQueued("I couldn't understand the duration.");
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
      setTabIndex(1);
    });

    return true;
  }

  // ---------------- STOP LISTENING ----------------
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