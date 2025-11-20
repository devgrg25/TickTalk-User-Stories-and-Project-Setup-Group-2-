// -------------------------------------------------------------
// VOICE ROUTER – STOPWATCH + TIMER + ROUTINES + NAVIGATION
// -------------------------------------------------------------

import 'dart:async';

import '../logic/timer/timer_controller.dart';
import '../logic/timer/timer_manager.dart';

import '../logic/voice/voice_stt_service.dart';
import '../logic/voice/voice_tts_service.dart';
import '../logic/voice/ai_interpreter.dart';
import '../logic/voice/ai_command.dart';

import '../logic/routines/routine_storage.dart';
import '../logic/routines/routine_model.dart';

// 🔥 NEW — import shared stopwatch controller
import '../logic/stopwatch/normal_stopwatch_shared_controller.dart';

typedef TabNavigator = void Function(int index);

class VoiceRouter {
  final TabNavigator onNavigateTab;
  final NormalStopwatchSharedController stopwatchController; // NEW!

  VoiceRouter({
    required this.onNavigateTab,
    required this.stopwatchController,
  });

  // -------------------------------------------------------------
  // ROUTINE BUILDER STATE (UNCHANGED)
  // -------------------------------------------------------------
  bool _isBuildingRoutine = false;
  String? _routineName;
  final List<TimerInterval> _routineSteps = [];

  // -------------------------------------------------------------
  // MAIN ENTRY
  // -------------------------------------------------------------
  Future<void> handle(String raw) async {
    final input = raw.toLowerCase().trim();
    if (input.isEmpty) return;

    print("🎤 VoiceRouter received: $raw");

    // -------------------------------------------------------------
    // 🔥 1. GLOBAL STOPWATCH COMMANDS (Highest Priority)
    // -------------------------------------------------------------
    if (await _handleStopwatchCommands(input)) return;

    // -------------------------------------------------------------
    // 2. Routine-building mode
    // -------------------------------------------------------------
    if (_isBuildingRoutine &&
        (input.contains("cancel") ||
            input.contains("never mind") ||
            input.contains("stop routine") ||
            input.contains("forget it"))) {
      return _cancelRoutineBuilder();
    }

    if (_isBuildingRoutine) return _handleRoutineBuilder(input);

    if (_detectRoutineStart(input)) return _startRoutineBuilder();

    // -------------------------------------------------------------
    // 3. Local timer controls
    // -------------------------------------------------------------
    if (await _handleLocalTimerControls(input)) return;

    // -------------------------------------------------------------
    // 4. Navigation
    // -------------------------------------------------------------
    if (await _handleNavigation(input)) return;

    // -------------------------------------------------------------
    // 5. BACKEND FALLBACK
    // -------------------------------------------------------------
    print("⚠ AI fallback triggered for: $raw");
    final ai = await AiInterpreter.interpret(raw);
    print("🌐 AI response: $ai");

    if (ai != null) return _executeAi(ai);

    return VoiceTtsService.instance.speak("Sorry, I cannot handle that yet.");
  }

  // -------------------------------------------------------------
  // 🔥 STOPWATCH COMMANDS (NORMAL STOPWATCH)
  // -------------------------------------------------------------
  Future<bool> _handleStopwatchCommands(String input) async {
    // OPEN STOPWATCH PAGE
    if (input.contains("open stopwatch") ||
        input.contains("go to stopwatch")) {
      onNavigateTab(5);
      await VoiceTtsService.instance.speak("Opening stopwatch.");
      return true;
    }

    // START
    if (input.contains("start") && input.contains("stopwatch")) {
      stopwatchController.start();
      await VoiceTtsService.instance.speak("Stopwatch started.");
      return true;
    }

    // PAUSE
    if (input.contains("pause stopwatch") ||
        input == "pause" ||
        input.contains("hold stopwatch")) {
      stopwatchController.pause();
      await VoiceTtsService.instance.speak("Paused.");
      return true;
    }

    // RESUME
    if (input.contains("resume stopwatch") ||
        input.contains("continue stopwatch") ||
        input == "resume" ||
        input == "continue") {
      stopwatchController.resume();
      await VoiceTtsService.instance.speak("Resumed.");
      return true;
    }

    // LAP
    if (input.contains("lap") ||
        input.contains("add lap") ||
        input.contains("mark lap")) {
      stopwatchController.lap();
      await VoiceTtsService.instance.speak("Lap recorded.");
      return true;
    }

    // STOP + GO TO SUMMARY
    if (input.contains("stop stopwatch") ||
        (input.contains("stop") && stopwatchController.isRunning)) {

      final total = stopwatchController.elapsed;
      final laps = List<Duration>.from(stopwatchController.laps);

      stopwatchController.stop();
      stopwatchController.reset();

      // OPEN SUMMARY PAGE
      onNavigateTab(6);

      VoiceTtsService.instance.speak("Stopwatch stopped. Showing summary.");
      return true;
    }

    // RESET
    if (input.contains("reset stopwatch") ||
        input == "reset") {
      stopwatchController.reset();
      await VoiceTtsService.instance.speak("Stopwatch reset.");
      return true;
    }

    return false;
  }

