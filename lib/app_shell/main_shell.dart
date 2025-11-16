import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../UI/home/home_page.dart';
import '../UI/timer/create_timer_page.dart';
import '../UI/routines/routines_page.dart';
import 'voice_mic_bar.dart';

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

  late stt.SpeechToText _speech;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _returnHome() {
    setState(() => _index = 0);
    createTimerKey = UniqueKey();
  }

  Future<void> _toggleMic() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          debugPrint("🔊 Speech status: $status");
          if (status == "notListening") {
            setState(() => _isListening = false);
          }
        },
        onError: (e) => debugPrint("❌ Speech error: $e"),
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() => _lastWords = result.recognizedWords);
            debugPrint("🗣 Heard: $_lastWords");
          },
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
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
      const RoutinesPage(),
      const Center(
        child: Text("Settings",
            style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(index: _index, children: screens),

            /// 🔹 Live caption text when mic is listening
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
                          color: Colors.white, fontSize: 16),
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
            onDestinationSelected: (i) => setState(() => _index = i),
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

          /// 🟣 Glowing talk sphere mic
          VoiceMicBar(
            isListening: _isListening,
            onTap: _toggleMic,
          ),

        ],
      ),
    );
  }
}
