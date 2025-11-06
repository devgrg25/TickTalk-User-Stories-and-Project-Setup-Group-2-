import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

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
      await _tts.setSpeechRate(0.9);
      await _tts.awaitSpeakCompletion(true);
      _ttsReady = true;

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



