import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

/// Base class for all voice controllers in TickTalk.
/// Handles both speech recognition and text-to-speech,
/// while leaving command handling to subclasses.
abstract class VoiceControllerBase {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;

  /// Abstract method all child voice controllers must implement.
  Future<void> handleCommand(String text);

  VoiceControllerBase() {
    _initTts();
  }

  // ---------- INIT ----------
  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.30);
    await _tts.setVolume(1.0);
  }

  // ---------- SPEAK ----------
  Future<void> speak(String text) async {
    try {
      await _tts.stop(); // stop any ongoing speech
      await _tts.speak(text);
    } catch (e) {
      debugPrint("⚠️ TTS Error: $e");
    }
  }

  // ---------- LISTEN ONCE ----------
  /// Starts listening for a single voice input and returns the recognized text.
  Future<String?> listenOnce() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) => debugPrint("🎙 Speech status: $status"),
        onError: (error) => debugPrint("❌ Speech error: $error"),
      );

      if (!available) {
        await speak("Speech recognition is not available on this device.");
        return null;
      }

      final completer = Completer<String?>();
      String? recognizedText;

      _isListening = true;
      debugPrint("🎧 Listening started...");

      await _speech.listen(
        listenMode: stt.ListenMode.confirmation,
        onResult: (result) {
          if (result.finalResult) {
            recognizedText = result.recognizedWords;
            debugPrint("🗣 Heard: ${recognizedText ?? '(empty)'}");
            if (!completer.isCompleted) completer.complete(recognizedText);
          }
        },
      );

      // Timeout safety — auto stop after 8 seconds
      Future.delayed(const Duration(seconds: 8), () {
        if (!_isListening) return;
        debugPrint("⏰ Timeout: stopping listening after 8 seconds.");
        stopListening();
        if (!completer.isCompleted) completer.complete(recognizedText);
      });

      final result = await completer.future;
      _isListening = false;
      await _speech.stop();

      debugPrint("🎤 Final recognized: $result");
      return (result == null || result.isEmpty) ? null : result;
    } catch (e, st) {
      debugPrint("❌ Error in listenOnce: $e\n$st");
      _isListening = false;
      return null;
    }
  }

  // ---------- STOP LISTENING ----------
  Future<void> stopListening() async {
    try {
      if (!_isListening) return;
      debugPrint("🛑 Stopping listening...");
      await _speech.stop();
    } catch (e) {
      debugPrint("⚠️ stopListening error: $e");
    } finally {
      _isListening = false;
    }
  }

  // ---------- STATE ----------
  bool get isListening => _isListening;

  // ---------- CLEANUP ----------
  void dispose() {
    _speech.stop();
    _tts.stop();
  }
}
