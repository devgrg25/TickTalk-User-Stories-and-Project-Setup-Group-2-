import 'stopwatch_controller.dart';

class PlayerStopwatchSummary {
  final int number;
  final Duration total;
  final List<Duration> laps;

  PlayerStopwatchSummary({
    required this.number,
    required this.total,
    required this.laps,
  });
}

class PlayerModeManager {
  PlayerModeManager._();
  static final PlayerModeManager instance = PlayerModeManager._();

  final List<StopwatchController> controllers = [];
  final List<List<Duration>> laps = [];

  /// Callback for when ALL players stop
  void Function(List<PlayerStopwatchSummary>)? onAllPlayersStopped;

  // ---------------------------------------------------
  // CREATE PLAYERS
  // ---------------------------------------------------
  void createPlayers(int count) {
    controllers.clear();
    laps.clear();

    for (int i = 0; i < count; i++) {
      controllers.add(StopwatchController());
      laps.add([]);
    }
  }

  // ---------------------------------------------------
  // SINGLE PLAYER ACTIONS
  // ---------------------------------------------------
  void startPlayer(int i) => controllers[i].start();

  void pausePlayer(int i) => controllers[i].pause();

  void resumePlayer(int i) => controllers[i].resume();

  void lapPlayer(int i) {
    laps[i].insert(
      0,
      Duration(milliseconds: controllers[i].elapsedMs),
    );
  }

  /// ❗ STOP SHOULD NOT RESET NOW
  void stopPlayer(int i) {
    final c = controllers[i];

    c.stop(); // freeze the time, don't reset

    // if all non-running → summary
    if (_allStopped()) {
      _triggerSummary();
    }
  }

  // ---------------------------------------------------
  // ALL PLAYERS
  // ---------------------------------------------------
  void startAll() {
    for (var c in controllers) {
      c.start();
    }
  }

  /// Stop all, then show summary, THEN reset
  void stopAll() {
    for (var c in controllers) {
      c.stop();
    }

    _triggerSummary();

    _resetAll();
  }

  // ---------------------------------------------------
  // CHECK ALL STOPPED
  // ---------------------------------------------------
  /// ❗ FIXED LOGIC — ONLY CHECK RUN STATE
  bool _allStopped() {
    return controllers.every((c) => !c.isRunning);
  }

  // ---------------------------------------------------
  // SUMMARY BUILDER
  // ---------------------------------------------------
  void _triggerSummary() {
    final summaries = <PlayerStopwatchSummary>[];

    for (int i = 0; i < controllers.length; i++) {
      summaries.add(
        PlayerStopwatchSummary(
          number: i + 1,
          total: Duration(milliseconds: controllers[i].elapsedMs),
          laps: List<Duration>.from(laps[i]),
        ),
      );
    }

    // 🔥 Send summary to UI
    if (onAllPlayersStopped != null) {
      onAllPlayersStopped!(summaries);
    }

    // reset after summary
    _resetAll();
  }

  // ---------------------------------------------------
  // INTERNAL RESET
  // ---------------------------------------------------
  void _resetAll() {
    for (var c in controllers) {
      c.reset();
    }

    for (var l in laps) {
      l.clear();
    }
  }
}
