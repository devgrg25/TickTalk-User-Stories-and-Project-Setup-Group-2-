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
  int _retryCount = 0;
  static const int _maxRetries = 3;

  final _welcomeText = """
Welcome to TickTalk. I'll guide you through setup and features step by step.
Say 'start tutorial' to begin or 'skip' to use the app.
You can also say 'repeat' to hear this again.
Try saying 'hey ticktalk start the stopwatch' to open the stopwatch.
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
      await _tts.setSpeechRate(0.5); // Reduced from 0.9 to 0.5 for slower speech
      await _tts.setPitch(1.0);
      setState(() => _ttsReady = true);
    } catch (e) {
      debugPrint('❌ TTS init error: $e');
    }

    await _ensureSpeech();

    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await _playWelcome();
      }
    }
  }

  Future<void> _playWelcome() async {
    await _speak(_welcomeText);
    await _startListening();
  }

  Future<void> _speak(String text) async {
    if (!_ttsReady) return;
    try {
      await _tts.stop();
      await _tts.setSpeechRate(0.5); // Reduced from 0.9 to 0.5 for slower speech
      await _tts.speak(text);
    } catch (e) {
      debugPrint('❌ TTS speak error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not play audio: $e')),
        );
      }
    }
  }

  Future<void> _ensureSpeech() async {
    if (_speechReady) return;

    try {
      _speechReady = await _speech.initialize(
        onStatus: (s) {
          if (!mounted) return;
          debugPrint('🎙️ Speech status: $s');
          if (s == 'notListening' && _listening) {
            _handleListeningStop();
          }
        },
        onError: (error) {
          debugPrint('⚠️ Speech error: $error');
          if (!mounted) return;
          if (_listening) {
            _handleListeningStop();
          }
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('❌ Speech init error: $e');
    }
  }

  Future<void> _startListening() async {
    if (!_speechReady || _listening) return;

    _retryCount = 0;
    setState(() => _listening = true);

    try {
      await _speech.listen(
        localeId: 'en_US',
        listenMode: stt.ListenMode.confirmation,
        partialResults: true,
        onResult: (res) {
          if (!mounted) return;
          final words = (res.recognizedWords ?? '').toLowerCase().trim();
          if (words.isEmpty) return;

          setState(() => _lastHeard = words);
          _handle(words);
        },
      );
    } catch (e) {
      debugPrint('❌ Listen error: $e');
      if (mounted) {
        setState(() => _listening = false);
      }
    }
  }

  void _handleListeningStop() {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      _restartListen();
    } else {
      if (mounted) {
        setState(() => _listening = false);
        debugPrint('❌ Max retries reached');
      }
    }
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

    // ✨ ADDED: Stopwatch command from welcome page
    if (has('hey tick talk') && has('start the stopwatch') ||
        has('hey tick talk') && has('start stopwatch') ||
        has('start the stopwatch') ||
        has('open stopwatch')) {
      await _speak("Starting stopwatch.");
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const StopwatchT2US2()),
        );
      }
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
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenWelcome', true);
    } catch (e) {
      debugPrint('❌ SharedPreferences error: $e');
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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

                  // Voice hints
                  const Text(
                    'Say: "start tutorial" • "skip" • "repeat"\n"hey ticktalk start the stopwatch"',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  // Listening status card
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

                  // Last heard transcript
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

                  // Web controls
                  if (kIsWeb) ...[
                    FilledButton.icon(
                      onPressed: _ttsReady ? _playWelcome : null,
                      icon: const Icon(Icons.volume_up),
                      label: const Text('Play Welcome'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _speechReady
                          ? () async {
                        await _startListening();
                      }
                          : null,
                      icon: const Icon(Icons.mic),
                      label: const Text('Start Listening'),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Manual tap listener
                  OutlinedButton.icon(
                    onPressed: _speechReady && !_listening
                        ? () async {
                      await _startListening();
                    }
                        : null,
                    icon: const Icon(Icons.mic),
                    label: const Text('Tap to Listen'),
                  ),

                  const SizedBox(height: 8),

                  // Skip button
                  OutlinedButton(
                    onPressed: _markSeenAndGoHome,
                    child: const Text('Skip for Now'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
