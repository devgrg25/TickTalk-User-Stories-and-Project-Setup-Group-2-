import 'dart:async';
import 'timer_controller.dart';
import 'timer_interval.dart';

class ActiveTimer {
  final String id;
  final String name;
  final TimerController controller;
  bool finished;

  ActiveTimer({
    required this.id,
    required this.name,
    required this.controller,
    this.finished = false,
  });
}

class TimerManager {
  void forceUpdate() => _emit();
  TimerManager._();
  static final TimerManager instance = TimerManager._();

  final List<ActiveTimer> _timers = [];
  final StreamController<void> _change = StreamController.broadcast();

  Stream<void> get onChange => _change.stream;
  List<ActiveTimer> get timers => List.unmodifiable(_timers);

  void _emit() {
    if (!_change.isClosed) _change.add(null);
  }

  /// Start a new timer and keep it in the list even when finished.
  TimerController startTimer(String name, List<TimerInterval> intervals) {
    final controller = TimerController(intervals: intervals);
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final active = ActiveTimer(
      id: id,
      name: name,
      controller: controller,
      finished: false,
    );

    _timers.add(active);
    _emit();

    controller.onTick = () {
      _emit(); // ⬅ notify UI every second
    };


    controller.start();
    return controller;
  }

  /// Remove timer manually (Stop button or X icon).
  void stopTimer(String id) {
    _timers.removeWhere((t) {
      if (t.id == id) {
        t.controller.stop();
        return true;
      }
      return false;
    });
    _emit();
  }

  void stopAll() {
    for (var t in _timers) {
      t.controller.stop();
    }
    _timers.clear();
    _emit();
  }
}
