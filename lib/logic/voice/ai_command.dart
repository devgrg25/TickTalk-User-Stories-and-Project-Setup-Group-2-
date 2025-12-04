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
  // Player Mode (single player)
  // --------------------------
  final int? playerIndex;
  final bool? startAll;
  final bool? stopAll;

  // NEW: global player controls
  final bool? pauseAll;
  final bool? resumeAll;


  // --------------------------
  // NEW: Player Mode (full mode N players)
  // --------------------------
  final int? playerCount;

  AiCommand({
    required this.type,

    // Timer
    this.seconds,
    this.label,

    // Interval
    this.workSeconds,
    this.restSeconds,
    this.rounds,

    // Routine
    this.routineName,
    this.autoSave,
    this.autoStart,
    this.steps,

    // Navigation
    this.target,

    // Rename
    this.oldName,
    this.newName,

    // Summary
    this.lapNumber,
    this.valueSeconds,

    // Player mode per-player controls
    this.playerIndex,
    this.startAll,
    this.stopAll,

    this.pauseAll,
    this.resumeAll,


    // NEW: full mode N players
    this.playerCount,
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
      valueSeconds: json["valueSeconds"] == null
          ? null
          : (json["valueSeconds"] as num).toDouble(),

      // Player mode single-player actions
      playerIndex: json["playerIndex"],

// Global player commands (snake_case from backend)
// These are booleans, so treat presence as TRUE
      startAll: json["start_all_players"] == true,
      stopAll: json["stop_all_players"] == true,
      pauseAll: json["pause_all_players"] == true,
      resumeAll: json["resume_all_players"] == true,

// NEW: full mode N players
      playerCount: json["playerCount"],

    );
  }
}
