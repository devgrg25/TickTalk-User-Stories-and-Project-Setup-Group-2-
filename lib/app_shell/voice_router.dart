// -------------------------------------------------------------
// VOICE ROUTER – UPDATED VERSION (LOCAL TIMER CREATION REMOVED)
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

typedef TabNavigator = void Function(int index);

class VoiceRouter {
  VoiceRouter({required this.onNavigateTab});
  final TabNavigator onNavigateTab;

  // -------------------------------------------------------------
  // ROUTINE BUILDER STATE (LOCAL)
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

    // Cancel routine builder
    if (_isBuildingRoutine &&
        (input.contains("cancel") ||
            input.contains("never mind") ||
            input.contains("stop routine") ||
            input.contains("forget it"))) {
      return _cancelRoutineBuilder();
    }

    // Continue routine builder
    if (_isBuildingRoutine) return _handleRoutineBuilder(input);

    // Start local routine builder
    if (_detectRoutineStart(input)) return _startRoutineBuilder();

    // Local timer controls (pause/resume/stop ONLY)
    if (await _handleLocalTimerControls(input)) return;

    // ⛔ REMOVED: Local quick timer creation logic
    // (Previously: if (_handleLocalQuickTimer) return;)

    // Navigation
    if (await _handleNavigation(input)) return;

    // -------------------------------------------------------------
    // BACKEND FALLBACK
    // -------------------------------------------------------------
    print("⚠ AI fallback triggered for: $raw");
    final ai = await AiInterpreter.interpret(raw);
    print("🌐 AI response: $ai");

    if (ai != null) return _executeAi(ai);

