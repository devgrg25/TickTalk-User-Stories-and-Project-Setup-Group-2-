import 'package:flutter/cupertino.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;

  final FlutterTts tts = FlutterTts();

  TTSService._internal();

  Future<void> initialize() async {
    try {
      await tts.setEngine("com.google.android.tts");
      await tts.setLanguage("en-US");
      await tts.setSpeechRate(0.9);
      await tts.setPitch(1.0);
      await tts.awaitSpeakCompletion(true);

      // Pre-warm
      await tts.speak(" ");
      await tts.stop();
    } catch (e) {
      debugPrint("Error initializing TTS: $e");
    }
  }

  Future<void> speak(String text) async {
    // Guard clause for empty or null text
    if (text.isEmpty) return;

    try {
      // Stop any previous speech to allow for interruptions
      await tts.stop();
      // Speak the new text
      await tts.speak(text);
    } catch (e) {
      debugPrint("Error during TTS speak: $e");
    }
  }

  Future<void> stop() async {
    try {
      await tts.stop();
    } catch (e) {
      debugPrint("Error stopping TTS: $e");
    }
  }
}