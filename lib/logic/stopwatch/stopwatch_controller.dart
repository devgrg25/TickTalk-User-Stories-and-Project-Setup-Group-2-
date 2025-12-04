import 'dart:async';
import 'package:flutter/foundation.dart';

class StopwatchController {
  Timer? _ticker;
  int elapsedMs = 0;
  bool isPaused = false;

  VoidCallback? onTick;

  /// 🔥 NEW — tells whether stopwatch is active (running or paused)
  bool get isActive => _ticker != null;

  bool get isRunning => _ticker != null && !isPaused;


  void start() {
    stop(); // ensure clean start
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!isPaused) {
        elapsedMs += 100;
        onTick?.call();
      }
    });
  }

  void pause() {
    isPaused = true;
  }

  void resume() {
    isPaused = false;
  }

  void stop() {
    _ticker?.cancel();
    _ticker = null; // VERY IMPORTANT for isActive logic
  }

  void reset() {
    elapsedMs = 0;
    onTick?.call();
  }

  static String format(int ms) {
    final seconds = (ms ~/ 1000);
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final cent = (ms % 1000) ~/ 10;

    return "${minutes.toString().padLeft(2, '0')}:"
        "${secs.toString().padLeft(2, '0')}:"
        "${cent.toString().padLeft(2, '0')}";
  }
}
