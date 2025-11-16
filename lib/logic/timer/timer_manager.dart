import 'dart:async';
import 'timer_controller.dart';
import 'timer_interval.dart';

class ActiveTimer {
  final String id;
  final String name;
  final TimerController controller;
  bool finished = false; // NEW FLAG

  ActiveTimer({
    required this.id,
    required this.name,
    required this.controller,
    this.finished = false,
  });
}

class TimerManager {
  TimerManager._();
  static final TimerManager instance = TimerManager._();

  final List<ActiveTimer> _timers = [];
  final StreamController<void> _change = StreamController.broadcast();

  Stream<void> get onChange => _change.stream;
  List<ActiveTimer> get timers => List.unmodifiable(_timers);

  void _emit() {
    if (!_change.isClosed) _change.add(null);
  }

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

    controller.onTimerComplete = () {
      active.finished = true;  // mark finished instead of removing
      _emit();
    };

    controller.start();
    return controller;
  }

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
