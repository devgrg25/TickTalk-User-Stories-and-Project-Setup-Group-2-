// lib/onboarding/T3_US1.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// T3_US1: Persistence and Fallback UI logic.
/// Manages welcomePlayed flag and provides simple UI buttons.

class T3US1Persistence {
  Future<void> setWelcomePlayed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcomePlayed', true);
  }

  Future<bool> hasPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('welcomePlayed') ?? false;
  }

  Future<void> resetFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcomePlayed', false);
  }
}

/// Optional: Fallback buttons for manual access (T3)
class OnboardingFallbackButtons extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onSkip;
  final VoidCallback onRepeat;

  const OnboardingFallbackButtons({
    super.key,
    required this.onStart,
    required this.onSkip,
    required this.onRepeat,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Tutorial'),
          onPressed: onStart,
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.skip_next),
          label: const Text('Skip'),
          onPressed: onSkip,
        ),
        TextButton.icon(
          icon: const Icon(Icons.replay),
          label: const Text('Repeat'),
          onPressed: onRepeat,
        ),
      ],
    );
  }
}
