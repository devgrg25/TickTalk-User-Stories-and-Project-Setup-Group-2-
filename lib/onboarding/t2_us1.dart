import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// T2_US1: TTS and Haptic Feedback manager.
/// Handles: playback, repeat, haptic trigger, and clean initialization.
class T2US1TTS {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  bool _hasHapticFired = false;

  /// Initialize the TTS engine
  Future<void> init() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    // Make sure we await completion events
    await _tts.awaitSpeakCompletion(true);

    if (kDebugMode) {
      print("TTS initialized");
    }
  }

  /// Speak the welcome message and trigger haptic once
  Future<void> playWelcomeMessage({Function? onComplete}) async {
    const String message =
        "Welcome to TickTalk. I’ll guide you through setup and features step by step. "
        "Say 'start tutorial' to begin or 'skip' to use the app. "
        "You can also say 'repeat' at any time.";

    // Fire haptic once per playback
    if (!_hasHapticFired) {
      HapticFeedback.lightImpact();
      _hasHapticFired = true;
    }

    _isSpeaking = true;
    if (kDebugMode) print("TTS speaking...");

    await _tts.speak(message);

    // Wait for the speech to finish
    _tts.completionHandler = () async {
      _isSpeaking = false;
      _hasHapticFired = false;
      if (onComplete != null) onComplete();
    };
  }

  /// Stop any ongoing speech
  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
    if (kDebugMode) print("TTS stopped");
  }

  /// Dispose cleanly
  void dispose() {
    _tts.stop();
  }
}

