import 'dart:async';
import 'package:flutter/foundation.dart';

class TimerInterval {
  final String name;
  final int seconds;
  TimerInterval({required this.name, required this.seconds});
}

class TimerController {
  final List<TimerInterval> intervals;

  TimerInterval? current;
  TimerInterval? next;

  int _currentIndex = 0;
  int remainingSeconds = 0;
  bool isPaused = false;
  Timer? _ticker;

  VoidCallback? onTick;
  VoidCallback? onIntervalComplete;
  VoidCallback? onTimerComplete;

  TimerController({required this.intervals}) {
    if (intervals.isEmpty) {
      throw Exception("TimerController created with no intervals.");
    }
    _setCurrentInterval(0);
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

  void pause() {
    isPaused = true;
  }

  void resume() {
    isPaused = false;
  }

  bool get isRunning => _ticker != null && !isPaused;
  bool get isStopped => _ticker == null;

  // bool get isRunning => _ticker != null && !isPaused;
  // bool get isStopped => _ticker == null;


  void addTime(int sec) {
    if (remainingSeconds != null) {
      remainingSeconds = (remainingSeconds! + sec).clamp(0, 999999);
    }
  }

  void stop() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _tick() {
    if (remainingSeconds == null) return;

    if (remainingSeconds! > 0) {
      remainingSeconds = remainingSeconds! - 1;
      onTick?.call();
      return;
    }

    _nextInterval();
  }

  void _setCurrentInterval(int index) {
    _currentIndex = index;
    current = intervals[index];
    remainingSeconds = current!.seconds;

    next = index + 1 < intervals.length ? intervals[index + 1] : null;
  }

  void _nextInterval() {
    onIntervalComplete?.call();

    final newIndex = _currentIndex + 1;
    if (newIndex >= intervals.length) {
      stop();
      onTimerComplete?.call();
      return;
    }
    _setCurrentInterval(newIndex);
  }
}
