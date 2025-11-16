import '../timer/timer_controller.dart';

class Routine {
  final String id;
  final String name;
  final List<TimerInterval> intervals;

  Routine({
    required this.id,
    required this.name,
    required this.intervals,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'intervals': intervals
        .map((i) => {'name': i.name, 'seconds': i.seconds})
        .toList(),
  };

  static Routine fromJson(Map<String, dynamic> json) {
    return Routine(
      id: json['id'],
      name: json['name'],
      intervals: (json['intervals'] as List<dynamic>)
          .map((i) => TimerInterval(
        name: i['name'],
        seconds: i['seconds'],
      ))
          .toList(),
    );
  }
}
