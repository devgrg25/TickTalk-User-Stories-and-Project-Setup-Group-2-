import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'homepage.dart';
import 'stopwatcht2us2.dart';

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
  bool _ttsReady = false;
  String _lastHeard = '…';
  bool _ttsSpeaking = false;

  final _welcomeText = """
Welcome to TickTalk. I'll guide you through setup and features step by step.
Say 'start tutorial' to begin or 'skip' to use the app.
You can also say 'repeat' to hear this again.
Try saying 'start the stopwatch' to open the stopwatch.
""";

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    if (kIsWeb) {
      setState(() => _ttsReady = true);
      await _ensureSpeech();
      return;
    }

    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      setState(() => _ttsReady = true);
    } catch (e) {
      debugPrint('❌ TTS init error: $e');
    }

    await _ensureSpeech();

    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) await _playWelcome();
    }
  }

  Future<void> _playWelcome() async {
    await _speak(_welcomeText);
  }

  Future<void> _speak(String text) async {
    if (!_ttsReady) return;
    try {
      _ttsSpeaking = true;
      await _tts.stop();
      await _tts.setSpeechRate(0.5);
      await _tts.speak(text);
      _ttsSpeaking = false;
    } catch (e) {
      debugPrint('❌ TTS speak error: $e');
    }
  }

  Future<void> _ensureSpeech() async {
    if (_speechReady) return;
    try {
      _speechReady = await _speech.initialize(
        onStatus: (s) {
          debugPrint('🎙️ Speech status: $s');
          if (s == 'notListening' && _listening) {
            setState(() => _listening = false);
          }
        },
        onError: (error) {
          debugPrint('⚠️ Speech error: $error');
          setState(() => _listening = false);
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('❌ Speech init error: $e');
    }
  }

  Future<void> _startListening() async {
    if (!_speechReady || _listening || _ttsSpeaking) return;

    setState(() => _listening = true);

    try {
      await _speech.listen(
        localeId: 'en_US',
        listenMode: stt.ListenMode.confirmation,
        partialResults: true,
        onResult: (res) {
          final words = (res.recognizedWords ?? '').toLowerCase().trim();
          if (words.isEmpty) return;

          setState(() => _lastHeard = words);
          _handleCommand(words);
        },
      );
    } catch (e) {
      debugPrint('❌ Listen error: $e');
      setState(() => _listening = false);
    }
  }

  Future<void> _stopListening() async {
    setState(() => _listening = false);
    await _speech.stop();
  }

  Future<void> _handleCommand(String words) async {
    bool has(String s) => words.contains(s);

    // prevent it from hearing itself
    if (_ttsSpeaking) return;

    if (has('repeat')) {
      await _stopListening();
      await _speak(_welcomeText);
      return;
    }

    if (has('start tutorial') || has('start')) {
      await _stopListening();
      await _markSeenAndGoHome();
      return;
    }

    if (has('skip')) {
      await _stopListening();
      await _markSeenAndGoHome();
      return;
    }

    if (has('stopwatch') || has('start stopwatch')) {
      await _stopListening();
      await _speak("Opening stopwatch.");
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const StopwatchT2US2()),
        );
      }
    }
  }

  Future<void> _markSeenAndGoHome() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenWelcome', true);
    } catch (e) {
      debugPrint('❌ SharedPreferences error: $e');
    }

    if (!mounted) return;

    // Delay navigation slightly so speech completes first
    await _tts.stop();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );

    // Say this once homepage loads
    Future.delayed(const Duration(seconds: 1), () async {
      await _tts.speak("You are now on the home page.");
    });
  }

  @override
  void dispose() {
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  Text(
                    'Welcome to TickTalk!',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your new favorite timer app.',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Say: "start tutorial" • "skip" • "repeat"\n"start stopwatch"',
                    textAlign: TextAlign.center,
                    style:
                    TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            _listening ? Icons.mic : Icons.mic_none,
                            size: 32,
                            color: _listening ? Colors.red : Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _listening ? 'Listening…' : 'Ready to listen',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Last heard:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _lastHeard,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _speechReady && !_listening
                        ? _startListening
                        : null,
                    icon: const Icon(Icons.mic),
                    label: const Text('Tap to Listen'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _markSeenAndGoHome,
                    child: const Text('Skip for Now'),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
            // bottom mic bar like homepage
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: _listening ? _stopListening : _startListening,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  color:
                  _listening ? Colors.redAccent : const Color(0xFF007BFF),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _listening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _listening
                            ? "Listening... Tap to stop"
                            : "Tap to Speak",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
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
