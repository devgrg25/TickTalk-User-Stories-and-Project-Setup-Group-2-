import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_shell/main_shell.dart';
import '../../app_shell/voice_mic_bar.dart';

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
Say “start tutorial” to begin the guided tour, “skip” to continue to the app, or “repeat” to hear this again.
Tap the microphone at the bottom of your screen to speak, then tap again to stop.
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
      partialResults: true,
      localeId: 'en_US',
      listenMode: stt.ListenMode.confirmation,
      onResult: (res) {
        if (!mounted) return;
        final words = res.recognizedWords.trim();
        if (words.isEmpty) return;
        setState(() => _lastHeard = words);
        if (res.finalResult) _handle(words.toLowerCase());
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

  Future<void> _goToApp({required bool startTutorial}) async {
    try {
      await _speech.stop();
      await _tts.stop();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcome', true);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainShell(
          startTutorial: startTutorial, // 👈 tells MainShell to run tutorial or not
        ),
      ),
    );
  }

  Future<void> _handle(String words) async {
    bool has(String s) => words.contains(s);

    // repeat intro
    if (has('repeat')) {
      await _tts.stop();
      await _tts.speak(_welcomeText);
      return;
    }

    // ✅ Only here: "start" / "start tutorial" trigger guided tutorial
    if (has('start tutorial') || words.trim() == 'start') {
      await _goToApp(startTutorial: true);
      return;
    }

    // skip / continue without tutorial
    if (has('skip') || has('continue')) {
      await _goToApp(startTutorial: false);
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
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 160),
              children: [
                const SizedBox(height: 8),
                Text(
                  'Your new favorite timer app.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 18),
                Text(
                  'Say: “start tutorial”, “skip”, or “repeat”.\n\n'
                      'Tap the microphone below to speak, and tap again to stop.',
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
                            Text(
                              'Last heard:',
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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

            // --------- Bottom mic (shared component) ---------
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: VoiceMicBar(
                  isListening: _listening,
                  onTap: () async {
                    await _triggerFeedback();
                    if (_listening) {
                      await _stopListening();
                    } else {
                      await _tts.stop();
                      await _startListening();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
