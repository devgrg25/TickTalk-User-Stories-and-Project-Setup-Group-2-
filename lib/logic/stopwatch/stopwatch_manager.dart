import 'dart:async';
import 'stopwatch_controller.dart';

class ActiveStopwatch {
  final String id;
  final StopwatchController controller;

  ActiveStopwatch({
    required this.id,
    required this.controller,
  });
}

class StopwatchManager {
  StopwatchManager._();
  static final StopwatchManager instance = StopwatchManager._();

  final List<ActiveStopwatch> _stopwatches = [];
  final StreamController<void> _change = StreamController.broadcast();

  Stream<void> get onChange => _change.stream;
  List<ActiveStopwatch> get stopwatches => List.unmodifiable(_stopwatches);

  void _emit() {
    if (!_change.isClosed) _change.add(null);
  }

  /// Start a new stopwatch
  StopwatchController startStopwatch() {
    final controller = StopwatchController();
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final active = ActiveStopwatch(id: id, controller: controller);
    _stopwatches.add(active);

    controller.onTick = () => _emit();

    controller.start();
    _emit();
    return controller;
  }

  void stopStopwatch(String id) {
    _stopwatches.removeWhere((s) {
      if (s.id == id) {
        s.controller.stop();
        return true;
      }
      return false;
    });
    _emit();
  }

  void stopAll() {
    for (var s in _stopwatches) {
      s.controller.stop();
    }
    _stopwatches.clear();
    _emit();
  }
}
