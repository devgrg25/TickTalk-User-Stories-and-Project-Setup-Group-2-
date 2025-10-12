import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'homepage.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _listening = false;
  bool _speechReady = false;
  String _lastHeard = '…';

  final _welcomeText = """
Welcome to TickTalk. I’ll guide you through setup and features step by step.
Say 'start tutorial' to begin or 'skip' to use the app.
You can also say 'repeat' to hear this again.
""";

  @override
  void initState() {
    super.initState();
    _runWelcome();
  }

  // Plays TTS + starts listening (except on web where a user gesture is required)
  Future<void> _runWelcome() async {
    if (kIsWeb) return; // show buttons for web
    await _speak(_welcomeText);
    await _ensureSpeech();
    await _startListening();
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.9);
      await _tts.setPitch(1.0);
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> _ensureSpeech() async {
    if (_speechReady) return;
    _speechReady = await _speech.initialize(
      onStatus: (s) {
        if (!mounted) return;
        if (s == 'notListening' && _listening) _restartListen();
      },
      onError: (_) {},
    );
    setState(() {});
  }

  Future<void> _startListening() async {
    if (!_speechReady || _listening) return;
    setState(() => _listening = true);
    await _speech.listen(
      localeId: 'en_US',
      listenMode: stt.ListenMode.confirmation,
      partialResults: true,
      onResult: (res) {
        final words = (res.recognizedWords ?? '').toLowerCase().trim();
        if (words.isEmpty) return;
        setState(() => _lastHeard = words);
        _handle(words);
      },
    );
  }

  void _restartListen() async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    _startListening();
  }

  Future<void> _handle(String words) async {
    bool has(String s) => words.contains(s);

    if (has('repeat')) {
      await _speech.cancel();
      await _speak(_welcomeText);
      _restartListen();
      return;
    }

    if (has('start tutorial') || has('start')) {
      await _markSeenAndGoHome();
      return;
    }

    if (has('skip')) {
      await _markSeenAndGoHome();
      return;
    }
  }

  Future<void> _markSeenAndGoHome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcome', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  // Keeps your original button flow
  Future<void> _onGetStarted() => _markSeenAndGoHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Welcome to Tick Talk!',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                const Text('Your new favorite timer app.',
                    style: TextStyle(fontSize: 18)),
                const SizedBox(height: 24),

                // Voice hints
                const Text(
                  'Say:  “start tutorial”   •   “skip”   •   “repeat”',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),

                // Tap-to-listen row (also shows status)
                ListTile(
                  leading: Icon(_listening ? Icons.mic : Icons.mic_none),
                  title: Text(_listening ? "Listening…" : "Tap to listen"),
                  onTap: () async {
                    await _ensureSpeech();
                    await _startListening();
                  },
                ),
                const SizedBox(height: 8),

                // Last heard transcript
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Heard: $_lastHeard'),
                ),

                const SizedBox(height: 24),

                // Web controls (browsers require a user gesture)
                if (kIsWeb) ...[
                  FilledButton.icon(
                    onPressed: () => _speak(_welcomeText),
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Play Welcome'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () async {
                      await _ensureSpeech();
                      await _startListening();
                    },
                    icon: const Icon(Icons.mic),
                    label: const Text('Start / Resume Listening'),
                  ),
                  const SizedBox(height: 8),
                ],

                // Your original CTA (kept)
                ElevatedButton(
                  onPressed: _onGetStarted,
                  child: const Text('Get Started'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