  // -------------------------------------------------------------
  // LOCAL TIMER CONTROLS (UNCHANGED)
  // -------------------------------------------------------------
  ActiveTimer? _findTimerByName(String query) {
    final timers = TimerManager.instance.timers;
    query = query.toLowerCase().trim();

    for (final t in timers) {
      if (t.name.toLowerCase() == query) return t;
    }

    for (final t in timers) {
      if (t.name.toLowerCase().contains(query)) return t;
    }

    return null;
  }

  Future<bool> _handleLocalTimerControls(String input) async {
    final timers = TimerManager.instance.timers;

    if (timers.isEmpty) return false;

    for (final t in timers) {
      final name = t.name.toLowerCase();

      if (input.contains("pause") && input.contains(name)) {
        t.controller.pause();
        await VoiceTtsService.instance.speak("Paused ${t.name}.");
        return true;
      }

      if ((input.contains("resume") || input.contains("continue")) &&
          input.contains(name)) {
        t.controller.resume();
        await VoiceTtsService.instance.speak("Resuming ${t.name}.");
        return true;
      }

      if ((input.contains("stop") || input.contains("cancel")) &&
          input.contains(name)) {
        TimerManager.instance.stopTimer(t.id);
        await VoiceTtsService.instance.speak("Stopped ${t.name}.");
        return true;
      }
    }

    final active = timers.last;

    if (input.contains("pause")) {
      active.controller.pause();
      await VoiceTtsService.instance.speak("Timer paused.");
      return true;
    }

    if (input.contains("resume") || input.contains("continue")) {
      active.controller.resume();
      await VoiceTtsService.instance.speak("Resuming timer.");
      return true;
    }

    if (input.contains("stop") || input.contains("cancel timer")) {
      TimerManager.instance.stopTimer(active.id);
      await VoiceTtsService.instance.speak("Timer stopped.");
      return true;
    }

    return false;
  }

  // -------------------------------------------------------------
  // ROUTINE BUILDER FUNCTIONS (UNCHANGED)
  // -------------------------------------------------------------
  bool _detectRoutineStart(String input) {
    return input.contains("create routine") ||
        input.contains("build routine") ||
        input.contains("make a routine") ||
        input.contains("new routine");
  }

  Future<void> _startRoutineBuilder() async {
    _isBuildingRoutine = true;
    _routineName = null;
    _routineSteps.clear();

    return VoiceTtsService.instance.speak(
      "Okay, let's build a new routine. What should I call it?",
    );
  }

  Future<void> _cancelRoutineBuilder() async {
    _isBuildingRoutine = false;
    _routineName = null;
    _routineSteps.clear();
    return VoiceTtsService.instance.speak("Routine setup canceled.");
  }

  Future<void> _handleRoutineBuilder(String text) async {
    if (_routineName == null) {
      _routineName = _cleanLabel(text);
      return VoiceTtsService.instance.speak("Great. What is the first step?");
    }

    if (text.contains("done") ||
        text.contains("finished") ||
        text.contains("no more")) {
      return _finishRoutineBuilder();
    }

    return _addRoutineStep(text);
  }

