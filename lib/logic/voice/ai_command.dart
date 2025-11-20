class AiStep {
  final String label;
  final int seconds;

  AiStep({
    required this.label,
    required this.seconds,
  });

  factory AiStep.fromJson(Map<String, dynamic> json) {
    return AiStep(
      label: json["label"],
      seconds: json["seconds"],
    );
  }
}

class AiCommand {
  final String type;

  // For simple timers
  final int? seconds;
  final String? label;

  // For interval timers
  final int? workSeconds;
  final int? restSeconds;
  final int? rounds;

  // For routines
  final String? routineName;

  // For navigation
  final String? target;

  // For rename routine
  final String? oldName;
  final String? newName;

  // 🔥 NEW — Multi-step routines
  final List<AiStep>? steps;

  AiCommand({
    required this.type,
    this.seconds,
    this.label,
    this.workSeconds,
    this.restSeconds,
    this.rounds,
    this.routineName,
    this.target,
    this.oldName,
    this.newName,
    this.steps,
  });

  factory AiCommand.fromJson(Map<String, dynamic> json) {
    return AiCommand(
      type: json["type"] ?? "",

      seconds: json["seconds"],
      label: json["label"],

      workSeconds: json["workSeconds"],
      restSeconds: json["restSeconds"],
      rounds: json["rounds"],

      routineName: json["routineName"],
      target: json["target"],

      oldName: json["oldName"],
      newName: json["newName"],

      // 🔥 NEW — Parse steps list
      steps: json["steps"] != null
          ? List<Map<String, dynamic>>.from(json["steps"])
          .map((s) => AiStep.fromJson(s))
          .toList()
          : null,
    );
  }
}
