import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VoiceTimerController extends ChangeNotifier {
  Duration _remaining = Duration.zero;
  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;

  Duration get remaining => _remaining;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;

  void start(Duration duration) {
    _timer?.cancel();
    _remaining = duration;
    _isRunning = true;
    _isPaused = false;
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    HapticFeedback.selectionClick();
    notifyListeners();
  }

  void _tick(Timer timer) {
    if (_remaining.inSeconds <= 1) {
      _remaining = Duration.zero;
      _isRunning = false;
      _isPaused = false;
      timer.cancel();
      HapticFeedback.heavyImpact();
      notifyListeners();
      return;
    }
    _remaining -= const Duration(seconds: 1);
    notifyListeners();
  }

  void pause() {
    if (!_isRunning || _isPaused) return;
    _timer?.cancel();
    _isPaused = true;
    notifyListeners();
  }

  void resume() {
    if (!_isRunning || !_isPaused) return;
    _isPaused = false;
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _isRunning = false;
    _isPaused = false;
    _remaining = Duration.zero;
    notifyListeners();
  }
}
