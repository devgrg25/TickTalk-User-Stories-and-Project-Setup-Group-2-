import 'package:speech_to_text/speech_to_text.dart';

class VoiceSttService {
  VoiceSttService._();
  static final VoiceSttService instance = VoiceSttService._();

  final SpeechToText _stt = SpeechToText();
  bool _enabled = false;
  bool _listening = false;

  bool get isListening => _listening;

  Future<bool> init() async {
    if (_enabled) return true;
    _enabled = await _stt.initialize();
    return _enabled;
  }

  Future<void> start({
    required Function(String text) onResult,
  }) async {
    if (!_enabled) {
      _enabled = await init();
      if (!_enabled) return;
    }

    _listening = true;

    await _stt.listen(
      onResult: (result) {
        final text = result.recognizedWords.trim();
        if (text.isNotEmpty) {
          onResult(text);
        }
      },
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(seconds: 8),
      partialResults: true,
    );
  }

  Future<void> stop() async {
    _listening = false;
    await _stt.stop();
  }

  Future<void> cancel() async {
    _listening = false;
    await _stt.cancel();
  }
}
