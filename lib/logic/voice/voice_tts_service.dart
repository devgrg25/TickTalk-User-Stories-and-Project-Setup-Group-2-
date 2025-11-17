import 'package:flutter_tts/flutter_tts.dart';

class VoiceTtsService {
  VoiceTtsService._internal();
  static final VoiceTtsService instance = VoiceTtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;

    await _tts.setSpeechRate(0.65);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> speak(String message) async {
    await _init();
    await _tts.stop(); // interrupt previous
    await _tts.speak(message);
  }
}
