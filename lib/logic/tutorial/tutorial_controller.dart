import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

typedef TutorialNavigation = Future<void> Function();
typedef TutorialPagePush = Future<void> Function(Widget page);

class TutorialController {
  final BuildContext context;

  // Navigation helpers provided by MainShell
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
    debugPrint("📘 Tutorial start()");
    _active = true;
    _paused = false;
    _step = 0;

    // Make sure any previous TTS (e.g., welcome message) is stopped first,
    // then start the first step.
    _prepareAndRun();
  }

  Future<void> _prepareAndRun() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _runCurrentStep();
  }

  void pause() {
    debugPrint("📘 Tutorial pause()");
    _paused = true;
    _tts.stop();
  }

  void resume() {
    debugPrint("📘 Tutorial resume()");
    if (!_active) return;
    if (!_paused) return;

    _paused = false;
    _runCurrentStep();
  }

  void stop() {
    debugPrint("📘 Tutorial stop()");
    _active = false;
    _paused = false;
    _tts.stop();
    _speak("Tutorial skipped. You can now explore the app.");
  }

  // -----------------------------
  // CORE TUTORIAL LOGIC
  // -----------------------------
  Future<void> _runCurrentStep() async {
    if (!_active || _paused) {
      debugPrint("📘 _runCurrentStep aborted: active=$_active, paused=$_paused");
      return;
    }

    debugPrint("📘 _runCurrentStep: step=$_step");

    switch (_step) {
    // STEP 0 — Timer Creation Page (Timer tab = index 1)
      case 0:
        await Future.delayed(const Duration(seconds: 1));
        debugPrint("📘 Step 0 → Timer tab (index 1)");
        goToTab(1);

        await _speakWait(
          "This is the Timer Creation page. "
              "Here is a step by step guide on how to use it. "
              "One: enter a timer name. "
              "Two: set work minutes. "
              "Three: set break minutes. "
              "Four: set the number of sets. "
              "You can also say: Start a study timer for four sets "
              "with twenty five minutes work and five minutes break.",
        );

        if (_paused || !_active) return;

        // Small delay so user can see this tab before jumping

        _step++;
        break;

    // STEP 1 — Stopwatch Selector (Stopwatch tab = index 3)
      case 1:
        debugPrint("📘 Step 1 → Stopwatch tab (index 3), selector explanation");
        goToTab(3);

        await _speakWait(
          "This is the Stopwatch Selector. "
              "Choose Normal Mode for a single stopwatch with voice control, "
              "or Player Mode to track up to six players.",
        );

        if (_paused || !_active) return;

        await Future.delayed(const Duration(seconds: 1));

        _step++;
        break;

    // STEP 2 — Normal Mode (still on Stopwatch tab = index 3)
      case 2:
        debugPrint("📘 Step 2 → Stopwatch tab (index 3), normal mode explanation");
        goToTab(3);

        await _speakWait(
          "This is Normal Mode. "
              "Say start to begin, stop to pause, lap to mark a lap, "
              "and reset to clear it.",
        );

        if (_paused || !_active) return;

        await Future.delayed(const Duration(seconds: 1));

        _step++;
        break;

    // FINISH — go to Home and announce
      default:
        debugPrint("📘 Step default → Home tab (index 0), tutorial complete");
        _active = false;

        // Go to Home tab (index 0) after tutorial
        goToTab(0);

        await _speakWait(
          "Tutorial complete. You are now on the Home page. "
              "You can now explore the app freely.",
        );
        return;
    }

    // Move to the next step automatically
    if (_active && !_paused) {
      _runCurrentStep();
    }
  }

  // -----------------------------
  // SPEAK UTILITY
  // -----------------------------
  Future<void> _speak(String text) async {
    try {
      debugPrint("📘 TTS _speak: $text");
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> _speakWait(String text) async {
    debugPrint("📘 TTS _speakWait: $text");

    if (!_active || _paused) {
      debugPrint("📘 TTS skipped: active=$_active, paused=$_paused");
      return;
    }

    try {
      // Configure TTS (only affects how speak() behaves)
      await _tts.setSpeechRate(0.45);
      await _tts.awaitSpeakCompletion(true);

      if (_active && !_paused) {
        final result = await _tts.speak(text);
        debugPrint("📘 TTS speak result: $result");
      }
    } catch (e) {
      debugPrint("TTS Error: $e");
    }
  }
}