    return VoiceTtsService.instance.speak("Sorry, I cannot handle that yet.");
  }

  // -------------------------------------------------------------
  // ROUTINE BUILDER (NO CHANGE)
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
  // LOCAL TIMER CONTROLS (PAUSE/RESUME/STOP ONLY)
  // -------------------------------------------------------------
  ActiveTimer? _findTimerByName(String query) {
    final timers = TimerManager.instance.timers;
    query = query.toLowerCase().trim();

    // Exact match
    for (final t in timers) {
      if (t.name.toLowerCase() == query) return t;
    }

    // Partial match
    for (final t in timers) {
      if (t.name.toLowerCase().contains(query)) return t;
    }

    return null;
  }

  Future<bool> _handleLocalTimerControls(String input) async {
    final timers = TimerManager.instance.timers;

    if (timers.isEmpty) return false;

    // Try to match "pause X timer", "stop Y", "resume study timer"
    for (final t in timers) {
      final name = t.name.toLowerCase();

      // PAUSE SPECIFIC
      if (input.contains("pause") && input.contains(name)) {
        t.controller.pause();
        await VoiceTtsService.instance.speak("Paused ${t.name}.");
        return true;
      }

      // RESUME SPECIFIC
      if ((input.contains("resume") || input.contains("continue")) &&
          input.contains(name)) {
        t.controller.resume();
        await VoiceTtsService.instance.speak("Resuming ${t.name}.");
        return true;
      }

      // STOP SPECIFIC
      if ((input.contains("stop") || input.contains("cancel")) &&
          input.contains(name)) {
        TimerManager.instance.stopTimer(t.id);
        await VoiceTtsService.instance.speak("Stopped ${t.name}.");
        return true;
      }
    }

    // FALLBACK — acts on last active timer
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
  // BACKEND COMMAND EXECUTION (UNCHANGED)
  // -------------------------------------------------------------
  Future<void> _executeAi(AiCommand cmd) async {
    switch (cmd.type) {
      case "start_timer":
        final sec = cmd.seconds ?? 0;
        final label = cmd.label ?? "Timer";

        TimerManager.instance.startTimer(
            label, [TimerInterval(name: label, seconds: sec)]);
        await VoiceTtsService.instance
            .speak("Starting $label for ${_spokenDuration(sec)}.");
        break;

      case "start_interval_timer":
        final label2 = cmd.label ?? "Interval";
        final w = cmd.workSeconds ?? 60;
        final r = cmd.restSeconds ?? 10;
        final rounds = cmd.rounds ?? 4;

        final intervals = <TimerInterval>[];
        for (int i = 0; i < rounds; i++) {
          intervals.add(TimerInterval(name: "$label2 Work", seconds: w));
          if (i < rounds - 1) {
            intervals.add(TimerInterval(name: "$label2 Rest", seconds: r));
          }
        }

        await VoiceTtsService.instance.speak(
            "$rounds rounds of ${w ~/ 60 > 0 ? "${w ~/ 60} minute work" : "$w seconds work"} "
                "and ${r ~/ 60 > 0 ? "${r ~/ 60} minute rest" : "$r seconds rest"}.");

        await VoiceTtsService.instance.speak("Save this routine?");
        final save = await _askYesNo(null);

        if (save == true) {
          final routine = Routine(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: label2,
            intervals: intervals,
          );
          await RoutineStorage.instance.saveRoutine(routine);
          await VoiceTtsService.instance.speak("Saved.");
        }

        await VoiceTtsService.instance.speak("Start it now?");
        final start = await _askYesNo(null);

        if (start == true) {
          TimerManager.instance.startTimer(label2, intervals);
          await VoiceTtsService.instance.speak("Starting $label2.");
        }

        break;

      case "pause_timer":
        final active1 = TimerManager.instance.timers.isNotEmpty
            ? TimerManager.instance.timers.last
            : null;
        if (active1 != null) active1.controller.pause();
        await VoiceTtsService.instance.speak("Timer paused.");
        break;

      case "resume_timer":
        final active2 = TimerManager.instance.timers.isNotEmpty
            ? TimerManager.instance.timers.last
            : null;
        if (active2 != null) active2.controller.resume();
        await VoiceTtsService.instance.speak("Resuming.");
        break;

      case "stop_timer":
        final active3 = TimerManager.instance.timers.isNotEmpty
            ? TimerManager.instance.timers.last
            : null;
        if (active3 != null) {
          TimerManager.instance.stopTimer(active3.id);
        }
        await VoiceTtsService.instance.speak("Timer stopped.");
        break;

      case "start_routine":
        final qStart = cmd.routineName?.trim().toLowerCase();
        if (qStart == null || qStart.isEmpty) {
          await VoiceTtsService.instance
              .speak("Which routine would you like to start?");
          break;
        }

        final all = await RoutineStorage.instance.loadRoutines();

        Routine? found;
        for (final r in all) {
          final n = r.name.toLowerCase();
          if (n == qStart || n.contains(qStart)) found = r;
        }

        if (found == null) {
          await VoiceTtsService.instance.speak("No routine named $qStart.");
          break;
        }

        TimerManager.instance.startTimer(found.name, found.intervals);
        await VoiceTtsService.instance
            .speak("Starting routine ${found.name}.");
        break;

      case "list_routines":
        final routines = await RoutineStorage.instance.loadRoutines();
        if (routines.isEmpty) {
          await VoiceTtsService.instance
              .speak("You don't have any routines saved.");
          break;
        }
        final names = routines.map((e) => e.name).join(", ");
        await VoiceTtsService.instance.speak("Your routines are: $names.");
        break;

      case "preview_routine":
        final qPrev = cmd.routineName?.trim().toLowerCase();
        if (qPrev == null || qPrev.isEmpty) {
          await VoiceTtsService.instance
              .speak("Which routine would you like to preview?");
          break;
        }

        final routinesP = await RoutineStorage.instance.loadRoutines();
        Routine? foundP;
        for (final r in routinesP) {
          final n = r.name.toLowerCase();
          if (n == qPrev || n.contains(qPrev)) foundP = r;
        }

        if (foundP == null) {
          await VoiceTtsService.instance.speak("I couldn't find $qPrev.");
          break;
        }

        final buf = StringBuffer();
        for (final step in foundP.intervals) {
          final mins = step.seconds ~/ 60;
          final secs = step.seconds % 60;
          if (mins > 0 && secs > 0)
            buf.write("${step.name} for $mins minutes $secs seconds, ");
          else if (mins > 0)
            buf.write("${step.name} for $mins minutes, ");
          else
            buf.write("${step.name} for $secs seconds, ");
        }

        await VoiceTtsService.instance
            .speak("Steps in ${foundP.name}: ${buf.toString()}");
        break;

      case "delete_routine":
        final qDel = cmd.routineName?.trim().toLowerCase();
        if (qDel == null || qDel.isEmpty) {
          await VoiceTtsService.instance
              .speak("Which routine should I delete?");
          break;
        }

        final routinesD = await RoutineStorage.instance.loadRoutines();
        Routine? foundD;
        for (final r in routinesD) {
          if (r.name.toLowerCase() == qDel ||
              r.name.toLowerCase().contains(qDel)) {
            foundD = r;
            break;
          }
        }

        if (foundD == null) {
          await VoiceTtsService.instance
              .speak("I couldn't find routine $qDel.");
          break;
        }

        await RoutineStorage.instance.deleteRoutine(foundD.id);
        await VoiceTtsService.instance
            .speak("Deleted routine ${foundD.name}.");
        break;

      case "rename_routine":
        final oldName = cmd.oldName?.trim().toLowerCase();
        final newName = cmd.newName?.trim();

        if (oldName == null || newName == null || newName.isEmpty) {
          await VoiceTtsService.instance
              .speak("I need both the old and new routine names.");
          break;
        }

        final routinesR = await RoutineStorage.instance.loadRoutines();
        Routine? foundR;
        for (final r in routinesR) {
          if (r.name.toLowerCase() == oldName ||
              r.name.toLowerCase().contains(oldName)) {
            foundR = r;
            break;
          }
        }

        if (foundR == null) {
          await VoiceTtsService.instance
              .speak("I couldn't find routine $oldName.");
          break;
        }

        final updated = Routine(
          id: foundR.id,
          name: newName,
          intervals: foundR.intervals,
        );

        await RoutineStorage.instance.saveRoutine(updated);
        await VoiceTtsService.instance
            .speak("Renamed ${foundR.name} to $newName.");
        break;

      case "edit_routine":
        final qEdit = cmd.routineName?.trim().toLowerCase();
        if (qEdit == null || qEdit.isEmpty) {
          await VoiceTtsService.instance
              .speak("Which routine would you like to edit?");
          break;
        }

        final routinesE = await RoutineStorage.instance.loadRoutines();
        Routine? foundE;
        for (final r in routinesE) {
          if (r.name.toLowerCase() == qEdit ||
              r.name.toLowerCase().contains(qEdit)) {
            foundE = r;
            break;
          }
        }

        if (foundE == null) {
          await VoiceTtsService.instance
              .speak("I couldn't find routine $qEdit.");
          break;
        }

        final bufE = StringBuffer();
        for (final step in foundE.intervals) {
          final mins = step.seconds ~/ 60;
          final secs = step.seconds % 60;
          if (mins > 0 && secs > 0)
            bufE.write("${step.name} for $mins minutes $secs seconds, ");
          else if (mins > 0)
            bufE.write("${step.name} for $mins minutes, ");
          else
            bufE.write("${step.name} for $secs seconds, ");
        }

        await VoiceTtsService.instance.speak(
          "Here are the steps in ${foundE.name}: ${bufE.toString()}",
        );
        await VoiceTtsService.instance
            .speak("Editing is coming soon. What else would you like?");
        break;

      default:
        await VoiceTtsService.instance.speak(
          "Sorry, I cannot handle that yet.",
        );
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
      "start",
      "timer",
      "countdown",
      "for",
      "a",
      "an",
      "the",
      "please",
      "i want",
      "i would like",
      "seconds",
      "second",
      "minutes",
      "minute",
      "hours",
      "hour",
      "set",
      "sets",
      "round",
      "rounds",
      "work",
      "rest",
    ];

    for (final w in remove) {
      t = t.replaceAll(w, "");
    }

    t = t.replaceAll(RegExp(r'\b\d+\b'), "").trim();

    if (t.isEmpty) return "";

    return t
        .split(" ")
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
