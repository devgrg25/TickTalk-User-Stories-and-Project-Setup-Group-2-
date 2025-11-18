// voice_router.dart
import '../logic/timer/timer_manager.dart';
import '../logic/voice/voice_stt_service.dart';
import '../logic/voice/voice_tts_service.dart';
import '../logic/voice/ai_interpreter.dart';
import '../logic/voice/ai_command.dart';
import '../logic/timer/timer_controller.dart';



typedef TabNavigator = void Function(int index);

class VoiceRouter {

  VoiceRouter({required this.onNavigateTab});
  final TabNavigator onNavigateTab;

  Future<void> handle(String raw) async {
    final input = raw.toLowerCase().trim();
    if (input.isEmpty) return;

    // Timer logic first (local + AI)
    if (await _handleTimer(input, raw)) return;

    // Navigation
    if (await _handleNavigation(input)) return;

    // AI fallback for other types
    final ai = await AiInterpreter.interpret(raw);
    if (ai != null) {
      if (ai.type == "start_routine" && ai.routineName != null) {
        await VoiceTtsService.instance.speak(
            "Starting routine ${ai.routineName} is not supported yet.");
        return;
      }
    }

    await VoiceTtsService.instance.speak(
      "Sorry, I cannot handle that yet.",
    );
  }

  // ---------------- TIMER FLOW ----------------

  Future<bool> _handleTimer(String input, String raw) async {
    final duration = _extractDuration(input);
    final mentionsTimer = input.contains("timer") || input.contains("countdown") || input.contains("start");

    // Immediate local simple timer
    if (duration != null && mentionsTimer) {
      final label = _cleanLabel(input);
      TimerManager.instance.startTimer(label, [TimerInterval(name: label, seconds: duration)]);
      await VoiceTtsService.instance.speak("Starting $label for ${_speak(duration)}.");
      return true;
    }

    // Ask AI for complex interpretation
    final ai = await AiInterpreter.interpret(raw);
    if (ai == null) return false;

    if (ai.type == "start_timer" && ai.seconds != null) {
      return _confirmAndStartSimple(ai);
    }

    if (ai.type == "start_interval_timer" && ai.workSeconds != null && ai.rounds != null) {
      return _confirmAndStartInterval(ai);
    }

    return false;
  }

  Future<bool> _confirmAndStartSimple(AiCommand ai) async {
    final label = ai.label ?? "Timer";
    final sec = ai.seconds!;
    await VoiceTtsService.instance.speak(
        "I found a $label timer for ${_speak(sec)}. Should I start it?");
    final ok = await VoiceSttService.instance.listenForConfirmation();
    if (ok == true) {
      TimerManager.instance.startTimer(label, [TimerInterval(name: label, seconds: sec)]);
      await VoiceTtsService.instance.speak("Starting $label.");
    }
    return true;
  }

  Future<bool> _confirmAndStartInterval(AiCommand ai) async {
    final label = ai.label ?? "Session";
    final w = ai.workSeconds!;
    final r = ai.restSeconds ?? 300;
    final rounds = ai.rounds ?? 4;

    await VoiceTtsService.instance.speak(
        "I found a $label session. Work ${_speak(w)}, break ${_speak(r)}, for $rounds rounds. Should I start it?");

    final ok = await VoiceSttService.instance.listenForConfirmation();
    if (ok == true) {
      final intervals = <TimerInterval>[];
      for (int i = 0; i < rounds; i++) {
        intervals.add(TimerInterval(name: label, seconds: w));
        if (i < rounds - 1) {
          intervals.add(TimerInterval(name: "Break", seconds: r));
        }
      }
      TimerManager.instance.startTimer(label, intervals);
      await VoiceTtsService.instance.speak("Starting $label.");
    }
    return true;
  }

  // ---------------- Navigation ----------------
  Future<bool> _handleNavigation(String input) async {
    if (input.contains("home"))  { onNavigateTab(0); return true; }
    if (input.contains("timer")) { onNavigateTab(1); return true; }
    if (input.contains("routine")) { onNavigateTab(2); return true; }
    return false;
  }

  // ---------------- UTILITIES ----------------

  int? _extractDuration(String input) {
    final regex = RegExp(r'(\d+)\s*(second|seconds|sec|s|minute|minutes|min|m)\b');
    final m = regex.firstMatch(input);
    if (m == null) return null;
    final num = int.parse(m.group(1)!);
    return m.group(2)!.startsWith("min") ? num * 60 : num;
  }

  String _cleanLabel(String raw) {
    return raw.replaceAll(RegExp(r'\d+|seconds?|minutes?|timer|start|countdown'), "").trim();
  }

  String _speak(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    if (m > 0 && s > 0) return "$m minutes and $s seconds";
    if (m > 0) return "$m minutes";
    return "$s seconds";
  }
}
