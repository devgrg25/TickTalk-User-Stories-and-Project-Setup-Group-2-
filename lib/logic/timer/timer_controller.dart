import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ticktalk_app/logic/voice/voice_tts_service.dart';
import 'package:ticktalk_app/logic/haptics/haptics_service.dart';

class TimerInterval {
  final String name;
  final int seconds;

  const TimerInterval({
    required this.name,
    required this.seconds,
  });
}

class TimerController {
  final List<TimerInterval> intervals;

  TimerInterval? current;
  TimerInterval? next;

  int _currentIndex = 0;
  int remainingSeconds = 0;
  bool isPaused = false;
  Timer? _ticker;

  /// Callbacks
  VoidCallback? onTick;
  VoidCallback? onIntervalComplete;
  VoidCallback? onTimerComplete;

  TimerController({required this.intervals}) {
    if (intervals.isEmpty) {
      throw Exception("TimerController created with no intervals.");
    }
    _setCurrentInterval(0);
    _announceStartOfInterval();
  }

  static String format(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  void start() {
    stop();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isPaused) _tick();
    });
  }

  void pause() => isPaused = true;
  void resume() => isPaused = false;

  bool get isRunning => _ticker != null && !isPaused;
  bool get isStopped => _ticker == null;

  void addTime(int sec) {
    remainingSeconds = (remainingSeconds + sec).clamp(0, 999999);
  }

  void stop() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _tick() {
    if (remainingSeconds > 0) {
      remainingSeconds -= 1;

      /// Voice warnings + haptics
      if (remainingSeconds == 10) {
        VoiceTtsService.instance.speak("10 seconds remaining.");
      } else if (remainingSeconds == 5) {
        VoiceTtsService.instance.speak("5 seconds remaining.");
      } else if (remainingSeconds == 3 ||
          remainingSeconds == 2 ||
          remainingSeconds == 1) {
        HapticsService.instance.countdownPulse();
      }

      onTick?.call();
      return;
    }

    _advanceToNextInterval();
  }

  void _setCurrentInterval(int index) {
    _currentIndex = index;
    current = intervals[index];
    remainingSeconds = current!.seconds;
    next = index + 1 < intervals.length ? intervals[index + 1] : null;
  }

  void _advanceToNextInterval() {
    onIntervalComplete?.call();

    final newIndex = _currentIndex + 1;
    if (newIndex >= intervals.length) {
      stop();
      VoiceTtsService.instance.speak("Routine complete.");
      HapticsService.instance.finishLong(); // long vibration on completion
      onTimerComplete?.call();
      return;
    }

    _setCurrentInterval(newIndex);
    _announceStartOfInterval();
  }

  void _announceStartOfInterval() {
    if (current == null) return;
    final text = _formatSpokenName(current!.name);
    VoiceTtsService.instance.speak(
        "Starting $text for ${current!.seconds} seconds."
    );
  }

  /// Fix shouting names: "HIGH KNEES" → "High knees"
  String _formatSpokenName(String text) {
    if (text.isEmpty) return text;
    final lower = text.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }
}
