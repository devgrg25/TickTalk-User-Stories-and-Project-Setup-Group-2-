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

  // --------------------------
  // Timer
  // --------------------------
  final int? seconds;
  final String? label;

  // --------------------------
  // Interval
  // --------------------------
  final int? workSeconds;
  final int? restSeconds;
  final int? rounds;

  // --------------------------
  // Multi-step routine
  // --------------------------
  final String? routineName;
  final bool? autoSave;
  final bool? autoStart;
  final List<AiStep>? steps;

  // --------------------------
  // Navigation
  // --------------------------
  final String? target;

  // --------------------------
  // Routine rename
  // --------------------------
  final String? oldName;
  final String? newName;

  // --------------------------
  // Stopwatch summary
  // --------------------------
  final int? lapNumber;
  final double? valueSeconds;

  // --------------------------
  // Player Mode
  // --------------------------
  final int? playerIndex;        // For single-player actions
  final bool? startAll;
  final bool? stopAll;

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
    this.steps,
    this.target,
    this.oldName,
    this.newName,
    this.lapNumber,
    this.valueSeconds,
    this.playerIndex,
    this.startAll,
    this.stopAll,
  });

  factory AiCommand.fromJson(Map<String, dynamic> json) {
    return AiCommand(
      type: json["type"] ?? "",

      // Timer
      seconds: json["seconds"],
      label: json["label"],

      // Interval
      workSeconds: json["workSeconds"],
      restSeconds: json["restSeconds"],
      rounds: json["rounds"],

      // Routine
      routineName: json["routineName"],
      autoSave: json["autoSave"],
      autoStart: json["autoStart"],

      // Navigation
      target: json["target"],

      // Rename
      oldName: json["oldName"],
      newName: json["newName"],

      // Steps
      steps: json["steps"] != null
          ? (json["steps"] as List)
          .map((e) => AiStep.fromJson(e as Map<String, dynamic>))
          .toList()
          : null,

      // Summary
      lapNumber: json["lapNumber"],
      valueSeconds:
      json["valueSeconds"] == null ? null : (json["valueSeconds"] as num).toDouble(),

      // Player mode
      playerIndex: json["playerIndex"],
      startAll: json["startAll"],
      stopAll: json["stopAll"],
    );
  }
}
