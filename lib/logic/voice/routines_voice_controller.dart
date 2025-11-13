import 'package:flutter/material.dart';
import 'base/voice_controller_base.dart';

class RoutinesVoiceController extends VoiceControllerBase {
  VoidCallback? onStartRoutine;
  VoidCallback? onStopRoutine;

  @override
  Future<void> handleCommand(String text) async {
    final lower = text.toLowerCase();

    if (lower.contains('start routine')) {
      await speak("Starting your routine now.");
      onStartRoutine?.call();
    } else if (lower.contains('stop routine')) {
      await speak("Stopping your routine.");
      onStopRoutine?.call();
    } else if (lower.contains('routine')) {
      await speak("You are in the routines section. Say start routine to begin.");
    } else {
      await speak("Sorry, I didn't understand that routine command.");
    }
  }
}
