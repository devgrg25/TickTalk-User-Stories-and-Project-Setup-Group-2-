import '../timer_models/timer_model.dart';

class FuzzyMatchResult {
  final TimerData timer;
  final double score;
  FuzzyMatchResult(this.timer, this.score);
}

class FuzzyTimerMatcher {
  /// Top-level function:
  /// returns exact match → 1 result
  /// fuzzy close match → 1 result
  /// multiple candidates → list of >1
  /// no match → empty list
  static List<FuzzyMatchResult> matchTimers(
      String spoken,
      List<TimerData> timers,
      ) {
    final cleaned = _clean(spoken);

    List<FuzzyMatchResult> results = [];

    for (final t in timers) {
      final score = _score(cleaned, _clean(t.name));
      if (score > 0.35) {                    // ← threshold (adjustable)
        results.add(FuzzyMatchResult(t, score));
      }
    }

    // Sort best → worst
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  // ---------------------------------------------------------
  // SCORING ALGORITHM = token match + partial + edit distance
  // ---------------------------------------------------------
  static double _score(String a, String b) {
    if (a == b) return 1.0;

    // Token-based score
    final aTokens = a.split(" ");
    final bTokens = b.split(" ");
    int tokenMatches = 0;
    for (final t1 in aTokens) {
      for (final t2 in bTokens) {
        if (t1 == t2) tokenMatches++;
      }
    }
    double tokenScore = tokenMatches / bTokens.length;

    // Partial match score (substring)
    double partialScore =
    (a.contains(b) || b.contains(a)) ? 0.5 : 0.0;

    // Edit-distance score
    int dist = _levenshtein(a, b);
    double editScore = 1 - (dist / (a.length + b.length).toDouble());

    // Weighted sum
    return (tokenScore * 0.5) + (partialScore * 0.2) + (editScore * 0.3);
  }

  // Cleaning: lowercase, remove symbols
  static String _clean(String s) {
    return s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();
  }

  // Levenshtein distance
  static int _levenshtein(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<List<int>> dp =
    List.generate(s1.length + 1, (_) => List.filled(s2.length + 1, 0));

    for (int i = 0; i <= s1.length; i++)
      {dp[i][0] = i;}
    for (int j = 0; j <= s2.length; j++)
      {dp[0][j] = j;}
    for (int i = 1; i < dp.length; i++) {
      for (int j = 1; j < dp[i].length; j++) {
        dp[i][j] = [
          dp[i - 1][j] + 1, // deletion
          dp[i][j - 1] + 1, // insertion
          dp[i - 1][j - 1] +
              (s1[i - 1] == s2[j - 1] ? 0 : 1), // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return dp[s1.length][s2.length];
  }
}
