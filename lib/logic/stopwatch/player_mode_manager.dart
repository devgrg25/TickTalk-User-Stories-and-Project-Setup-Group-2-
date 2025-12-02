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

  /// 🔥 NEW — correct callback type (removes your error)
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
    laps[i].insert(0, Duration(milliseconds: controllers[i].elapsedMs));
  }

  void stopPlayer(int i) {
    final c = controllers[i];

    c.stop();
    c.reset();

    // ⭐ If last player stopped → summary
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

  void stopAll() {
    for (var c in controllers) {
      c.stop();
      c.reset();
    }
    _triggerSummary();
  }

  // ---------------------------------------------------
  // CHECK ALL STOPPED
  // ---------------------------------------------------
  bool _allStopped() {
    return controllers.every((c) => !c.isRunning && c.elapsedMs == 0);
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

    if (onAllPlayersStopped != null) {
      onAllPlayersStopped!(summaries);
    }
  }
}
