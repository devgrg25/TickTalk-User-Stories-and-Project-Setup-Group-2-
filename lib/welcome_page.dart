import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'MainPage.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});
  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _listening = false;
  bool _hasPlayedWelcome = false;
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

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.50);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {}
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

  Future<void> _initSpeech() async {
    try {
      await _speech.initialize(
        onStatus: (_) => setState(() => _listening = _speech.isListening),
        onError: (_) => setState(() => _listening = false),
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
      onResult: (res) async {
        if (!mounted) return;
        final words = res.recognizedWords.trim();
        if (words.isEmpty) return;
        setState(() => _lastHeard = words);
        if (res.finalResult) await _handle(words.toLowerCase());
      },
    );
  }

  Future<void> _stopListening() async {
    try { await _speech.stop(); } catch (_) {}
    if (!mounted) return;
    setState(() => _listening = false);
  }

  Future<void> _setSeen() async {
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
    if (has('skip') || has('continue')) {
      await _speech.stop();
      await _tts.stop();
      if (!mounted) return;
      await _setSeen();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
      return;
    }
    if (has('start tutorial') || has('start the tutorial') || has('start')) {
      await _speech.stop();
      await _tts.stop();
      if (!mounted) return;
      await _setSeen();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainPage(tutorialMode: true)),
      );
      return;
    }
  }

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

  @override
  Widget build(BuildContext context) {
    // ❗ Opt out from global scaling here
    final fixed = MediaQuery.of(context).copyWith(textScaleFactor: 1.0);
    return MediaQuery(
      data: fixed,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Welcome to TickTalk!'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 140),
                children: [
                  const SizedBox(height: 8),
                  Text('Your new favorite timer app.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium),
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
                        const Icon(Icons.hearing, color: Color(0xFF007BFF)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Last heard:',
                                  style: TextStyle(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text(_lastHeard.isEmpty ? '…' : _lastHeard,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // bottom mic
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
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mic, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "Tap to Speak",
                            style: TextStyle(
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
      ),
    );
  }
}
