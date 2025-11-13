import 'package:flutter_tts/flutter_tts.dart';

/// ------------------------------------------------------------
/// BASE TTS WRAPPER
/// ------------------------------------------------------------
/// This is a minimal abstraction over FlutterTts that provides
/// simple, consistent voice output used across all modules.
/// ------------------------------------------------------------
class TtsBase {
  final FlutterTts _tts = FlutterTts();

  TtsBase() {
    _init();
  }

  Future<void> _init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.30);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
  }

  /// Speak a given message aloud, cancelling previous speech.
  Future<void> speak(String message) async {
    if (message.trim().isEmpty) return;
    try {
      await _tts.stop();
      await _tts.speak(message);
    } catch (_) {}
  }

  /// Stop any current speech
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// Change voice speed dynamically (optional)
  Future<void> setRate(double rate) async {
    await _tts.setSpeechRate(rate.clamp(0.2, 1.0));
  }

  /// Change pitch dynamically (optional)
  Future<void> setPitch(double pitch) async {
    await _tts.setPitch(pitch.clamp(0.5, 2.0));
  }
}
