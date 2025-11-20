class AiStep {
  final String label;
  final int seconds;

  AiStep({
    required this.label,
    required this.seconds,
  });

  factory AiStep.fromJson(Map<String, dynamic> json) {
    return AiStep(
      label: json["label"] ?? "Step",
      seconds: json["seconds"] ?? 1,
    );
  }
}

class AiCommand {
  final String type;

  // Simple timer
  final int? seconds;
  final String? label;

  // Interval timer
  final int? workSeconds;
  final int? restSeconds;
  final int? rounds;

  // Routine
  final String? routineName;
  final bool? autoSave;
  final bool? autoStart;

  // Navigation
  final String? target;

  // Rename routine
  final String? oldName;
  final String? newName;

  // Multi-step routines
  final List<AiStep>? steps;

  AiCommand({
    required this.type,
    this.seconds,
    this.label,
    this.workSeconds,
    this.restSeconds,
    this.rounds,
    this.routineName,
    this.autoSave,
    this.autoStart,
    this.target,
    this.oldName,
    this.newName,
    this.steps,
  });

  factory AiCommand.fromJson(Map<String, dynamic> json) {
    return AiCommand(
      type: json["type"] ?? "",

      // Simple timer
      seconds: json["seconds"],
      label: json["label"],

      // Interval
      workSeconds: json["workSeconds"],
      restSeconds: json["restSeconds"],
      rounds: json["rounds"] == null
          ? null
          : int.tryParse(json["rounds"].toString()) ?? json["rounds"],

      // Routines
      routineName: json["routineName"],
      autoSave: json["autoSave"],
      autoStart: json["autoStart"] ?? false,

      // Navigation
      target: json["target"],

      // Rename
      oldName: json["oldName"],
      newName: json["newName"],

      // MULTI-STEP routines (strong typing)
      steps: json["steps"] != null
          ? (json["steps"] as List)
          .map((e) => AiStep.fromJson(e as Map<String, dynamic>))
          .toList()
          : null,
    );
  }
}
