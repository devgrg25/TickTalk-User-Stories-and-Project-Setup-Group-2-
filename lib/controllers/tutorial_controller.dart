import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

typedef TutorialNavigation = Future<void> Function();
typedef TutorialPagePush = Future<void> Function(Widget page);

class TutorialController {
  final BuildContext context;

  // Navigation helpers provided by MainPage
  final void Function(int tabIndex) goToTab;
  final TutorialPagePush pushPage;

  final FlutterTts _tts = FlutterTts();

  bool _active = false;
  bool _paused = false;
  int _step = 0;

  bool get isActive => _active;
  bool get isPaused => _paused;
  int get step => _step;

  TutorialController({
    required this.context,
    required this.goToTab,
    required this.pushPage,
  });

  // -----------------------------
  // PUBLIC API
  // -----------------------------
  void start() {
    _active = true;
    _paused = false;
    _step = 0;
    _runCurrentStep();
  }

  void pause() {
    _paused = true;
    _tts.stop();
  }

  void resume() {
    if (!_active) return;
    if (!_paused) return;

    _paused = false;
    // This is now the *only* thing that restarts the flow.
    // Since _step was not incremented, it will re-run the
    // *current* step from the beginning.
    _runCurrentStep();
  }

  void stop() {
    _active = false;
    _paused = false;
    _tts.stop();
    _speak("Tutorial skipped. You can now explore the app.");
  }

  // -----------------------------
  // CORE TUTORIAL LOGIC
  // -----------------------------
  Future<void> _runCurrentStep() async {
    // Guard: Don't run if inactive or paused.
    // This is especially important for the resume() call.
    if (!_active || _paused) return;

    switch (_step) {

    // STEP 0 — Create Page
      case 0:
        goToTab(1);
        await _speakWait(
            "This is the Timer Creation page. "
                "Here is a step by step guide on how to use it. "
                "One: enter a timer name. "
                "Two: set work minutes. "
                "Three: set break minutes. "
                "Four: set the number of sets. "
                "You can also say: Start a study timer for four sets with twenty five minutes work and five minutes break."
        );

        if (_paused) return;

        _step++;
        break;

    // STEP 1 — Stopwatch Selector
      case 1:
        goToTab(4);
        await _speakWait(
            "This is the Stopwatch Selector. "
                "Choose Normal Mode for a single stopwatch with voice control, "
                "or Player Mode to track up to six players."
        );

        if (_paused) return;

        _step++;
        break;

    // STEP 2 — Normal Mode Page
      case 2:
        goToTab(3);
        await _speakWait(
            "This is Normal Mode. "
                "Say start to begin, stop to pause, lap to mark a lap, and reset to clear it."
        );
        if (_paused) return;

        _step++;
        break;

      default:
        _active = false;
        await _speakWait(
            "Tutorial complete. You can now explore the app freely."
        );
        break;
    }

    // Continue automatically only if the step completed
    // (wasn't paused) and the tutorial is still active.
    if (_active && !_paused) {
      _runCurrentStep();
    }
  }

  // -----------------------------
  // SPEAK UTILITY
  // -----------------------------
  Future<void> _speak(String text) async {
    try {
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> _speakWait(String text) async {
    await _tts.stop();
    await _tts.setSpeechRate(0.45);
    await _tts.awaitSpeakCompletion(true);

    try {
      if (_active && !_paused) {
        await _tts.speak(text);
      }
    } catch (e) {
      debugPrint("TTS Error: $e");
    }
  }
}