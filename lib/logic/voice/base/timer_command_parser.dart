import 'dart:core';

/// Parses spoken timer creation commands into structured data.
///
/// This helper doesn’t handle any speech I/O; it only interprets the text.
/// Used by [TimerVoiceController] to extract timer intent and values.
class TimerCommandParser {
  /// Attempts to extract numbers (minutes, sets) and type (interval/normal)
  /// from a natural-language input.
  ///
  /// Returns a [ParsedTimerCommand] if confident enough, otherwise `null`.
  ParsedTimerCommand? tryParseFullTimer(String input) {
    final text = input.toLowerCase().trim();

    if (!text.contains('timer')) return null;

    final isInterval = text.contains('interval') ||
        text.contains('sets') ||
        text.contains('set') ||
        text.contains('break');

    // Extract the timer name
    final name = _extractName(text);

    // Extract all numbers in the order they appear
    final numbers = _extractAllNumbers(text);

    // Interpret based on structure
    if (!isInterval && numbers.isNotEmpty) {
      // "create a timer for 25 minutes"
      return ParsedTimerCommand(
        name: name,
        isInterval: false,
        durationMinutes: numbers.first,
      );
    }

    if (isInterval) {
      // Try to map: work / break / sets from context
      final work = _extractAfter(text, ['work', 'working']);
      final brk = _extractAfter(text, ['break', 'rest']);
      final sets = _extractAfter(text, ['set', 'sets']);

      return ParsedTimerCommand(
        name: name,
        isInterval: true,
        workMinutes: work ?? _guessByOrder(numbers, 0),
        breakMinutes: brk ?? _guessByOrder(numbers, 1),
        sets: sets ?? _guessByOrder(numbers, 2),
      );
    }

    return null;
  }

  /// Extracts the *first* number (like "25" from "25 minutes").
  int? extractSingleNumber(String input) {
    final match = RegExp(r'(\d+)').firstMatch(input);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  // =========================
  //     INTERNAL HELPERS
  // =========================

  /// Returns all numbers in the string, in order.
  List<int> _extractAllNumbers(String text) {
    return RegExp(r'(\d+)')
        .allMatches(text)
        .map((m) => int.tryParse(m.group(1) ?? '0') ?? 0)
        .where((n) => n > 0)
        .toList();
  }

  /// Extracts an integer appearing after any of the keywords.
  int? _extractAfter(String text, List<String> keywords) {
    for (final k in keywords) {
      final reg = RegExp('$k[^0-9]*(\\d+)');
      final match = reg.firstMatch(text);
      if (match != null) {
        return int.tryParse(match.group(1)!);
      }
    }
    return null;
  }

  /// Guesses number by index if context keywords fail.
  int? _guessByOrder(List<int> nums, int index) {
    if (nums.length > index) return nums[index];
    return null;
  }

  /// Extracts a timer name from phrases like:
  /// "create a timer called study" or "make a timer named workout".
  String? _extractName(String text) {
    final namePatterns = [
      RegExp(r'(?:called|named|name it|call it)\s+([a-zA-Z\s]+)'),
      RegExp(r'(?:create|make|start)\s+(?:a\s+)?timer\s+(?:called|named)?\s*([a-zA-Z\s]+)?'),
    ];

    for (final pattern in namePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final raw = match.group(1)?.trim() ?? '';
        if (raw.isNotEmpty) {
          // remove trailing filler like "for 25 minutes"
          final name = raw.split(RegExp(r'\s+for\s+')).first.trim();
          return name.isEmpty ? null : name;
        }
      }
    }

    return null;
  }
}

/// Structured output of [TimerCommandParser].
class ParsedTimerCommand {
  ParsedTimerCommand({
    required this.name,
    required this.isInterval,
    this.durationMinutes,
    this.workMinutes,
    this.breakMinutes,
    this.sets,
  });

  final String? name;
  final bool isInterval;
  final int? durationMinutes;
  final int? workMinutes;
  final int? breakMinutes;
  final int? sets;

  bool get isComplete => isInterval
      ? (workMinutes != null && breakMinutes != null && sets != null)
      : (durationMinutes != null);

  @override
  String toString() {
    if (isInterval) {
      return 'IntervalTimer(name=$name, work=$workMinutes, break=$breakMinutes, sets=$sets)';
    } else {
      return 'NormalTimer(name=$name, duration=$durationMinutes)';
    }
  }
}
