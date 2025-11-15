import 'dart:async';

class TimerController {
  late int _remainingSeconds;
  bool _paused = false;

  bool get isPaused => _paused;

  final StreamController<int> _streamController =
  StreamController<int>.broadcast();

  Stream<int> get stream => _streamController.stream;

  Timer? _timer;

  TimerController(int totalSeconds) {
    _remainingSeconds = totalSeconds;
    _start();
  }

  void _start() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_paused && _remainingSeconds > 0) {
        _remainingSeconds--;
        _streamController.add(_remainingSeconds);
      }
    });
  }

  void togglePause() {
    _paused = !_paused;
  }

  void addOneMinute() {
    _remainingSeconds += 60;
    _streamController.add(_remainingSeconds);
  }

  void stop() {
    _timer?.cancel();
    _streamController.close();
  }

  static String format(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;

    return "${h.toString().padLeft(2, '0')}:"
        "${m.toString().padLeft(2, '0')}:"
        "${s.toString().padLeft(2, '0')}";
  }
}
