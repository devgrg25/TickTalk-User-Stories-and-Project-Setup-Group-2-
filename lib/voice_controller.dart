import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// VoiceController manages both speech recognition (STT)
/// and text-to-speech (TTS) features for TickTalk.
/// It’s designed to be lightweight and reliable for accessibility.
class VoiceController {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isInitialized = false;
  bool _isListening = false;
  bool _ttsReady = false;

  /// Initialize both TTS and Speech Recognition
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize TTS
      await _tts.setLanguage('en-US');
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.9);
      _ttsReady = true;

      // Initialize Speech Recognition
      await _speech.initialize(
        onStatus: (status) => debugPrint('🎙 Speech status: $status'),
        onError: (error) => debugPrint('⚠️ Speech error: $error'),
      );

      _isInitialized = true;
      debugPrint("✅ VoiceController initialized successfully");
    } catch (e) {
      debugPrint('❌ VoiceController init error: $e');
    }
  }

  /// Speak any given text aloud using TTS
  Future<void> speak(String text) async {
    if (!_ttsReady) {
      debugPrint('⚠️ TTS not ready yet.');
      return;
    }

    try {
      await _tts.stop(); // stop any previous speech
      await _tts.speak(text);
    } catch (e) {
      debugPrint('❌ TTS speak error: $e');
    }
  }

  /// Stop speech output
  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('❌ TTS stop error: $e');
    }
  }

  /// Start listening for speech and run optional callbacks
  /// [onCommandRecognized] - passes recognized command text to caller
  Future<void> listenAndRecognize({
    Function(String recognizedText)? onCommandRecognized,
    VoidCallback? onComplete,
  }) async {
    try {
      if (_isListening) return;
      _isListening = true;

      debugPrint('🎤 Listening started...');

      await _speech.listen(
        listenMode: stt.ListenMode.confirmation,
        localeId: 'en_US',
        onResult: (result) async {
          if (result.recognizedWords.isEmpty) return;

          final recognized = result.recognizedWords.toLowerCase().trim();
          debugPrint('🗣 Recognized: $recognized');

          // Return recognized text to caller
          if (onCommandRecognized != null) {
            onCommandRecognized(recognized);
          }

          // Built-in responses for some default phrases
          await _handleInternalCommand(recognized);

          if (result.finalResult) {
            await stopListening();
            onComplete?.call();
          }
        },
      );
    } catch (e) {
      debugPrint('❌ Listen error: $e');
      _isListening = false;
      onComplete?.call();
    }
  }

  /// Stop listening manually
  Future<void> stopListening() async {
    if (!_isListening) return;
    try {
      await _speech.stop();
      _isListening = false;
      debugPrint('🛑 Listening stopped.');
    } catch (e) {
      debugPrint('❌ Stop listening error: $e');
    }
  }

  /// Cancel current recognition
  Future<void> cancelListening() async {
    try {
      await _speech.cancel();
      _isListening = false;
    } catch (e) {
      debugPrint('❌ Cancel listening error: $e');
    }
  }

  /// Handles simple voice feedback for recognized commands
  /// (Navigation is handled externally by the UI)
  Future<void> _handleInternalCommand(String recognized) async {
    if (recognized.contains("repeat")) {
      await speak("Repeating that again.");
    } else if (recognized.contains("start stopwatch")) {
      await speak("Starting stopwatch.");
    } else if (recognized.contains("open settings")) {
      await speak("Opening settings.");
    } else if (recognized.contains("stop")) {
      await speak("Okay, stopping now.");
    } else if (recognized.contains("create timer") ||
        recognized == "timer" ||
        recognized.contains("new timer")) {
      // Speak confirmation only — navigation handled by parent
      await speak("Creating a new timer.");
    } else {
      debugPrint("No predefined command matched.");
    }
  }

  /// Dispose resources
  void dispose() {
    _speech.stop();
    _tts.stop();
  }
}
