class AiCommand {
  final String type;
  final int? seconds;        // simple timer
  final String? label;

  // interval timers
  final int? workSeconds;
  final int? restSeconds;
  final int? rounds;

  // routines
  final String? routineName;

  AiCommand({
    required this.type,
    this.seconds,
    this.label,
    this.workSeconds,
    this.restSeconds,
    this.rounds,
    this.routineName,
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
    );
  }
}