  Future<void> _addRoutineStep(String text) async {
    final duration = _extractDuration(text);
    if (duration == null) {
      return VoiceTtsService.instance
          .speak("I couldn't detect the duration. Please say it again.");
    }

    String label = _cleanLabel(text);
    if (label.isEmpty) label = "Interval";

    int rounds = 1;
    final wantsRounds =
    await _askYesNo("Would you like this step to repeat multiple rounds?");
    if (wantsRounds == true) {
      rounds = await _askForNumber("How many rounds?");
    }

    int? rest = null;
    if (rounds > 1) {
      final wantsRest =
      await _askYesNo("Should I add rest between each round?");
      if (wantsRest == true) rest = await _askForDuration("How long is the rest?");
    }

    for (int i = 0; i < rounds; i++) {
      _routineSteps.add(TimerInterval(name: label, seconds: duration));
      if (rest != null && i < rounds - 1) {
        _routineSteps.add(TimerInterval(name: "Rest", seconds: rest));
      }
    }

    return VoiceTtsService.instance.speak("Step added. What comes next?");
  }

  Future<void> _finishRoutineBuilder() async {
    if (_routineSteps.isEmpty) {
      _isBuildingRoutine = false;
      return VoiceTtsService.instance
          .speak("No steps were added. Routine discarded.");
    }

    await VoiceTtsService.instance
        .speak("Would you like me to save this routine?");
    final save = await _askYesNo(null);

    if (save != true) {
      _isBuildingRoutine = false;
      return VoiceTtsService.instance.speak("Okay, I won't save it.");
    }

    final routine = Routine(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _routineName!,
      intervals: [..._routineSteps],
    );

    await RoutineStorage.instance.saveRoutine(routine);

    await VoiceTtsService.instance
        .speak("Saved! Would you like to start it now?");
    final start = await _askYesNo(null);

    if (start == true) {
      TimerManager.instance.startTimer(_routineName!, _routineSteps);
      await VoiceTtsService.instance.speak("Starting ${_routineName!} now.");
    }

    _isBuildingRoutine = false;
  }

