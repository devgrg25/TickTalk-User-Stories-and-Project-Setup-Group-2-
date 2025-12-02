import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../UI/settings/settings.dart';
import '../UI/home/home_page.dart';
import '../UI/timer/create_timer_page.dart';
import '../UI/routines/routines_page.dart';

// Stopwatch pages
import '../UI/stopwatch/stopwatch_selector_page.dart';
import '../UI/stopwatch/normal_stopwatch_page.dart';
import '../UI/stopwatch/stopwatch_summary_page.dart';
import '../UI/stopwatch/player_count_selector_page.dart';
import '../UI/stopwatch/player_mode_stopwatch_page.dart';
import '../UI/stopwatch/multi_player_summary_page.dart';    // ⭐️ ADD THIS IMPORT

// Logic
import '../logic/stopwatch/normal_stopwatch_shared_controller.dart';
import '../logic/tutorial/tutorial_controller.dart';
import '../logic/stopwatch/player_mode_manager.dart';       // ⭐️ PLAYER MANAGER IMPORT

import 'voice_mic_bar.dart';
import 'voice_router.dart';

import '../UI/settings/font_scale.dart';
import '../logic/voice/voice_tts_service.dart';


class MainShell extends StatefulWidget {
  final bool startTutorial;

  const MainShell({super.key, this.startTutorial = false});

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

  // Normal stopwatch shared controller
  final NormalStopwatchSharedController sharedSW = NormalStopwatchSharedController();

  // Summary variables for SINGLE STOPWATCH
  Duration? _summaryTotal;
  List<Duration>? _summaryLaps;

  // Player Mode
  int? _playerCount = 1;

  // ⭐️ PLAYER MODE SUMMARY STORAGE
  List<PlayerStopwatchSummary>? _playerSummaries;


  @override
  void initState() {
    super.initState();

    // TICKER FOR NORMAL STOPWATCH
    sharedSW.onTick = () {
      if (mounted) setState(() {});
    };

    // -----------------------------------------------------
    // ⭐️ LISTEN TO PLAYER-MODE SUMMARY CALLBACK
    // -----------------------------------------------------
    PlayerModeManager.instance.onAllPlayersStopped = (summaries) {
      setState(() {
        _playerSummaries = summaries;
        _index = 9; // navigate to MultiPlayerSummaryPage
      });
    };

    // Voice Router
    _voiceRouter = VoiceRouter(
      onNavigateTab: (tab) {
        setState(() => _index = tab);
        if (tab == 2) routinesKey.currentState?.reload();
      },
      stopwatchController: sharedSW,

      // NORMAL STOPWATCH SUMMARY
      onShowSummary: (total, laps) {
        setState(() {
          _summaryTotal = total;
          _summaryLaps = laps;
          _voiceRouter.setSummary(total, laps);

          _index = 6; // Show normal summary page
        });
      },
    );

    // Tutorial Controller
    _tutorial = TutorialController(
      context: context,
      goToTab: (tab) {
        setState(() => _index = tab);
        if (tab == 2) routinesKey.currentState?.reload();
      },
      pushPage: (page) async {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
      },
    );

    // Start tutorial if needed
    if (widget.startTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tutorial.start();
      });
    }
  }

  void _returnHome() {
    setState(() => _index = 0);
    createTimerKey = UniqueKey();
  }

  // ------------------------------------------------------------
  // 🔥 ADVANCED MIC LOGIC (unchanged)
  // ------------------------------------------------------------
  Future<void> _toggleMic() async {
    if (!_isListening) {
      if (_tutorial.isActive && !_tutorial.isPaused) _tutorial.pause();

      final available = await _speech.initialize(
        onStatus: (status) {
          if (status.contains('notListening') || status.contains('done')) {
            if (mounted) setState(() => _isListening = false);
            if (_tutorial.isActive && _tutorial.isPaused) _tutorial.resume();
          }
        },
        onError: (e) {
          if (mounted) setState(() => _isListening = false);
          if (_tutorial.isActive && _tutorial.isPaused) _tutorial.resume();
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

          // Stop mic state
          setState(() => _isListening = false);
          try {
            await _speech.stop();
          } catch (_) {}

          // Tutorial Cancel / Resume
          if (_tutorial.isActive) {
            bool skip = lower.contains('skip') ||
                lower.contains('exit tutorial') ||
                lower.contains('cancel tutorial') ||
                lower.contains('stop tutorial');

            if (skip) {
              _tutorial.stop();
              return;
            }

            _tutorial.resume();
            return;
          }

          // Restart tutorial
          bool wantsTutorial =
              lower.contains('start tutorial') ||
                  lower.contains('restart tutorial') ||
                  lower.contains('run tutorial') ||
                  lower == "tutorial";

          if (wantsTutorial) {
            setState(() => _index = 0);
            _tutorial.start();
            return;
          }

          // Font controls
          if (lower.contains('increase font') ||
              lower.contains('bigger text') ||
              lower.contains('larger text')) {
            await FontScale.instance.increaseBy10();
            await VoiceTtsService.instance.speak('Increasing font size.');
            return;
          }

          if (lower.contains('decrease font') ||
              lower.contains('smaller text') ||
              lower.contains('reduce font')) {
            await FontScale.instance.decreaseBy10();
            await VoiceTtsService.instance.speak('Decreasing font size.');
            return;
          }

          // NORMAL VOICE ROUTING
          if (lower.isNotEmpty) _voiceRouter.handle(lower);
        },
      );
    } else {
      // Stop listening
      setState(() => _isListening = false);
      try {
        await _speech.stop();
      } catch (_) {}
      if (_tutorial.isActive && _tutorial.isPaused) _tutorial.resume();
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
        controller: sharedSW,
        onStopFromPreview: (total, laps) {
          _summaryTotal = total;
          _summaryLaps = laps;
          setState(() => _index = 6);
        },
      ),                                                // 3
      const SettingsPage(),                             // 4
      NormalStopwatchPage(
        controller: sharedSW,
        onStop: (total, laps) {
          _summaryTotal = total;
          _summaryLaps = laps;
          setState(() => _index = 6);
        },
      ),                                                // 5
      StopwatchSummaryPage(
        total: _summaryTotal,
        laps: _summaryLaps,
        onClose: () {
          _voiceRouter.clearSummary();
          setState(() => _index = 3);
        },
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

      // ⭐️ MULTI PLAYER SUMMARY PAGE ADDED AS INDEX 9
      MultiPlayerSummaryPage(
        summaries: _playerSummaries ?? [],
        onClose: () => setState(() => _index = 3),
      ),                                                // 9
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
