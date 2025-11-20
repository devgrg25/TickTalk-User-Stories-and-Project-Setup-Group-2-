import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../UI/home/home_page.dart';
import '../UI/timer/create_timer_page.dart';
import '../UI/routines/routines_page.dart';
import '../UI/stopwatch/stopwatch_selector_page.dart';
import '../UI/stopwatch/normal_stopwatch_page.dart';
import '../UI/stopwatch/stopwatch_summary_page.dart';
import '../UI/stopwatch/player_count_selector_page.dart';
import '../UI/stopwatch/player_mode_stopwatch_page.dart';

import '../logic/stopwatch/normal_stopwatch_shared_controller.dart';

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

  /// Shared normal stopwatch
  final NormalStopwatchSharedController sharedNormalSW =
  NormalStopwatchSharedController();

  Key createTimerKey = UniqueKey();
  final GlobalKey<RoutinesPageState> routinesKey = GlobalKey<RoutinesPageState>();

  Duration? _summaryTotal;
  List<Duration>? _summaryLaps;

  int? _playerCount = 1;

  final stt.SpeechToText _speech = stt.SpeechToText();
  late final VoiceRouter _voiceRouter;

  @override
  void initState() {
    super.initState();

    sharedNormalSW.onTick = () {
      if (mounted) setState(() {});
    };

    _voiceRouter = VoiceRouter(
      onNavigateTab: (int tabIndex) {
        setState(() => _index = tabIndex);
        if (tabIndex == 2) routinesKey.currentState?.reload();
      },
      stopwatchController: sharedNormalSW, // 🔥 REQUIRED PARAMETER
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
          if (kDebugMode) print("🎙 Status: $status");
          if (status.contains('notListening') || status.contains('done')) {
            setState(() => _isListening = false);
          }
        },
        onError: (e) {
          if (kDebugMode) print("❌ Speech error: $e");
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
            if (result.finalResult && _lastWords.isNotEmpty) {
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
      const HomePage(),                                 // 0
      KeyedSubtree(
        key: createTimerKey,
        child: CreateTimerPage(onTimerStarted: _returnHome),
      ),                                                // 1
      RoutinesPage(key: routinesKey),                   // 2

      StopwatchSelectorPage(
        onNavigate: (i) => setState(() => _index = i),
        controller: sharedNormalSW,

        // 🔥 Add this block
        onStopFromPreview: (total, laps) {
          _summaryTotal = total;
          _summaryLaps = laps;
          setState(() => _index = 6); // go to summary page
        },
      ),                                                // 3

      const Center(
        child: Text("Settings",
            style: TextStyle(color: Colors.white, fontSize: 18)),
      ),                                                // 4

      NormalStopwatchPage(
        controller: sharedNormalSW,
        onStop: (total, laps) {
          _summaryTotal = total;
          _summaryLaps = laps;
          setState(() => _index = 6);
        },
      ),                                                // 5

      StopwatchSummaryPage(
        total: _summaryTotal,
        laps: _summaryLaps,
        onClose: () => setState(() => _index = 3),
      ),                                                // 6

      PlayerCountSelectorPage(
        onSelectPlayers: (count) {
          _playerCount = count;
          setState(() => _index = 8);
        },
      ),                                                // 7

      PlayerModeStopwatchPage(
        playerCount: _playerCount ?? 1,
        onExit: () => setState(() => _index = 3),
      ),                                                // 8
    ];

    screens[6] = StopwatchSummaryPage(
      total: _summaryTotal,
      laps: _summaryLaps,
      onClose: () => setState(() => _index = 3),
    );

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
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _lastWords,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
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
            selectedIndex: _index.clamp(0, 4),
            indicatorColor: const Color(0xFF7A3FFF),
            onDestinationSelected: (i) {
              setState(() => _index = i);
              if (i == 2) routinesKey.currentState?.reload();
            },
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: "Home"),
              NavigationDestination(
                  icon: Icon(Icons.timer_outlined),
                  selectedIcon: Icon(Icons.timer),
                  label: "Timer"),
              NavigationDestination(
                  icon: Icon(Icons.list_alt_outlined),
                  selectedIcon: Icon(Icons.list_alt),
                  label: "Routines"),
              NavigationDestination(
                  icon: Icon(Icons.timer),
                  selectedIcon: Icon(Icons.timer_rounded),
                  label: "Stopwatch"),
              NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: "Settings"),
            ],
          ),

          VoiceMicBar(isListening: _isListening, onTap: _toggleMic),
        ],
      ),
    );
  }
}
