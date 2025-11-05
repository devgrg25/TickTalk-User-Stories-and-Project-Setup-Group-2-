import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class VoiceController {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isListening = false;
  bool get isListening => _isListening;

  // Callback storage to handle status updates
  VoidCallback? _onListeningComplete;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize TTS
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.9); // Slightly faster than default for snappiness
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true); // Wait for speech to finish before continuing

      // 2. Initialize STT
      // We initialize it here once to get permissions and readiness.
      bool available = await _speech.initialize(
        onError: (error) => debugPrint('STT Error: $error'),
        onStatus: (status) => _onStatusChanged(status),
      );

      _isInitialized = available;
      debugPrint("VoiceController initialized: $_isInitialized");
    } catch (e) {
      debugPrint("VoiceController initialization failed: $e");
      _isInitialized = false;
    }
  }

  void _onStatusChanged(String status) {
    debugPrint('🎙 Speech status: $status');
    if (status == 'notListening' || status == 'done') {
      _isListening = false;
      // If we have a completion callback waiting, fire it now.
      if (_onListeningComplete != null) {
        _onListeningComplete!();
        _onListeningComplete = null; // Clear it after firing
      }
    } else if (status == 'listening') {
      _isListening = true;
    }
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    try {
      // Stop any current speech or listening before speaking new text
      if (_isListening) await stopListening();
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint("TTS Speak Error: $e");
    }
  }

  Future<void> listenAndRecognize({
    required Function(String) onCommandRecognized,
    VoidCallback? onComplete,
  }) async {
    if (!_isInitialized) {
      debugPrint("Cannot listen: VoiceController not initialized.");
      return;
    }

    // Store the completion callback for when the status changes to 'done'
    _onListeningComplete = onComplete;

    try {
      // Ensure we aren't already listening
      if (_isListening) {
        await _speech.stop();
      }

      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            final command = result.recognizedWords.trim();
            if (command.isNotEmpty) {
              debugPrint("🗣 Recognized final command: $command");
              onCommandRecognized(command);
            }
          }
        },
        localeId: 'en_US',
        cancelOnError: true,
        partialResults: false, // Set to true if you want real-time feedback
        listenMode: stt.ListenMode.confirmation, // Optimized for short commands
        listenFor: const Duration(seconds: 10), // Stop after 10s of silence
        pauseFor: const Duration(seconds: 3),   // Wait 3s after speech pauses before finalizing
      );
    } catch (e) {
      debugPrint("STT Listen Error: $e");
      // If it fails to start, fire complete immediately so UI doesn't get stuck red
      if (onComplete != null) onComplete();
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  void dispose() {
    _speech.cancel();
    _tts.stop();
  }
}