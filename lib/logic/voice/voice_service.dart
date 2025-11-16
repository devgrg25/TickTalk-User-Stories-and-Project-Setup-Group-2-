import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  VoiceService._internal();
  static final VoiceService instance = VoiceService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();

  bool get isListening => _speech.isListening;

  /// Initialize speech system
  Future<bool> init() async {
    return await _speech.initialize(
      onError: (e) => print("❌ Speech error: $e"),
      onStatus: (status) => print("🎙 Status: $status"),
    );
  }

  /// Start continuous dictation with a callback for text
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
