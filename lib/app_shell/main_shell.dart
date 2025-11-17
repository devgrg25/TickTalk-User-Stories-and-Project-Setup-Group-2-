import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../UI/home/home_page.dart';
import '../UI/timer/create_timer_page.dart';
import '../UI/routines/routines_page.dart';
import 'voice_mic_bar.dart';
import 'voice_router.dart';
import '../logic/voice/voice_tts_service.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  bool _isListening = false;
  String _lastWords = "";

  Key createTimerKey = UniqueKey();
  final GlobalKey<RoutinesPageState> routinesKey =
  GlobalKey<RoutinesPageState>();

  final stt.SpeechToText _speech = stt.SpeechToText();
  late final VoiceRouter _voiceRouter;

  @override
  void initState() {
    super.initState();

    // Initialize the voice router
    _voiceRouter = VoiceRouter(
      onNavigateTab: (int tabIndex) {
        setState(() => _index = tabIndex);

        // If we navigate to routines, refresh them
        if (tabIndex == 2) {
          routinesKey.currentState?.reload();
        }
      },

      // 🔮 AI fallback for Hybrid C2:
      // Right now this is just a placeholder.
      // Later you can call your backend / OpenAI here.
      aiFallback: (String rawText) async {
        debugPrint("AI fallback would handle: $rawText");
        await VoiceTtsService.instance.speak(
          "I'm still learning to understand more complex phrases.",
        );
      },
    );
  }

  void _returnHome() {
    setState(() => _index = 0);
    createTimerKey = UniqueKey();
  }

  Future<void> _toggleMic() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (kDebugMode) {
            print("🎙 Status: $status");
          }
          if (status.contains('notListening') || status.contains('done')) {
            setState(() => _isListening = false);
          }
        },
        onError: (e) {
          if (kDebugMode) {
            print("❌ Speech error: $e");
          }
          setState(() => _isListening = false);
        },
      );

      if (available) {
        setState(() {
          _isListening = true;
          _lastWords = "";
        });

        await _speech.listen(
          onResult: (result) {
            setState(() => _lastWords = result.recognizedWords);

            // When STT thinks the phrase is finished, send it to the router.
            if (result.finalResult) {
              _voiceRouter.handle(_lastWords);
            }
          },
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
        );
      }
    } else {
      setState(() => _isListening = false);
      await _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomePage(),
      KeyedSubtree(
        key: createTimerKey,
        child: CreateTimerPage(onTimerStarted: _returnHome),
      ),
      RoutinesPage(key: routinesKey),
      const Center(
        child: Text(
          "Settings",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(index: _index, children: screens),

            // Bubble showing live transcription
            if (_isListening && _lastWords.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 160,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
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

              if (i == 2) {
                routinesKey.currentState?.reload();
              }
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
