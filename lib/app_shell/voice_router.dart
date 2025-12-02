// -------------------------------------------------------------
// VOICE ROUTER – CLEAN REWRITTEN VERSION (NO LOGIC CHANGES)
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
import '../logic/stopwatch/player_mode_manager.dart';
import '../logic/stopwatch/normal_stopwatch_shared_controller.dart';

typedef TabNavigator = void Function(int index);

class VoiceRouter {
  final TabNavigator onNavigateTab;
  final NormalStopwatchSharedController stopwatchController;
  final void Function(Duration total, List<Duration> laps) onShowSummary;

  VoiceRouter({
    required this.onNavigateTab,
    required this.stopwatchController,
    required this.onShowSummary,
  });

  // -------------------------------------------------------------
  // SUMMARY STATE
  // -------------------------------------------------------------
  Duration? summaryTotal;
  List<Duration>? summaryLaps;

  void setSummary(Duration total, List<Duration> laps) {
    summaryTotal = total;
    summaryLaps = laps;
  }

  void clearSummary() {
    summaryTotal = null;
    summaryLaps = null;
  }

  // -------------------------------------------------------------
  // ROUTINE BUILDER STATE (LEGACY)
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

    // 1. Stopwatch local commands
    if (await _handleStopwatchCommands(input)) return;

    // 2. Legacy routine builder
    if (_isBuildingRoutine && _cancelsRoutine(input)) {
      return _cancelRoutineBuilder();
    }
    if (_isBuildingRoutine) return _handleRoutineBuilder(input);
    if (_detectRoutineStart(input)) return _startRoutineBuilder();

    // 3. Local timers (pause / resume / stop)
    if (await _handleLocalTimerControls(input)) return;

    // 4. Navigation
    if (await _handleNavigation(input)) return;

    // 5. Summary mode backend queries
    if (summaryTotal != null && summaryLaps != null) {
      if (await _handleSummaryCommands(input)) return;
    }

    // 6. Backend fallback (AI)
    final ai = await AiInterpreter.interpret(raw);
    if (ai != null) return _executeAi(ai);

