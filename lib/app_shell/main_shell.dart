import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../UI/settings/settings.dart';
import '../UI/home/home_page.dart';
import '../UI/timer/create_timer_page.dart';
import '../UI/routines/routines_page.dart';
import '../UI/stopwatch/stopwatch_selector_page.dart';

import 'voice_mic_bar.dart';
import 'voice_router.dart';
import '../logic/tutorial/tutorial_controller.dart';

class MainShell extends StatefulWidget {
  final bool startTutorial; // if true, run tutorial once on launch

  const MainShell({
    super.key,
    this.startTutorial = false,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  bool _isListening = false;
  String _lastWords = "";

  Key createTimerKey = UniqueKey();
  final GlobalKey<RoutinesPageState> routinesKey = GlobalKey<RoutinesPageState>();

  final stt.SpeechToText _speech = stt.SpeechToText();
  late final VoiceRouter _voiceRouter;
  late final TutorialController _tutorial;

  @override
  void initState() {
    super.initState();

    _voiceRouter = VoiceRouter(
      onNavigateTab: (int tabIndex) {
        setState(() => _index = tabIndex);
        if (tabIndex == 2) {
          routinesKey.currentState?.reload();
        }
      },
    );

    _tutorial = TutorialController(
      context: context,
      goToTab: (int tabIndex) {
        debugPrint("📘 goToTab called with index=$tabIndex");
        setState(() => _index = tabIndex);
        if (tabIndex == 2) {
          routinesKey.currentState?.reload();
        }
      },
      pushPage: (Widget page) async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => page),
        );
      },
    );

    if (widget.startTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint("📘 MainShell: startTutorial=true → starting tutorial");
        _tutorial.start();
      });
    }
  }

  void _returnHome() {
    setState(() => _index = 0);
    createTimerKey = UniqueKey();
  }

  Future<void> _toggleMic() async {
    // ---------------------------
    // START LISTENING
    // ---------------------------
    if (!_isListening) {
      // If tutorial is running, pause it immediately when mic is tapped
      if (_tutorial.isActive && !_tutorial.isPaused) {
        debugPrint("📘 Mic tapped → pausing tutorial");
        _tutorial.pause();
      }

      final available = await _speech.initialize(
        onStatus: (status) {
          if (kDebugMode) print("🎙 Status: $status");
          if (status.contains('notListening') || status.contains('done')) {
            if (mounted) {
              setState(() => _isListening = false);
            }

            // If tutorial is active and still paused (no finalResult came), resume it
            if (_tutorial.isActive && _tutorial.isPaused) {
              debugPrint("📘 onStatus(done) → resuming tutorial");
              _tutorial.resume();
            }
          }
        },
        onError: (e) {
          if (kDebugMode) print("❌ Speech error: $e");
          if (mounted) {
            setState(() => _isListening = false);
          }

          if (_tutorial.isActive && _tutorial.isPaused) {
            debugPrint("📘 onError → resuming tutorial");
            _tutorial.resume();
          }
        },
      );

      if (!available) return;

      setState(() {
        _isListening = true;
        _lastWords = "";
      });

      await _speech.listen(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        onResult: (result) async {
          if (!mounted) return;

          setState(() => _lastWords = result.recognizedWords);

          if (!result.finalResult) return;

          final lower = _lastWords.toLowerCase().trim();

          // Stop listening UI
          if (mounted) {
            setState(() => _isListening = false);
          }
          try {
            await _speech.stop();
          } catch (_) {}

          // ---------------------------
          // WHILE TUTORIAL IS ACTIVE
          // ---------------------------
          if (_tutorial.isActive) {
            final isSkipCommand =
                lower.contains('skip') ||
                    lower.contains('exit') ||
                    lower.contains('stop tutorial') ||
                    lower.contains('cancel tutorial') ||
                    lower.contains('end tutorial');

            if (isSkipCommand) {
              debugPrint("📘 Voice: tutorial skip command detected");
              _tutorial.stop();
              return;
            }

            // No skip or unrecognized → resume tutorial
            debugPrint("📘 Voice: non-skip during tutorial → resuming tutorial");
            _tutorial.resume();
            return;
          }

          // ---------------------------
          // NORMAL BEHAVIOR (NO TUTORIAL ACTIVE)
          // ---------------------------
          if (lower.isEmpty) return;

          // ✅ GLOBAL VOICE COMMAND TO RE-RUN TUTORIAL
          final wantsTutorial =
              lower.contains('start tutorial') ||
                  lower.contains('restart tutorial') ||
                  lower.contains('run tutorial') ||
                  lower.contains('tutorial again') ||
                  lower.contains('welcome page') || // if user says "go to welcome page"
                  (lower == 'tutorial');

          if (wantsTutorial) {
            debugPrint("📘 Voice: start/restart tutorial command detected");
            // Go to Home (optional) then start tutorial
            setState(() => _index = 0);
            _tutorial.start();
            return;
          }

          // Otherwise: normal voice routing
          _voiceRouter.handle(_lastWords);
        },
      );

      // ---------------------------
      // STOP LISTENING (mic already ON)
      // ---------------------------
    } else {
      if (mounted) {
        setState(() => _isListening = false);
      }
      try {
        await _speech.stop();
      } catch (_) {}

      // If user manually taps to cancel listening while tutorial was paused, resume it
      if (_tutorial.isActive && _tutorial.isPaused) {
        debugPrint("📘 Mic tapped again → resuming tutorial");
        _tutorial.resume();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomePage(), // index 0
      KeyedSubtree(
        key: createTimerKey,
        child: CreateTimerPage(onTimerStarted: _returnHome), // index 1
      ),
      RoutinesPage(key: routinesKey), // index 2
      const StopwatchSelectorPage(),   // index 3
      const SettingsPage(),            // index 4
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(index: _index, children: screens),

            if (_isListening && _lastWords.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 160,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _lastWords,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationBar(
            backgroundColor: const Color(0xFF1C1C1C),
            selectedIndex: _index,
            indicatorColor: const Color(0xFF7A3FFF),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (i) {
              setState(() => _index = i);
              if (i == 2) routinesKey.currentState?.reload();
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: "Home",
              ),
              NavigationDestination(
                icon: Icon(Icons.timer_outlined),
                selectedIcon: Icon(Icons.timer),
                label: "Timer",
              ),
              NavigationDestination(
                icon: Icon(Icons.list_alt_outlined),
                selectedIcon: Icon(Icons.list_alt),
                label: "Routines",
              ),
              NavigationDestination(
                icon: Icon(Icons.timer),
                selectedIcon: Icon(Icons.timer_rounded),
                label: "Stopwatch",
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: "Settings",
              ),
            ],
          ),
          VoiceMicBar(
            isListening: _isListening,
            onTap: _toggleMic,
          ),
        ],
      ),
    );
  }
}
