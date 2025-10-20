import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'welcome_page.dart';
import 'homepage.dart';
import 'create_timer_screen.dart';
import 'stopwatchmodeselecter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenWelcome = prefs.getBool('hasSeenWelcome') ?? false;

  runApp(TickTalkApp(hasSeenWelcome: hasSeenWelcome));
}

class TickTalkApp extends StatelessWidget {
  final bool hasSeenWelcome;
  const TickTalkApp({super.key, required this.hasSeenWelcome});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TickTalk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF007BFF),
        scaffoldBackgroundColor: const Color(0xFFF2F6FA),
      ),
      home: hasSeenWelcome ? const AppShell() : const WelcomePage(),
      // Routes are no longer needed here as navigation is handled inside the AppShell
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  final GlobalKey<HomeScreenState> _homeScreenKey = GlobalKey<HomeScreenState>();

  // UPDATED: All pages are now included in this list
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Instantiate all your pages here
    _pages = [
      HomeScreen(key: _homeScreenKey),
      const CreateTimerScreen(), // Added
      const RoutinesPage(),
      const ActivityPage(),
      const StopwatchModeSelector(), // Added
    ];
    _initSpeech();
  }

  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  final FlutterTts _tts = FlutterTts();

  void _initSpeech() async {
    try {
      await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'notListening') setState(() => _isListening = false);
        },
        onError: (error) => setState(() => _isListening = false),
      );
    } catch (e) {
      print("Error initializing speech: $e");
    }
  }

  void _startListening() async {
    if (_isListening) return;
    try {
      setState(() => _isListening = true);
      await _speak("Listening");
      await _speechToText.listen(onResult: _onSpeechResult);
    } catch (e) {
      setState(() => _isListening = false);
    }
  }

  void _stopListening() async {
    try {
      await _speechToText.stop();
      setState(() => _isListening = false);
    } catch (e) {
      print("Error stopping listening: $e");
    }
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.9);
      await _tts.speak(text);
    } catch (e) {
      print("TTS error: $e");
    }
  }

  void _onSpeechResult(result) {
    String recognizedText = result.recognizedWords.toLowerCase();
    if (!result.finalResult) return;

    final homeScreenState = _homeScreenKey.currentState;
    if (homeScreenState == null) return;

    if (recognizedText.contains("start") && recognizedText.contains("stopwatch")) {
      _stopListening();
      _speak("Starting stopwatch");
      homeScreenState.openNormalStopwatch(autoStart: true);
      return;
    }
    if (recognizedText.contains("hey tick talk") && recognizedText.contains("start mindfulness")) {
      homeScreenState.startMindfulnessMinute();
    }
    if (recognizedText.contains("hey tick talk") && recognizedText.contains("start laundry")) {
      homeScreenState.startSimpleLaundryCycle();
    }
    if (recognizedText.contains("hey tick talk") && recognizedText.contains("start 20 20 20")) {
      homeScreenState.start202020Rule();
    }
    if (recognizedText.contains("rerun tutorial")) {
      homeScreenState.rerunTutorial();
      _stopListening();
    }
  }

  // UPDATED: Navigation logic is now much simpler
  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            // IndexedStack efficiently switches between pages
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),

          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onNavBarTap,
            selectedItemColor: const Color(0xFF007BFF),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 8,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Create'),
              BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Routines'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Activity'),
              BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Stopwatch'),
            ],
          ),

          GestureDetector(
            onTap: _isListening ? _stopListening : _startListening,
            child: Semantics(
              label: _isListening
                  ? 'Voice control is active. Double tap to stop listening'
                  : 'Voice control button. Double tap to start listening',
              button: true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 24, top: 12),
                color: _isListening ? Colors.red : const Color(0xFF007BFF),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isListening ? 'LISTENING...' : 'TAP ANYWHERE TO SPEAK',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// These can be moved to their own files later if they become complex
class RoutinesPage extends StatelessWidget {
  const RoutinesPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Routines')),
      body: const Center(child: Text('Routines Page Content')),
    );
  }
}

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: const Center(child: Text('Activity Page Content')),
    );
  }
}