    return VoiceTtsService.instance.speak("Sorry, I cannot handle that yet.");
  }

  // -------------------------------------------------------------
  // STOPWATCH COMMANDS
  // -------------------------------------------------------------
  Future<bool> _handleStopwatchCommands(String input) async {
    // Open
    if (input.contains("open stopwatch") ||
        input.contains("go to stopwatch")) {
      onNavigateTab(5);
      await VoiceTtsService.instance.speak("Opening stopwatch.");
      return true;
    }

    // Start
    if (input.contains("start") && input.contains("stopwatch")) {
      stopwatchController.start();
      await VoiceTtsService.instance.speak("Stopwatch started.");
      return true;
    }

    // Pause
    if (input.contains("pause stopwatch") || input == "pause") {
      stopwatchController.pause();
      await VoiceTtsService.instance.speak("Paused.");
      return true;
    }

    // Resume
    if (input.contains("resume stopwatch") ||
        input == "resume" ||
        input == "continue") {
      stopwatchController.resume();
      await VoiceTtsService.instance.speak("Resumed.");
      return true;
    }

    // Lap
    if (_isLapCommand(input)) {
      stopwatchController.lap();
      await VoiceTtsService.instance.speak("Lap recorded.");
      return true;
    }

    // Stop
    if (input.contains("stop stopwatch") ||
        (input.contains("stop") && stopwatchController.isRunning)) {
      final total = stopwatchController.elapsed;
      final laps = List<Duration>.from(stopwatchController.laps);

      stopwatchController.stop();
      stopwatchController.reset();

      onShowSummary(total, laps);

      await VoiceTtsService.instance
          .speak("Stopwatch stopped. Total time was ${_spokenDurationFromDuration(total)}.");

      if (laps.isEmpty) {
        await VoiceTtsService.instance.speak("No laps recorded.");
      } else {
        for (int i = 0; i < laps.length; i++) {
          await VoiceTtsService.instance.speak(
            "Lap ${i + 1}: ${_spokenDurationFromDuration(laps[i])}.",
          );
        }
      }
      return true;
    }

    // Reset
    if (input.contains("reset stopwatch") || input == "reset") {
      stopwatchController.reset();
      await VoiceTtsService.instance.speak("Stopwatch reset.");
      return true;
    }

    return false;
  }

  // -------------------------------------------------------------
  // TIMER CONTROLS (LOCAL)
  // -------------------------------------------------------------
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
  // AI COMMAND EXECUTION (BACKEND)
  // -------------------------------------------------------------
  Future<void> _executeAi(AiCommand cmd) async {
    switch (cmd.type) {
    // ---------------------------------------------------------
    // Simple Timer
    // ---------------------------------------------------------
      case "start_timer":
        final sec = cmd.seconds ?? 0;
        final label = cmd.label ?? "Timer";

        await VoiceTtsService.instance.speak(
          "$label for ${_spokenDuration(sec)}. Starting now.",
        );

        TimerManager.instance.startTimer(
          label,
          [TimerInterval(name: label, seconds: sec)],
        );
        return;

    // ---------------------------------------------------------
    // Multi-step routine
    // ---------------------------------------------------------
      case "start_multi_step_routine":
        final steps = cmd.steps ?? [];
        if (steps.isEmpty) {
          await VoiceTtsService.instance.speak("I couldn't understand the steps.");
          return;
        }

        final intervals = steps
            .map((s) =>
            TimerInterval(name: s.label, seconds: s.seconds))
            .toList();

        final name = cmd.routineName ?? "Custom Routine";

        if (cmd.autoSave == true) {
          await RoutineStorage.instance.saveRoutine(
            Routine(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: name,
              intervals: intervals,
            ),
          );
          await VoiceTtsService.instance.speak("Saved routine $name.");
        }

        if (cmd.autoStart == true) {
          TimerManager.instance.startTimer(name, intervals);
          await VoiceTtsService.instance.speak("Starting $name now.");
          return;
        }

        // Manual save/start fallback
        await VoiceTtsService.instance
            .speak("Should I save this routine?");
        final save = await _askYesNo(null);

        if (save == true) {
          await RoutineStorage.instance.saveRoutine(
            Routine(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: name,
              intervals: intervals,
            ),
          );
          await VoiceTtsService.instance.speak("Saved.");
        }

        await VoiceTtsService.instance.speak("Should I start it?");
        final start = await _askYesNo(null);

        if (start == true) {
          TimerManager.instance.startTimer(name, intervals);
          await VoiceTtsService.instance.speak("Starting now.");
        }
        return;

    // ---------------------------------------------------------
    // Interval Timer
    // ---------------------------------------------------------
      case "start_interval_timer":
        final label2 =
        (cmd.routineName != null && cmd.routineName!.isNotEmpty)
            ? cmd.routineName!
            : (cmd.label ?? "Interval");

        final work = cmd.workSeconds ?? 60;
        final rest = cmd.restSeconds ?? 10;
        final rounds = cmd.rounds ?? 4;

        final intervals2 = <TimerInterval>[];
        for (int i = 0; i < rounds; i++) {
          intervals2.add(
            TimerInterval(name: "$label2 Work", seconds: work),
          );
          if (i < rounds - 1) {
            intervals2.add(
              TimerInterval(name: "$label2 Rest", seconds: rest),
            );
          }
        }

        await VoiceTtsService.instance.speak(
          "$rounds rounds of ${_spokenDuration(work)} work "
              "and ${_spokenDuration(rest)} rest.",
        );

        await VoiceTtsService.instance
            .speak("Would you like to save this routine?");
        final save2 = await _askYesNo(null);

        if (save2 == true) {
          await RoutineStorage.instance.saveRoutine(
            Routine(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: label2,
              intervals: intervals2,
            ),
          );
          await VoiceTtsService.instance.speak("Saved.");
        }

        await VoiceTtsService.instance.speak("Should I start it now?");
        final start2 = await _askYesNo(null);

        if (start2 == true) {
          TimerManager.instance.startTimer(label2, intervals2);
          await VoiceTtsService.instance.speak("Starting now.");
        }
        return;

    // ---------------------------------------------------------
    // Pause / Resume / Stop
    // ---------------------------------------------------------
      case "pause_timer":
        TimerManager.instance.timers.last.controller.pause();
        await VoiceTtsService.instance.speak("Timer paused.");
        return;

      case "resume_timer":
        TimerManager.instance.timers.last.controller.resume();
        await VoiceTtsService.instance.speak("Resuming timer.");
        return;

      case "stop_timer":
        if (TimerManager.instance.timers.isNotEmpty) {
          TimerManager.instance.stopTimer(
            TimerManager.instance.timers.last.id,
          );
        }
        await VoiceTtsService.instance.speak("Timer stopped.");
        return;

    // ---------------------------------------------------------
    // Navigation
    // ---------------------------------------------------------
      case "navigate":
        if (cmd.target != null) {
          await _handleNavigation(cmd.target!.toLowerCase());
        }
        return;

    // ---------------------------------------------------------
    // Start a saved routine
    // ---------------------------------------------------------
      case "start_routine":
        final query = cmd.routineName?.toLowerCase();
        if (query == null || query.isEmpty) {
          await VoiceTtsService.instance.speak(
            "Which routine would you like to start?",
          );
          return;
        }

        final routines = await RoutineStorage.instance.loadRoutines();
        Routine? match;

        for (final r in routines) {
          if (r.name.toLowerCase() == query ||
              r.name.toLowerCase().contains(query)) {
            match = r;
          }
        }

        if (match == null) {
          await VoiceTtsService.instance.speak("I couldn't find $query.");
          return;
        }

        TimerManager.instance.startTimer(match.name, match.intervals);
        await VoiceTtsService.instance.speak("Starting ${match.name}.");
        return;

    // ---------------------------------------------------------
    // List routines
    // ---------------------------------------------------------
      case "list_routines":
        final list = await RoutineStorage.instance.loadRoutines();
        if (list.isEmpty) {
          await VoiceTtsService.instance.speak("You have no routines saved.");
          return;
        }

        final names = list.map((r) => r.name).join(", ");
        await VoiceTtsService.instance.speak(
          "Your routines are: $names.",
        );
        return;

    // ---------------------------------------------------------
    // Preview routine
    // ---------------------------------------------------------
      case "preview_routine":
        final q = cmd.routineName?.trim().toLowerCase();
        if (q == null || q.isEmpty) {
          await VoiceTtsService.instance.speak(
            "Which routine should I preview?",
          );
          return;
        }

        final routines2 = await RoutineStorage.instance.loadRoutines();
        Routine? m2;

        for (final r in routines2) {
          if (r.name.toLowerCase() == q ||
              r.name.toLowerCase().contains(q)) {
            m2 = r;
          }
        }

        if (m2 == null) {
          await VoiceTtsService.instance.speak("I couldn't find $q.");
          return;
        }

        final summary = m2.intervals
            .map((s) => "${s.name} for ${_spokenDuration(s.seconds)}")
            .join(", ");

        await VoiceTtsService.instance.speak(
          "Steps in ${m2.name}: $summary",
        );
        return;

    // ---------------------------------------------------------
    // Delete routine
    // ---------------------------------------------------------
      case "delete_routine":
        final del = cmd.routineName?.toLowerCase();
        if (del == null || del.isEmpty) {
          await VoiceTtsService.instance.speak(
            "Which routine should I delete?",
          );
          return;
        }

        final routines3 = await RoutineStorage.instance.loadRoutines();
        Routine? toDelete;

        for (final r in routines3) {
          if (r.name.toLowerCase() == del ||
              r.name.toLowerCase().contains(del)) {
            toDelete = r;
          }
        }

        if (toDelete == null) {
          await VoiceTtsService.instance.speak("I couldn't find $del.");
          return;


        }

        await VoiceTtsService.instance.speak(
          "Are you sure you want to delete ${toDelete.name}?",
        );
        final confirm = await _askYesNo(null);

        if (confirm == true) {
          await RoutineStorage.instance.deleteRoutine(toDelete.id);
          await VoiceTtsService.instance.speak(
            "Deleted ${toDelete.name}.",
          );
        } else {
          await VoiceTtsService.instance.speak("Not deleted.");
        }
        return;

    // ---------------------------------------------------------
    // PLAYER MODE COMMANDS
    // ---------------------------------------------------------
      case "start_player":
        PlayerModeManager.instance.startPlayer(cmd.playerIndex!);
        break;

      case "pause_player":
        PlayerModeManager.instance.pausePlayer(cmd.playerIndex!);
        break;

      case "resume_player":
        PlayerModeManager.instance.resumePlayer(cmd.playerIndex!);
        break;

      case "lap_player":
        PlayerModeManager.instance.lapPlayer(cmd.playerIndex!);
        break;

      case "stop_player":
        PlayerModeManager.instance.stopPlayer(cmd.playerIndex!);
        break;

      case "start_all_players":
        PlayerModeManager.instance.startAll();
        break;

      case "stop_all_players":
        PlayerModeManager.instance.stopAll();
        break;

    // ---------------------------------------------------------
    // Rename routine
    // ---------------------------------------------------------
      case "rename_routine":
        final oldName = cmd.oldName?.toLowerCase();
        final newName = cmd.newName?.trim();

        if (oldName == null || oldName.isEmpty || newName == null || newName.isEmpty) {
          await VoiceTtsService.instance.speak(
            "I couldn't understand the routine name to rename.",
          );
          return;
        }

        final routines = await RoutineStorage.instance.loadRoutines();
        Routine? target;

        for (final r in routines) {
          if (r.name.toLowerCase() == oldName ||
              r.name.toLowerCase().contains(oldName)) {
            target = r;


            break;
          }
        }

        if (target == null) {
          await VoiceTtsService.instance.speak("I couldn't find $oldName.");
          return;
        }

        // Create updated routine
        final updated = Routine(
          id: target.id,
          name: newName,
          intervals: target.intervals,
        );

        await RoutineStorage.instance.saveRoutine(updated);
        await VoiceTtsService.instance
            .speak("Renamed $oldName to $newName.");
        return;


      default:
        await VoiceTtsService.instance.speak(
          "Sorry, I cannot handle that yet.",
        );
        return;
    }
  }

  // -------------------------------------------------------------
  // NAVIGATION
  // -------------------------------------------------------------
  Future<bool> _handleNavigation(String input) async {
    if (input.contains("home")) {
      onNavigateTab(0);
      await VoiceTtsService.instance.speak("Opening home.");
      return true;
    }

    if (input.contains("go to timer") ||
        input.contains("timer page")) {
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
  // YES/NO HELPER
  // -------------------------------------------------------------
  Future<bool?> _askYesNo(String? prompt) async {
    if (prompt != null) {
      await VoiceTtsService.instance.speak(prompt);
    }
    return await VoiceSttService.instance.listenForConfirmation();
  }

  // -------------------------------------------------------------
  // SUMMARY COMMAND HANDLER (BACKEND)
  // -------------------------------------------------------------
  Future<bool> _handleSummaryCommands(String input) async {
    final totalMs = summaryTotal!.inMilliseconds;
    final lapsMs = summaryLaps!.map((d) => d.inMilliseconds).toList();

    final cmd = await AiInterpreter.interpretSummary(
      rawText: input,
      totalMs: totalMs,
      lapsMs: lapsMs,
    );

    if (cmd == null) return false;

    switch (cmd.type) {
      case "summary_lap_time":
        final n = cmd.lapNumber!;
        if (n < 1 || n > summaryLaps!.length) {
          await VoiceTtsService.instance.speak(
              "You do not have lap $n.");
          return true;
        }
        await VoiceTtsService.instance.speak(
          "Lap $n was ${_spokenDuration(cmd.valueSeconds!.round())
          }.",
        );
        return true;

      case "summary_total_time":
        await VoiceTtsService.instance.speak(
          "Your total time was ${_spokenDuration(cmd.valueSeconds!.round())
          }.",
        );
        return true;

      case "summary_lap_count":
        await VoiceTtsService.instance.speak(
          "You recorded ${summaryLaps!.length} laps.",
        );
        return true;

      case "summary_fastest_lap":
        await VoiceTtsService.instance.speak(
          "Your fastest lap was lap ${cmd.lapNumber} at ${_spokenDuration(cmd.valueSeconds!.round())
          }.",
        );
        return true;

      case "summary_slowest_lap":
        await VoiceTtsService.instance.speak(
          "Your slowest lap was lap ${cmd.lapNumber} at ${_spokenDuration(cmd.valueSeconds!.round())
          }.",
        );
        return true;

      case "summary_average_lap":
        await VoiceTtsService.instance.speak(
          "Your average lap time was ${_spokenDuration(cmd.valueSeconds!.round())
          }.",
        );
        return true;

      case "summary_read_all":
        for (int i = 0; i < summaryLaps!.length; i++) {
          await VoiceTtsService.instance.speak(
            "Lap ${i + 1}: ${_spokenDuration(summaryLaps![i].inSeconds)}.",
          );
        }
        return true;
    }

    return false;
  }

  // -------------------------------------------------------------
  // SUPPORTING UTILITIES
  // -------------------------------------------------------------
  bool _cancelsRoutine(String input) {
    return input.contains("cancel") ||
        input.contains("never mind") ||
        input.contains("stop routine") ||
        input.contains("forget it");
  }

  bool _isLapCommand(String input) {
    input = input.trim().toLowerCase();

    if (!stopwatchController.isRunning) return false;

    final lapWords = [
      "lap",
      "lab",
      "left",
      "lat",
      "app",
      "flap",
      "clap",
      "add lap",
      "lap now",
      "mark lap",
      "new lap",
      "next lap",
      "lap please",
    ];

    if (lapWords.contains(input)) return true;
    if (lapWords.any((w) => input.contains(w))) return true;

    if (input.length <= 2 && input.startsWith("l")) return true;

    return false;
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

  String _spokenDurationFromDuration(Duration d) {
    final totalSec = d.inSeconds;
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;

    if (h > 0) {
      if (m > 0 && s > 0) return "$h hours $m minutes $s seconds";
      if (m > 0) return "$h hours $m minutes";
      if (s > 0) return "$h hours $s seconds";
      return "$h hours";
    }

    if (m > 0) {
      if (s > 0) return "$m minutes $s seconds";
      return "$m minutes";
    }

    return "$s seconds";
  }
  // -------------------------------------------------------------
  // LEGACY ROUTINE BUILDER (UNCHANGED FROM YOUR ORIGINAL)
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

    return VoiceTtsService.instance
        .speak("Okay, let's build a new routine. What should I call it?");
  }

  Future<void> _cancelRoutineBuilder() async {
    _isBuildingRoutine = false;
    _routineName = null;
    _routineSteps.clear();
    return VoiceTtsService.instance.speak("Routine setup canceled.");
  }

  Future<void> _handleRoutineBuilder(String text) async {
    if (_routineName == null) {
      _routineName = text.trim();
      return VoiceTtsService.instance
          .speak("Great. What is the first step?");
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

    final label = text.trim();
    _routineSteps.add(TimerInterval(name: label, seconds: duration));

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

    if (save == true) {
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
        await VoiceTtsService.instance
            .speak("Starting ${_routineName!} now.");
      }
    }

    _isBuildingRoutine = false;
  }
  // -------------------------------------------------------------
  // TIME PARSER – required for legacy routine builder
  // -------------------------------------------------------------
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

}
