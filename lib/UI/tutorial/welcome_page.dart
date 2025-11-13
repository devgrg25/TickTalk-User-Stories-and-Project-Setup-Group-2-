import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import '../homepage.dart';
import '../timers/create_timer_screen.dart';
import '../stopwatch/stopwatchmodeselecter.dart';
import '../stopwatch/stopwatch_normal_mode.dart';
import '../MainPage.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  // ---- TTS ----
  final FlutterTts _tts = FlutterTts();
  bool _hasPlayedWelcome = false;

  // ---- Speech ----
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _listening = false;
  String _lastHeard = '…';

  final String _welcomeText = '''
Welcome to TickTalk. I’ll guide you through setup and features step by step.
Say “start tutorial” to begin, “skip” to continue to the app, or “repeat” to hear this again.
Tap the blue bar at the bottom of your screen to speak, then tap again to stop.
''';

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSpeech();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePlayWelcome());
  }

  // --------------------- T T S --------------------- //
  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.50);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {}
    _maybePlayWelcome();
  }

  Future<void> _maybePlayWelcome() async {
    if (!mounted || _hasPlayedWelcome) return;
    await Future.delayed(const Duration(milliseconds: 250));
    try {
      await _tts.stop();
      await _tts.speak(_welcomeText);
      _hasPlayedWelcome = true;
    } catch (_) {}
  }

  // ------------------ S P E E C H ------------------ //
  Future<void> _initSpeech() async {
    try {
      await _speech.initialize(
        onStatus: (s) {
          if (!mounted) return;
          if (s == 'done' || s == 'notListening') {
            setState(() => _listening = false);
          }
        },
        onError: (_) {
          if (!mounted) return;
          setState(() => _listening = false);
        },
      );
    } catch (_) {}
  }

  Future<void> _startListening() async {
    if (!await _speech.hasPermission && !(await _speech.initialize())) return;
    if (!mounted) return;

    setState(() => _listening = true);

    await _speech.listen(
      listenMode: stt.ListenMode.confirmation,
      partialResults: true,
      localeId: 'en_US',
      onResult: (res) {
        if (!mounted) return;
        final words = res.recognizedWords.trim();
        if (words.isEmpty) return;
        setState(() => _lastHeard = words);
        if (res.finalResult) _handle(words.toLowerCase()); // act only on final result
      },
    );
  }

  Future<void> _stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _listening = false);
  }

  // ------------------ N A V I G A T I O N ------------------ //
  Future<void> _goHome() async {
    try {
      await _speech.stop();
      await _tts.stop();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainPage()),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcome', true);
  }

  Future<void> _handle(String words) async {
    bool has(String s) => words.contains(s);

    if (has('repeat')) {
      await _tts.stop();
      await _tts.speak(_welcomeText);
      return;
    }

    // ✅ On "start" / "start tutorial": Create Timer → speak → Stopwatch selector → speak → Normal Mode → speak
    if (has('start tutorial') || has('start the tutorial') || has('start')) {
      try {
        await _speech.stop();
        await _tts.stop();
      } catch (_) {}

      if (!mounted) return;

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainPage(tutorialMode: true)),
      );
      return;
      /*
      // 1) Go to Create Timer page immediately
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CreateTimerScreen()),
      );

      // Speak *on* Create Timer page
      const createGuide =
          'This is the timer creation page '
          'Here is a step by step guide on how to use it'
          'One: enter a timer name, for example “study”. '
          'Two: set work minutes, for example twenty five. '
          'Three: set break minutes, for example five. '
          'Four: set number of sets, for example four. '
          'You can also say a single sentence like: '
          'Start a study timer for four sets with twenty five minute work and five minute break.';
      await Future.delayed(const Duration(milliseconds: 350));
      try { await _tts.speak(createGuide); } catch (_) {}

      // 2) Open Stopwatch Mode Selector
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const StopwatchModeSelector()),
      );

      // Speak *on* Stopwatch selector page
      const selectorGuide =
          'This is the stopwatch selector. '
          'Choose Normal Mode for a single stopwatch with voice control, '
          'or Player Mode to track up to six players at once.';
      await Future.delayed(const Duration(milliseconds: 350));
      try { await _tts.speak(selectorGuide); } catch (_) {}

// 3) Open Normal Mode stopwatch
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const StopwatchNormalMode(autoStart: false)),
      );

// Speak *on* Normal Mode page (slower rate), then restore default
      const normalGuide =
          'This is Normal Mode. Say "start" to begin, "stop" to pause, "lap" to mark a lap, and "reset" to clear. '
          'You can also use the buttons on screen.';

      await Future.delayed(const Duration(milliseconds: 350)); // ensure page is shown
      try {
        await _tts.setSpeechRate(0.3);     // slower just for this page
        await _tts.setPitch(1.0);
        await _tts.awaitSpeakCompletion(true);
        await _tts.speak(normalGuide);
      } catch (_) {
        // ignore TTS errors
      } finally {
        await _tts.setSpeechRate(0.50);     // restore your global rate
      }

      if (!mounted) return;

      return;*/
    }


    if (has('skip') || has('continue')) {
      await _goHome();
      return;
    }
  }

  // Optional tactile feedback
  Future<void> _triggerFeedback() async {
    try {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  // -------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Welcome to TickTalk!'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // --------- Main content ---------
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 140),
              children: [
                const SizedBox(height: 8),
                Text(
                  'Your new favorite timer app.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 18),
                Text(
                  'Say:  “start tutorial” , “skip”  , “repeat”\n\n'
                      'Tap the blue bar below to speak, and tap again to stop.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 30),

                // Heard box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.hearing, color: cs.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Last heard:',
                                style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Text(
                              _lastHeard.isEmpty ? '…' : _lastHeard,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // --------- Bottom full-width mic bar (same as HomeScreen) ---------
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: GestureDetector(
                  onTap: () async {
                    await _triggerFeedback();
                    if (_listening) {
                      await _stopListening();
                    } else {
                      await _tts.stop();
                      await _startListening();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    color: _listening ? Colors.redAccent : const Color(0xFF007BFF),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _listening ? Icons.mic : Icons.mic_off,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _listening
                              ? "Listening... Tap to stop"
                              : "Tap to Speak",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
