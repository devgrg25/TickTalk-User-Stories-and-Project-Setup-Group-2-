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

  int? parseNumber(String text) {
    const numberWords = {
      'zero': 0,
      'one': 1,
      'two': 2,
      'three': 3,
      'four': 4,
      'five': 5,
      'six': 6,
      'seven': 7,
      'eight': 8,
      'nine': 9,
      'ten': 10,
      'eleven': 11,
      'twelve': 12,
      'thirteen': 13,
      'fourteen': 14,
      'fifteen': 15,
      'sixteen': 16,
      'seventeen': 17,
      'eighteen': 18,
      'nineteen': 19,
      'twenty': 20
    };

    text = text.toLowerCase().trim();
    if (numberWords.containsKey(text)) {
      return numberWords[text];
    }

    // Also allow numeric input
    final numericMatch = RegExp(r'\d+').firstMatch(text);
    if (numericMatch != null) {
      return int.parse(numericMatch.group(0)!);
    }

    return null;
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

    final nameMatch = RegExp(r'start a (\w+) timer|create a (\w+) timer').firstMatch(text);
    final workMatch = RegExp(
        r'(?:for\s*)?(\d+)\s*(?:minute|min|mins)?\s*(?:of\s*)?(?:work|focus|session|timer||)?'
    ).firstMatch(text);
    final breakMatch = RegExp(r'(\d+)\s*(?:minute|min|mins)?\s*(?:break|rest)|(?:break|rest)\s*(\d+)').firstMatch(text);
    final setsMatch = RegExp(
        r'(\d+|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty)\s*(?:set|sets|round|rounds)'
    ).firstMatch(text);

    if (workMatch != null) {
      final name = nameMatch?.group(1) ?? nameMatch?.group(2);
      final workMinutes = int.tryParse(workMatch.group(1) ?? workMatch.group(2) ?? '');
      final breakMinutes = int.tryParse(breakMatch?.group(1) ?? breakMatch?.group(2) ?? '');
      final sets = int.tryParse(setsMatch?.group(1) ?? '');

      return ParsedVoiceCommand(
        name: name,
        workMinutes: workMinutes,
        breakMinutes: breakMinutes,
        sets: sets,
      );
    }
  }

  Future<void> startListeningForTimer({
    required Function(ParsedVoiceCommand) onCommand,
  }) async {
    if (!_isInitialized) await initialize();

    if (_isListening) {
      debugPrint("Already listening...");
      return;
    }

    _isListening = true;

    await _speech.listen(
      onResult: (result) async {
        if (result.finalResult) {
          final parsed = await interpretCommand(result.recognizedWords);
          debugPrint(result.recognizedWords);
          if (parsed != null) onCommand(parsed);
          await stopListening();
        }
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        autoPunctuation: true,
        enableHapticFeedback: true,
      ),
    );
  }

  Future<void> startListeningForControl({
    required void Function(String command) onCommand,
  }) async {
    await initialize();
    await _speech.listen(
      listenFor: const Duration(seconds: 5),
      onResult: (result) {
        if (result.finalResult) {
          final words = result.recognizedWords.toLowerCase();
          onCommand(words);
        }
      },
    );
  }
}



