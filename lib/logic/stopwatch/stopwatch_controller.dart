import 'dart:async';
import 'package:flutter/foundation.dart';

class StopwatchController {
  Timer? _ticker;
  int elapsedMs = 0;
  bool isPaused = false;

  VoidCallback? onTick;

  void start() {
    stop();
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
    _ticker = null;
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