  // -------------------------------------------------------------
  // BACKEND COMMAND EXECUTION — RESTORED + DELETE ADDED
  // -------------------------------------------------------------
  Future<void> _executeAi(AiCommand cmd) async {
    switch (cmd.type) {
    // ---------------------------------------------------------
// MULTI STEP ROUTINE (NEW)
// ---------------------------------------------------------
      case "start_multi_step_routine":
        final steps = cmd.steps;

        if (steps == null || steps.isEmpty) {
          await VoiceTtsService.instance.speak(
              "I couldn't detect multiple steps."
          );
          return;
        }

        final intervals = <TimerInterval>[];
        final summary = StringBuffer("Routine with: ");

        for (final s in steps) {
          intervals.add(TimerInterval(name: s.label, seconds: s.seconds));
          summary.write("${s.label} for ${_spokenDuration(s.seconds)}, ");
        }

        await VoiceTtsService.instance.speak(summary.toString());

        // Ask to save
        await VoiceTtsService.instance.speak(
            "Would you like to save this routine?");
        final save = await _askYesNo(null);

        String routineName = "Custom Routine";

        if (save == true) {
          await VoiceTtsService.instance
              .speak("What should I call this routine?");
          final heard = await VoiceSttService.instance.listenOnce();
          if (heard != null && heard.trim().isNotEmpty) {
            routineName = heard.trim();
          }

          await RoutineStorage.instance.saveRoutine(
            Routine(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: routineName,
              intervals: intervals,
            ),
          );

          await VoiceTtsService.instance.speak("Saved as $routineName.");
        }

        // Start?
        await VoiceTtsService.instance.speak(
            "Should I start this routine now?");
        final start = await _askYesNo(null);

        if (start == true) {
          TimerManager.instance.startTimer(routineName, intervals);
          await VoiceTtsService.instance
              .speak("Starting routine now.");
        } else {
          await VoiceTtsService.instance
              .speak("Okay, not starting.");
        }

        return;


    // ---------------------------------------------------------
    // START TIMER
    // ---------------------------------------------------------
      case "start_timer":
        final sec = cmd.seconds ?? 0;
        final label = cmd.label ?? "Timer";

        // Speak summary
        await VoiceTtsService.instance.speak(
            "$label for ${_spokenDuration(sec)}. Starting now.");

        // Immediately start without asking to save
        TimerManager.instance.startTimer(
          label,
          [TimerInterval(name: label, seconds: sec)],
        );

        return;

    // ---------------------------------------------------------
    // START INTERVAL TIMER (WORK / REST / ROUNDS)
    // ---------------------------------------------------------
      case "start_interval_timer":
        final label2 = cmd.label ?? "Interval";
        final work = cmd.workSeconds ?? 60;
        final rest = cmd.restSeconds ?? 10;
        final rounds = cmd.rounds ?? 4;

        final intervals = <TimerInterval>[];
        for (int i = 0; i < rounds; i++) {
          intervals.add(TimerInterval(name: "$label2 Work", seconds: work));
          if (i < rounds - 1) {
            intervals.add(TimerInterval(name: "$label2 Rest", seconds: rest));
          }
        }

        await VoiceTtsService.instance.speak(
            "$rounds rounds of ${_spokenDuration(work)} work and ${_spokenDuration(rest)} rest.");

        await VoiceTtsService.instance.speak(
            "Would you like to save this interval routine?");

        final save2 = await _askYesNo(null);

        if (save2 == true) {
          final routine = Routine(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: label2,
            intervals: intervals,
          );
          await RoutineStorage.instance.saveRoutine(routine);
          await VoiceTtsService.instance.speak("Saved to routines.");
        }

        await VoiceTtsService.instance.speak("Should I start this routine now?");
        final startNow2 = await _askYesNo(null);

        if (startNow2 == true) {
          TimerManager.instance.startTimer(label2, intervals);
          await VoiceTtsService.instance.speak("Starting $label2.");
        }

        return;

    // ---------------------------------------------------------
    // PAUSE/RESUME/STOP
    // ---------------------------------------------------------
      case "pause_timer":
        final p = TimerManager.instance.timers.isNotEmpty
            ? TimerManager.instance.timers.last
            : null;
        if (p != null) p.controller.pause();
        await VoiceTtsService.instance.speak("Timer paused.");
        return;

      case "resume_timer":
        final r = TimerManager.instance.timers.isNotEmpty
            ? TimerManager.instance.timers.last
            : null;
        if (r != null) r.controller.resume();
        await VoiceTtsService.instance.speak("Resuming timer.");
        return;

      case "stop_timer":
        final s = TimerManager.instance.timers.isNotEmpty
            ? TimerManager.instance.timers.last
            : null;
        if (s != null) TimerManager.instance.stopTimer(s.id);
        await VoiceTtsService.instance.speak("Timer stopped.");
        return;

    // ---------------------------------------------------------
    // NAVIGATION
    // ---------------------------------------------------------
      case "navigate":
        if (cmd.target != null) {
          await _handleNavigation(cmd.target!.toLowerCase());
        }
        return;

    // ---------------------------------------------------------
    // START ROUTINE
    // ---------------------------------------------------------
      case "start_routine":
        final query = cmd.routineName?.toLowerCase().trim();
        if (query == null || query.isEmpty) {
          await VoiceTtsService.instance.speak(
              "Which routine would you like to start?");
          return;
        }

        final routines = await RoutineStorage.instance.loadRoutines();
        Routine? match;
        for (final r in routines) {
          final n = r.name.toLowerCase();
          if (n == query || n.contains(query)) match = r;
        }

        if (match == null) {
          await VoiceTtsService.instance.speak("I couldn't find $query.");
          return;
        }

        TimerManager.instance.startTimer(match.name, match.intervals);

        await VoiceTtsService.instance.speak("Starting ${match.name}.");
        return;

    // ---------------------------------------------------------
    // LIST ROUTINES
    // ---------------------------------------------------------
      case "list_routines":
        final list = await RoutineStorage.instance.loadRoutines();
        if (list.isEmpty) {
          await VoiceTtsService.instance.speak(
              "You have no routines saved.");
          return;
        }

        await VoiceTtsService.instance.speak(
          "Your routines are: ${list.map((r) => r.name).join(", ")}.",
        );
        return;

    // ---------------------------------------------------------
    // PREVIEW ROUTINE
    // ---------------------------------------------------------
      case "preview_routine":
        final query2 = cmd.routineName?.trim().toLowerCase();
        if (query2 == null || query2.isEmpty) {
          await VoiceTtsService.instance.speak(
              "Which routine should I preview?");
          return;
        }

        final rl = await RoutineStorage.instance.loadRoutines();
        Routine? match2;
        for (final r in rl) {
          final n = r.name.toLowerCase();
          if (n == query2 || n.contains(query2)) match2 = r;
        }

        if (match2 == null) {
          await VoiceTtsService.instance.speak("I couldn't find $query2.");
          return;
        }

        final buf = StringBuffer();
        for (final step in match2.intervals) {
          final mins = step.seconds ~/ 60;
          final secs = step.seconds % 60;
          if (mins > 0 && secs > 0)
            buf.write("${step.name} for $mins minutes $secs seconds, ");
          else if (mins > 0)
            buf.write("${step.name} for $mins minutes, ");
          else
            buf.write("${step.name} for $secs seconds, ");
        }

        await VoiceTtsService.instance.speak(
          "Steps in ${match2.name}: ${buf.toString()}",
        );
        return;

    // ---------------------------------------------------------
    // 🚀 ADDED: DELETE ROUTINE
    // ---------------------------------------------------------
      case "delete_routine":
        final delName = cmd.routineName?.toLowerCase().trim();

        if (delName == null || delName.isEmpty) {
          await VoiceTtsService.instance.speak(
            "Which routine should I delete?",
          );
          return;
        }

        final routinesDel = await RoutineStorage.instance.loadRoutines();

        Routine? toDelete;
        for (final r in routinesDel) {
          final n = r.name.toLowerCase();
          if (n == delName || n.contains(delName)) {
            toDelete = r;
            break;
          }
        }

        if (toDelete == null) {
          await VoiceTtsService.instance.speak("I couldn't find $delName.");
          return;
        }

        await VoiceTtsService.instance.speak(
            "Are you sure you want to delete ${toDelete.name}?");
        final confirm = await _askYesNo(null);

        if (confirm == true) {
          await RoutineStorage.instance.deleteRoutine(toDelete.id);
          await VoiceTtsService.instance
              .speak("Deleted ${toDelete.name}.");
        } else {
          await VoiceTtsService.instance.speak("Okay, I won't delete it.");
        }

        return;

    // ---------------------------------------------------------
    // ---------------------------------------------------------
    // MULTI-STEP ROUTINE FROM BACKEND
    // ---------------------------------------------------------
      case "start_multi_step_routine":
        final steps = cmd.steps;
        if (steps == null || steps.isEmpty) {
          await VoiceTtsService.instance.speak(
            "I couldn’t understand the routine steps.",
          );
          return;
        }

        // Build timer intervals from backend steps
        final intervals = <TimerInterval>[];
        for (final s in steps) {
          intervals.add(
            TimerInterval(name: s.label, seconds: s.seconds),
          );
        }

        // Routine name (backend label OR joined step labels)
        final routineName = cmd.label ??
            steps.map((s) => s.label).join(" + ");

        // 1. Speak summary
        await VoiceTtsService.instance.speak(
          "I created a routine with ${steps.length} steps.",
        );

        // 2. Ask to save
        await VoiceTtsService.instance.speak(
            "Would you like me to save this routine?");
        final save = await _askYesNo(null);

        if (save == true) {
          final routine = Routine(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: routineName,
            intervals: intervals,
          );

          await RoutineStorage.instance.saveRoutine(routine);
          await VoiceTtsService.instance.speak(
              "Saved routine $routineName.");
        }

        // 3. Ask to start
        await VoiceTtsService.instance.speak(
            "Should I start this routine now?");
        final start = await _askYesNo(null);

        if (start == true) {
          TimerManager.instance.startTimer(routineName, intervals);
          await VoiceTtsService.instance.speak(
              "Starting routine $routineName.");
        }

        return;
    // ---------------------------------------------------------
    // RENAME ROUTINE
    // ---------------------------------------------------------
      case "rename_routine":
        final oldName = cmd.oldName?.toLowerCase().trim();
        final newName = cmd.newName?.trim();

        if (oldName == null || oldName.isEmpty || newName == null || newName.isEmpty) {
          await VoiceTtsService.instance.speak(
            "I need both the old name and the new name to rename a routine.",
          );
          return;
        }

        final routines = await RoutineStorage.instance.loadRoutines();

        Routine? match;
        for (final r in routines) {
          final n = r.name.toLowerCase();
          if (n == oldName || n.contains(oldName)) {
            match = r;
            break;
          }
        }

        if (match == null) {
          await VoiceTtsService.instance.speak("I couldn't find a routine called $oldName.");
          return;
        }

        // Update name
        final updated = Routine(
          id: match.id,
          name: newName,
          intervals: match.intervals,
        );

        await RoutineStorage.instance.updateRoutine(updated);

        await VoiceTtsService.instance.speak(
          "Okay, I renamed $oldName to $newName.",
        );

        return;

      default:
        await VoiceTtsService.instance.speak(
          "Sorry, I cannot handle that yet.",
        );
        return;
    }
  }

