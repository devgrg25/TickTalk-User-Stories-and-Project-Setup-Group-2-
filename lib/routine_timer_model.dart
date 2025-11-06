import 'dart:convert';

class TimerStep {
  final String name;
  final int durationInMinutes;

  TimerStep({required this.name, required this.durationInMinutes});

  Map<String, dynamic> toJson() => {
    'name': name,
    'duration': durationInMinutes,
  };

  factory TimerStep.fromJson(Map<String, dynamic> json) => TimerStep(
    name: json['name'],
    durationInMinutes: json['duration'],
  );
}

class TimerDataV {
  final String id;
  final String name;
  final List<TimerStep> steps;
  // NEW FIELDS
  bool isFavorite;
  final bool isCustom;

  int get totalSteps => steps.length;
  int get totalTime => steps.fold(0, (sum, step) => sum + step.durationInMinutes);

  TimerDataV({
    required this.id,
    required this.name,
    required this.steps,
    this.isFavorite = false, // Default to false
    this.isCustom = false,   // Default to false (true only for user-created)
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'steps': steps.map((step) => step.toJson()).toList(),
    'isFavorite': isFavorite,
    'isCustom': isCustom,
  };

  factory TimerDataV.fromJson(Map<String, dynamic> json) {
    var stepsList = json['steps'] as List;
    List<TimerStep> parsedSteps = stepsList.map((stepJson) => TimerStep.fromJson(stepJson)).toList();

    return TimerDataV(
      id: json['id'],
      name: json['name'],
      steps: parsedSteps,
      isFavorite: json['isFavorite'] ?? false,
      isCustom: json['isCustom'] ?? false,
    );
  }
}