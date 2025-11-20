import 'dart:async';
import 'package:flutter/foundation.dart';

class NormalStopwatchSharedController {
  Timer? _ticker;
  int elapsedMs = 0;
  bool isPaused = false;
  bool isRunning = false;

  final List<Duration> laps = [];

  VoidCallback? onTick;

  void start() {
    if (isRunning && !isPaused) return; // already running

    isRunning = true;
    isPaused = false;

    _ticker ??= Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!isPaused) {
        elapsedMs += 100;
        onTick?.call();
      }
    });

    onTick?.call();
  }

  void pause() {
    if (!isRunning) return;
    isPaused = true;
    onTick?.call();
  }

  void resume() {
    if (!isRunning) return;
    isPaused = false;
    onTick?.call();
  }

  void lap() {
    laps.insert(0, Duration(milliseconds: elapsedMs));
    onTick?.call();
  }

  void stop() {
    isPaused = false;
    isRunning = false;
    _ticker?.cancel();
    _ticker = null;
    onTick?.call();
  }

  void reset() {
    elapsedMs = 0;
    laps.clear();
    onTick?.call();
  }

  Duration get elapsed => Duration(milliseconds: elapsedMs);

  /// 🔥 FIXED: This method is now named correctly!
  static String format(int ms) {
    final seconds = (ms ~/ 1000);
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final cent = (ms % 1000 ~/ 10);

    return "${minutes.toString().padLeft(2, '0')}:"
        "${secs.toString().padLeft(2, '0')}:"
        "${cent.toString().padLeft(2, '0')}";
  }
}
