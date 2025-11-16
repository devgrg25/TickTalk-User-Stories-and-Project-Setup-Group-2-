import 'dart:async';
import 'package:flutter/foundation.dart';


class TimerInterval {
  final String name;
  final int seconds;
  TimerInterval({required this.name, required this.seconds});
}

class TimerController {
  final List<TimerInterval> intervals;
  late TimerInterval current;
  TimerInterval? next;

  int _currentIndex = 0;
  int remainingSeconds = 0;
  bool isPaused = false;
  Timer? _ticker;

  VoidCallback? onTick;
  VoidCallback? onIntervalComplete;
  VoidCallback? onTimerComplete;

  TimerController({required this.intervals}) {
    current = intervals.first;
    remainingSeconds = current.seconds;
    _updateNext();
  }

  static String format(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  void start() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isPaused) _tick();
    });
  }

  void pause() => isPaused = true;
  void resume() => isPaused = false;

  void addTime(int sec) => remainingSeconds += sec;

  void stop() {
    _ticker?.cancel();
  }

  void _tick() {
    remainingSeconds--;
    onTick?.call();

    if (remainingSeconds <= 0) {
      _nextInterval();
    }
  }

  void _updateNext() {
    next = _currentIndex + 1 < intervals.length
        ? intervals[_currentIndex + 1]
        : null;
  }

  void _nextInterval() {
    onIntervalComplete?.call();
    _currentIndex++;

    if (_currentIndex >= intervals.length) {
      stop();
      onTimerComplete?.call();
      return;
    }

    current = intervals[_currentIndex];
    remainingSeconds = current.seconds;
    _updateNext();
  }
}
