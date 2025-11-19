import 'dart:async';

class TimerData {
  final String id;
  final String name;

  int totalTime;       // <- mutable!
  final int workInterval;
  final int breakInterval;
  final int totalSets;
  int currentSet;      // <- mutable!

  bool isRunning;
  Timer? ticker;

  TimerData({
    required this.id,
    required this.name,
    required this.totalTime,
    required this.workInterval,
    required this.breakInterval,
    required this.totalSets,
    required this.currentSet,
    this.isRunning = false,
    this.ticker,
  });

  TimerData copyWith({
    String? id,
    String? name,
    int? totalTime,
    int? workInterval,
    int? breakInterval,
    int? totalSets,
    int? currentSet,
    bool? isRunning,
  }) {
    return TimerData(
      id: id ?? this.id,
      name: name ?? this.name,
      totalTime: totalTime ?? this.totalTime,
      workInterval: workInterval ?? this.workInterval,
      breakInterval: breakInterval ?? this.breakInterval,
      totalSets: totalSets ?? this.totalSets,
      currentSet: currentSet ?? this.currentSet,
      isRunning: isRunning ?? this.isRunning,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'totalTime': totalTime,
    'workInterval': workInterval,
    'breakInterval': breakInterval,
    'totalSets': totalSets,
    'currentSet': currentSet,
  };

  factory TimerData.fromJson(Map<String, dynamic> json) => TimerData(
    id: json['id'],
    name: json['name'],
    totalTime: json['totalTime'],
    workInterval: json['workInterval'],
    breakInterval: json['breakInterval'],
    totalSets: json['totalSets'],
    currentSet: json['currentSet'],
  );

  void start(Function onTick, Function onFinish) {
    isRunning = true;
    ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (totalTime <= 0) {
        t.cancel();
        isRunning = false;
        onFinish();
        return;
      }
      totalTime--;      // now works
      onTick();
    });
  }

  void pause() {
    ticker?.cancel();
    isRunning = false;
  }

  void resume(Function onTick, Function onFinish) {
    if (isRunning) return;

    isRunning = true;
    ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (totalTime <= 0) {
        t.cancel();
        isRunning = false;
        onFinish();
        return;
      }
      totalTime--;
      onTick();
    });
  }

  void stop() {
    ticker?.cancel();
    ticker = null;
    isRunning = false;
  }
}