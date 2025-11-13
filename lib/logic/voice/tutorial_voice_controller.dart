import 'package:flutter/material.dart';
import 'base/voice_controller_base.dart';

class TutorialVoiceController extends VoiceControllerBase {
  VoidCallback? onStartTutorial;
  VoidCallback? onNextStep;
  VoidCallback? onExitTutorial;

  @override
  Future<void> handleCommand(String text) async {
    final lower = text.toLowerCase();

    if (lower.contains('tutorial') || lower.contains('start')) {
      await speak("Starting tutorial mode. Let's begin.");
      onStartTutorial?.call();
    } else if (lower.contains('next')) {
      await speak("Moving to the next tutorial step.");
      onNextStep?.call();
    } else if (lower.contains('exit') || lower.contains('stop')) {
      await speak("Exiting tutorial mode.");
      onExitTutorial?.call();
    } else {
      await speak("Sorry, I didn’t understand that tutorial command.");
    }
  }
}
