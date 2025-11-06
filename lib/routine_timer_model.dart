import 'dart:convert';

// NEW: A class to represent a single step in a timer
class TimerStep {
  final String name;
  final int durationInMinutes;

  TimerStep({required this.name, required this.durationInMinutes});

  // Methods to convert this step to/from JSON for saving
  Map<String, dynamic> toJson() => {
    'name': name,
    'duration': durationInMinutes, // Save using the key 'duration'
  };

  // Factory constructor: Create TimerStep from JSON
  factory TimerStep.fromJson(Map<String, dynamic> json) => TimerStep(
    name: json['name'],
    // Use the correct parameter name 'durationInMinutes' when calling the constructor
    durationInMinutes: json['duration'], // <-- CORRECTED LINE
  );
}

// UPDATED: The main TimerData class
class TimerDataV {
  final String id; // Unique ID for each timer
  final String name;
  final List<TimerStep> steps; // <-- REPLACED old fields

  // 'totalSteps' is now just the count of steps
  int get totalSteps => steps.length;

  // 'totalTime' is now calculated by adding all step durations
  int get totalTime => steps.fold(0, (sum, step) => sum + step.durationInMinutes);

  TimerDataV({
    required this.id,
    required this.name,
    required this.steps,
  });

  // Method to convert a TimerData instance to a JSON map
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    // Convert the list of steps into a list of JSON maps
    'steps': steps.map((step) => step.toJson()).toList(),
  };

  // Factory constructor to create a TimerData instance from a JSON map
  factory TimerDataV.fromJson(Map<String, dynamic> json) {
    // Get the list of steps from JSON
    var stepsList = json['steps'] as List;
    // Convert that list of JSON maps back into a List<TimerStep>
    List<TimerStep> parsedSteps = stepsList.map((stepJson) => TimerStep.fromJson(stepJson)).toList();

    return TimerDataV(
      id: json['id'],
      name: json['name'],
      steps: parsedSteps,
    );
  }
}