  // -------------------------------------------------------------
  // NAVIGATION (UNCHANGED)
  // -------------------------------------------------------------
  Future<bool> _handleNavigation(String input) async {
    if (input.contains("home")) {
      onNavigateTab(0);
      await VoiceTtsService.instance.speak("Opening home.");
      return true;
    }
    if (input.contains("go to timer")) {
      onNavigateTab(1);
      await VoiceTtsService.instance.speak("Opening timer.");
      return true;
    }
    if (input.contains("go to routine") ||
        input.contains("go to routines")) {
      onNavigateTab(2);
      await VoiceTtsService.instance.speak("Opening routines.");
      return true;
    }
    if (input.contains("settings")) {
      onNavigateTab(3);
      await VoiceTtsService.instance.speak("Opening settings.");
      return true;
    }

    return false;
  }

  // -------------------------------------------------------------
  // ASK HELPERS (UNCHANGED)
  // -------------------------------------------------------------
  Future<bool?> _askYesNo(String? prompt) async {
    if (prompt != null) {
      await VoiceTtsService.instance.speak(prompt);
    }
    return await VoiceSttService.instance.listenForConfirmation();
  }

  Future<int> _askForNumber(String prompt) async {
    while (true) {
      await VoiceTtsService.instance.speak(prompt);
      final heard = await VoiceSttService.instance.listenOnce();
      if (heard == null) continue;

      final n = int.tryParse(heard.replaceAll(RegExp(r'[^0-9]'), ""));
      if (n != null && n > 0) return n;

      await VoiceTtsService.instance.speak("I didn't catch a number.");
    }
  }

