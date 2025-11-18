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

  // -------------------------------------------------------------
  // Single-utterance capture for questions: yes/no, duration, etc.
  // -------------------------------------------------------------
  Future<String?> listenOnce({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!_enabled && !(await init())) return null;

    _listening = true;

    String finalText = "";
    bool done = false;

    await _stt.listen(
      listenFor: timeout,
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
      onResult: (result) {
        final text = result.recognizedWords.trim();
        if (text.isNotEmpty) {
          finalText = text;
        }
        if (result.finalResult) {
          done = true;
        }
      },
    );

    final startTime = DateTime.now();
    while (!done && DateTime.now().difference(startTime) < timeout) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    await _stt.stop();
    _listening = false;

    return finalText.isEmpty ? null : finalText;
  }

  // -------------------------------------------------------------
  // Yes/No Confirmation for saving, starting, etc.
  // -------------------------------------------------------------
  Future<bool?> listenForConfirmation({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final heard = await listenOnce(timeout: timeout);
    if (heard == null) return null;

    final t = heard.toLowerCase();

    // Positive confirmations
    if (t.contains("yes") ||
        t.contains("yeah") ||
        t.contains("yep") ||
        t.contains("sure") ||
        t.contains("please do") ||
        t.contains("go ahead") ||
        t.contains("do it") ||
        t.contains("okay") ||
        t.contains("ok") ||
        t.contains("confirm") ||
        t.contains("save")) {
      return true;
    }

    // Negative confirmations
    if (t.contains("no") ||
        t.contains("nope") ||
        t.contains("don't") ||
        t.contains("do not") ||
        t.contains("cancel") ||
        t.contains("stop") ||
        t.contains("not")) {
      return false;
    }

    return null;
  }

  // -------------------------------------------------------------
  // Continuous dictation — used for main push-to-talk mode
  // -------------------------------------------------------------
  Future<void> start({
    required Function(String text) onResult,
  }) async {
    if (!_enabled && !(await init())) return;

    _listening = true;

    await _stt.listen(
      listenMode: ListenMode.dictation,
      partialResults: true,
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(seconds: 10),
      onResult: (result) {
        final text = result.recognizedWords.trim();
        if (text.isNotEmpty) onResult(text);
      },
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
