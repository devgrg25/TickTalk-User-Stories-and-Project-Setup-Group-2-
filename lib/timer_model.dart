// timer_model.dart

class TimerData {
  final String id; // Unique ID for each timer
  final String name;
  final int totalTime;
  final int workInterval;
  final int breakInterval;
  final int totalSets;
  final int currentSet;

  TimerData({
    required this.id,
    required this.name,
    required this.totalTime,
    required this.workInterval,
    required this.breakInterval,
    required this.totalSets,
    required this.currentSet,
  });

  TimerData copyWith({
    String? id,
    String? name,
    int? totalTime,
    int? workInterval,
    int? breakInterval,
    int? totalSets,
    int? currentSet,
  }) {
    return TimerData(
      id: id ?? this.id,
      name: name ?? this.name,
      totalTime: totalTime ?? this.totalTime,
      workInterval: workInterval ?? this.workInterval,
      breakInterval: breakInterval ?? this.breakInterval,
      totalSets: totalSets ?? this.totalSets,
      currentSet: currentSet ?? this.currentSet,
    );
  }

  // Method to convert a TimerData instance to a JSON map
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'totalTime': totalTime,
    'workInterval': workInterval,
    'breakInterval': breakInterval,
    'totalSets': totalSets,
    'currentSet': currentSet,
  };

  // Factory constructor to create a TimerData instance from a JSON map
  factory TimerData.fromJson(Map<String, dynamic> json) => TimerData(
    id: json['id'],
    name: json['name'],
    totalTime: json['totalTime'],
    workInterval: json['workInterval'],
    breakInterval: json['breakInterval'],
    totalSets: json['totalSets'],
    currentSet: json['currentSet']
  );
}