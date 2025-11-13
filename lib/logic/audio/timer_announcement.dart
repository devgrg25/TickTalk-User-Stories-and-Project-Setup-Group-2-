import 'package:flutter_tts/flutter_tts.dart';
import '../haptic/timer_haptic.dart';
import 'tts_base.dart';

/// ------------------------------------------------------------
/// TIMER ANNOUNCEMENT MODULE
/// ------------------------------------------------------------
/// This module handles all spoken feedback and guidance for
/// the Timer feature — including creation, confirmation,
/// and runtime updates.
///
/// It works together with:
///   - [TtsBase] for voice output
///   - [TimerHaptic] for tactile feedback
///
/// All methods are async and safe to call from voice controllers.
/// ------------------------------------------------------------
class TimerAnnouncement {
  final TtsBase tts;
  final TimerHaptic haptic;

  TimerAnnouncement({required this.tts, required this.haptic});

  /// Initial prompt when the user requests to create a timer.
  Future<void> announceTimerIntent() async {
    await haptic.promptType();
    await tts.speak(
      "Sure. Would you like to create a normal timer or an interval timer?",
    );
  }

  /// When user chooses normal timer type
  Future<void> announceNormalTimerPrompt() async {
    await haptic.promptType();
    await tts.speak(
      "Okay, creating a normal timer. Please tell me the duration in minutes. For example, say twenty five minutes.",
    );
  }

  /// When user chooses interval timer type
  Future<void> announceIntervalTimerPrompt() async {
    await haptic.promptType();
    await tts.speak(
      "Alright, creating an interval timer. Please tell me the work time, break time, and number of sets. "
          "For example, say thirty minute work, ten minute break, and four sets.",
    );
  }

  /// Confirms what was parsed from user's speech
  Future<void> confirmParsedTimer({
    String? name,
    bool isInterval = false,
    int? duration,
    int? work,
    int? rest,
    int? sets,
  }) async {
    await haptic.confirmMinor();
    if (!isInterval) {
      await tts.speak(
        "Creating a timer named ${name ?? 'My Timer'} for ${duration ?? 0} minutes. "
            "Please say confirm to save, or cancel to start over.",
      );
    } else {
      await tts.speak(
        "Creating an interval timer named ${name ?? 'My Timer'} "
            "with ${work ?? 0} minute work, ${rest ?? 0} minute break, for ${sets ?? 0} sets. "
            "Say confirm to save, or cancel to try again.",
      );
    }
  }

  /// When user confirms timer creation
  Future<void> announceTimerCreated({bool isInterval = false}) async {
    await haptic.confirmStrong();
    await tts.speak(
      isInterval
          ? "Your interval timer has been created and started."
          : "Your timer has been created and started.",
    );
  }

  /// When timer starts running
  Future<void> announceTimerStarted(String name) async {
    await haptic.confirmMinor();
    await tts.speak("Starting timer ${name.isEmpty ? 'now' : name}.");
  }

  /// When timer finishes
  Future<void> announceTimerFinished(String name) async {
    await haptic.confirmStrong();
    await tts.speak(
      "Timer ${name.isEmpty ? '' : '$name '}completed. Well done!",
    );
  }

  /// When something goes wrong or input is unclear
  Future<void> announceError([String? context]) async {
    await haptic.errorSoft();
    await tts.speak(
      context ??
          "I didn’t quite understand that. Please try again, or say cancel to stop timer setup.",
    );
  }

  /// When user cancels timer creation
  Future<void> announceCancelled() async {
    await haptic.errorHard();
    await tts.speak("Timer setup cancelled.");
  }

  /// Optional helper to provide contextual help
  Future<void> announceHelp() async {
    await haptic.promptType();
    await tts.speak(
      "You can say things like: create a 20 minute timer, or create an interval timer with 25 minute work, "
          "5 minute break, and 4 sets.",
    );
  }
}
