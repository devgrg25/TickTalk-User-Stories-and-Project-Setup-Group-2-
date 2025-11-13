class TimerNormal {
  final String id;
  final String name;
  final int totalTime;
  final bool isRunning;

  TimerNormal({
    required this.id,
    required this.name,
    required this.totalTime,
    this.isRunning = false,
  });

  TimerNormal copyWith({
    String? id,
    String? name,
    int? totalTime,
    bool? isRunning,
  }) {
    return TimerNormal(
      id: id ?? this.id,
      name: name ?? this.name,
      totalTime: totalTime ?? this.totalTime,
      isRunning: isRunning ?? this.isRunning,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'totalTime': totalTime,
    'isRunning': isRunning,
  };

  factory TimerNormal.fromJson(Map<String, dynamic> json) => TimerNormal(
    id: json['id'],
    name: json['name'],
    totalTime: json['totalTime'],
    isRunning: json['isRunning'] ?? false,
  );
}
