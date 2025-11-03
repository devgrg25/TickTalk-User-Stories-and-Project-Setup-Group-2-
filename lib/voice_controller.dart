import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ParsedVoiceCommand {
  final String? name;
  final int? workMinutes;
  final int? breakMinutes;
  final int? sets;
  final int? simpleTimerMinutes;

  ParsedVoiceCommand({
    this.name,
    this.workMinutes,
    this.breakMinutes,
    this.sets,
    this.simpleTimerMinutes,
  });
}

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
      await _tts.setSpeechRate(0.5);
      _ttsReady = true;

      // Initialize Speech Recognition
      await _speech.initialize(
        onStatus: (status) {
          debugPrint('🎙 Speech status: $status');
        },
        onError: (error) {
          debugPrint('⚠️ Speech error: $error');
        },
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

  /// Start listening for speech and run optional callback when complete
  Future<void> listenAndRecognize({VoidCallback? onComplete}) async {
    try {
      if (_isListening) return;
      _isListening = true;

      debugPrint('🎤 Listening started...');

      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            final recognized = result.recognizedWords.toLowerCase();
            debugPrint("🎙 Recognized: $recognized");

            if (recognized.contains("start")) {
              speak("Starting timer");
            } else if (recognized.contains("stop")) {
              speak("Stopping all timers");
            } else if (recognized.contains("home")) {
              speak("Navigating to home");
            }  else {
              _handleCommand(recognized);
            }

            stopListening();
            onComplete?.call();
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation, // now set here
          partialResults: true,
          cancelOnError: true,
          autoPunctuation: true,
          enableHapticFeedback: true,
          // Optional timeouts:
          // listenFor: const Duration(seconds: 30),
          // pauseFor: const Duration(seconds: 3),
          // localeId: 'en_US',
        ),
        onSoundLevelChange: (level) {
          // optional: handle mic level UI
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

  /// Handle simple recognized commands
  Future<void> _handleCommand(String recognized) async {
    if (recognized.contains("repeat")) {
      await speak("Repeating that again.");
    } else if (recognized.contains("start stopwatch")) {
      await speak("Starting stopwatch.");
    } else if (recognized.contains("open settings")) {
      await speak("Opening settings.");
    } else if (recognized.contains("stop")) {
      await speak("Okay, stopping now.");
    } else {
      debugPrint("No predefined command matched.");
    }
  }

  /// Dispose resources
  void dispose() {
    _speech.stop();
    _tts.stop();
  }
  //------------------------------- Create Timer -------------------------------

  Future<ParsedVoiceCommand?> interpretCommand(String command) async {
    final text = command.toLowerCase();

    final simpleTimerMatch = RegExp(
        r'(?:start|create)(?: a)?(?: timer)?(?: for)? (\d+)\s*(?:minute|min|mins)?'
    ).firstMatch(text);

    final nameMatch = RegExp(r'start a (\w+) timer|create a (\w+) timer').firstMatch(text);
    final workMatch = RegExp(r'(\d+)\s*(?:minute|min|mins)?\s*(?:work|focus|session)|(?:work|focus|session)\s*(\d+)').firstMatch(text);
    final breakMatch = RegExp(r'(\d+)\s*(?:minute|min|mins)?\s*(?:break|rest)|(?:break|rest)\s*(\d+)').firstMatch(text);
    final setsMatch = RegExp(r'(\d+)\s*(?:set|sets|round|rounds)').firstMatch(text);

    return ParsedVoiceCommand(
      name: nameMatch?.group(1) ?? nameMatch?.group(2),
      workMinutes: int.tryParse(workMatch?.group(1) ?? workMatch?.group(2) ?? ''),
      breakMinutes: int.tryParse(breakMatch?.group(1) ?? breakMatch?.group(2) ?? ''),
      sets: int.tryParse(setsMatch?.group(1) ?? ''),
      simpleTimerMinutes: int.tryParse(simpleTimerMatch?.group(1) ?? ''),
    );
  }

  Future<void> startListening({required Function(ParsedVoiceCommand) onCommand}) async {
    if (!_isInitialized) await initialize(); // initialize only once

    if (_isListening) {
      debugPrint("Already listening, ignoring new start request.");
      return;
    }

    final hasPermission = await _speech.hasPermission;
    if (!hasPermission) {
      final bool granted = await _speech.initialize();
      if (!granted) {
        debugPrint("Speech recognition permission not granted.");
        return;
      }
    }

    _isListening = true;
    debugPrint("🎤 Starting microphone...");

    await _speech.listen(
      onResult: (result) async {
        debugPrint("Heard: ${result.recognizedWords}");
        if (result.finalResult) {
          final parsed = await interpretCommand(result.recognizedWords);
          if (parsed != null) onCommand(parsed);
          await stopListening();
        }
      },
      onSoundLevelChange: (level) {
        // optional: handle mic level for UI
      },
    );
  }

}



