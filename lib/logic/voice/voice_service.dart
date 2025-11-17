import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  VoiceService._internal();
  static final VoiceService instance = VoiceService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool get isListening => _speech.isListening;

  /// Initialize speech + TTS
  Future<bool> init() async {
    await _tts.setSpeechRate(0.65); // Default speed (adjustable)
    await _tts.setPitch(1.0);

    return await _speech.initialize(
      onError: (e) => print("❌ Speech error: $e"),
      onStatus: (status) => print("🎙 Status: $status"),
    );
  }

  /// Speak text
  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  /// Start continuous dictation with a callback
  Future<void> startListening(Function(String text) onResult) async {
    await _speech.listen(
      onResult: (result) => onResult(result.recognizedWords),
      cancelOnError: true,
      partialResults: true,
      listenMode: stt.ListenMode.dictation,
    );
  }

  /// Stop listening
  Future<void> stop() async {
    await _speech.stop();
  }
}