  Future<int> _askForDuration(String prompt) async {
    while (true) {
      await VoiceTtsService.instance.speak(prompt);
      final heard = await VoiceSttService.instance.listenOnce();
      if (heard == null) continue;

      final d = _extractDuration(heard);
      if (d != null) return d;

      await VoiceTtsService.instance
          .speak("I didn't catch the duration.");
    }
  }

  // -------------------------------------------------------------
  // TEXT HELPERS (UNCHANGED)
  // -------------------------------------------------------------
  String _cleanLabel(String raw) {
    String t = raw.toLowerCase();

    final remove = [
      "start", "timer", "countdown", "for", "a", "an", "the", "please",
      "i want", "i would like", "seconds", "second", "minutes", "minute",
      "hours", "hour", "set", "sets", "round", "rounds", "work", "rest",
    ];

    for (final w in remove) {
      t = t.replaceAll(w, "");
    }

    t = t.replaceAll(RegExp(r'\b\d+\b'), "").trim();

    if (t.isEmpty) return "";

    return t.split(" ")
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(" ");
  }

  int? _extractDuration(String input) {
    final sec = RegExp(r'(\d+)\s*(sec|secs|second|seconds)\b',
        caseSensitive: false)
        .firstMatch(input);
    if (sec != null) return int.parse(sec.group(1)!);

    final min = RegExp(r'(\d+)\s*(min|mins|minute|minutes)\b',
        caseSensitive: false)
        .firstMatch(input);
    if (min != null) return int.parse(min.group(1)!) * 60;

    final hr = RegExp(r'(\d+)\s*(hr|hrs|hour|hours)\b',
        caseSensitive: false)
        .firstMatch(input);
    if (hr != null) return int.parse(hr.group(1)!) * 3600;

    return null;
  }

  String _spokenDuration(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;

    if (h > 0) {
      if (m > 0) return "$h hours and $m minutes";
      return "$h hours";
    }

    if (m > 0) {
      if (s > 0) return "$m minutes and $s seconds";
      return "$m minutes";
    }

    return "$s seconds";
  }
}
