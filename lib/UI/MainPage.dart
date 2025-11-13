import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

// Stopwatch UI pages
import 'stopwatch/stopwatch_normal_mode.dart';
import 'stopwatch/stopwatch_player_mode.dart';
import 'stopwatch/stopwatchmodeselecter.dart';

// Core app files
import 'homepage.dart';
import 'timers/create_timer_screen.dart';
import '../logic/models/timer_model.dart';
import 'timers/countdown_screen.dart';
import '../logic/models/routine_timer_model.dart';
import '../logic/routines/routines.dart';
import 'routines/routines_page.dart';

// Voice system
import '../../logic/voice/base/global_voice_router.dart';
import '../../logic/voice/stopwatch_voice_controller.dart';
import '../../logic/voice/timer_voice_controller.dart';
import '../../logic/voice/routines_voice_controller.dart';
import '../../logic/voice/tutorial_voice_controller.dart';

// --- NEW IMPORTS ---
import 'timers/normal_timer.dart';
import 'timers/timer_mode_selector.dart';
import '../logic/models/timer_normal_model.dart';

class MainPage extends StatefulWidget {
  final bool tutorialMode;
  const MainPage({super.key, this.tutorialMode = false});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _tabIndex = 0;
  bool _showingCountdown = false;
  bool _isListening = false;

  TimerData? _editingTimer;
  TimerData? _activeTimer;
  Timer? _ticker;

  final FlutterTts _tts = FlutterTts();

  String? _activeStopwatchMode;

  final _timerVoice = TimerVoiceController();
  final _stopwatchVoice = StopwatchVoiceController();
  final _routinesVoice = RoutinesVoiceController();
  final _tutorialVoice = TutorialVoiceController();
  late final GlobalVoiceRouter _voiceRouter;

  final CountdownController _countdownController = CountdownController();
  final String _timersKey = 'saved_timers_list';
  List<TimerData> _timers = [];

  @override
  void initState() {
    super.initState();

    // Initialize global voice router
    _voiceRouter = GlobalVoiceRouter(
      stopwatchController: _stopwatchVoice,
      timerController: _timerVoice,
      routinesController: _routinesVoice,
      tutorialController: _tutorialVoice,
    );
    // ✅ When user says "create timer" or "go to timer"
    _timerVoice.onOpenTimer = () async {
      setState(() {
        _activeStopwatchMode = null; // Close stopwatch subpage if open
        _tabIndex = 1;               // Switch to timer mode selector
      });

      // Wait for UI to rebuild, then lock router to timer
      await Future.delayed(const Duration(milliseconds: 400));
      _voiceRouter.activateDomain('timer');
    };


    // --- VOICE CALLBACKS ---

    // ✅ 1. Add this block for Timer voice navigation
    _timerVoice.onNavigateToTab = (index) {
      setState(() => _tabIndex = index);
    };
    // ✅ NEW: when user says "create stopwatch", go to tab index 3
    _stopwatchVoice.onOpenStopwatch = () async {
      setState(() => _tabIndex = 3);

      // Wait a short moment for UI to finish switching,
      // then lock the router to stopwatch domain
      await Future.delayed(const Duration(milliseconds: 400));
      _voiceRouter.activateDomain('stopwatch');
    };


    // ✅ 2. Keep stopwatch voice callbacks
    _stopwatchVoice.onSelectMode = (mode) {
      setState(() => _activeStopwatchMode = mode);
    };

    _stopwatchVoice.onBack = () {
      setState(() => _activeStopwatchMode = null);
    };

    // ✅ 3. Keep timer loading and TTS setup
    _loadTimers();
    _initTts();
  }


  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.9);
  }

  @override
  void dispose() {
    _tts.stop();
    _ticker?.cancel();
    super.dispose();
  }

  // ---------- TIMER STORAGE ----------
  Future<void> _loadTimers() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_timersKey);
    if (data == null) return;
    final List decoded = jsonDecode(data);
    setState(() {
      _timers = decoded.map((e) => TimerData.fromJson(e)).toList();
    });
  }

  Future<void> _saveTimers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _timersKey,
      jsonEncode(_timers.map((t) => t.toJson()).toList()),
    );
  }

  // ---------- TIMER CONTROL ----------
  void _playTimer(TimerData timerToPlay) {
    if (timerToPlay.totalTime <= 0) return;
    _startTimer(timerToPlay);
  }

  void _startTimer(TimerData timerData) {
    _ticker?.cancel();
    setState(() {
      _activeTimer = timerData.copyWith();
      _showingCountdown = true;
    });

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _activeTimer == null) {
        timer.cancel();
        return;
      }

      final current = _activeTimer!;
      final remaining = current.totalTime - 1;

      if (remaining <= 0) {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          setState(() {
            _activeTimer = null;
            _showingCountdown = false;
            _tabIndex = 0;
          });
        });
      } else {
        setState(() {
          _activeTimer = current.copyWith(totalTime: remaining);
        });
      }
    });
  }

  void _stopTimer() {
    _ticker?.cancel();
    _ticker = null;
    setState(() {
      _activeTimer = null;
      _showingCountdown = false;
    });
  }

  // ---------- STOPWATCH UI ----------
  Widget _buildStopwatchArea() {
    if (_activeStopwatchMode == 'normal') {
      return StopwatchNormalMode(onBack: () => setState(() => _activeStopwatchMode = null));
    } else if (_activeStopwatchMode == 'player') {
      return StopwatchPlayerMode(onBack: () => setState(() => _activeStopwatchMode = null));
    } else {
      return StopwatchModeSelector(onSelectMode: (mode) => setState(() => _activeStopwatchMode = mode));
    }
  }

  // ---------- MAIN PAGES ----------
  List<Widget> get _pages => [
    // 0 - Home
    HomeScreen(
      timers: _timers,
      onPlayTimer: _playTimer,
      onEditTimer: (t) => setState(() {
        _editingTimer = t;
        _tabIndex = 1;
      }),
      onDeleteTimer: (id) => _deleteTimer(id),
      onSwitchTab: (i) => setState(() => _tabIndex = i),
      onStartTimer: _startTimer,
      activeTimer: _activeTimer,
    ),

    // 1 - Create (selector)
    TimerModeSelector(
      onSelectMode: (mode) {
        if (mode == 'normal') {
          setState(() => _tabIndex = 4); // Normal Timer
        } else if (mode == 'interval') {
          setState(() => _tabIndex = 5); // Interval Timer
        }
      },
    ),

    // 2 - Routines
    RoutinesPage(
      routines: PredefinedRoutines(
        stopListening: () => _voiceRouter.stopListening(),
        speak: (msg) => _tts.speak(msg),
        playTimer: (t) {},
      ),
    ),

    // 3 - Stopwatch (visible tab)
    _buildStopwatchArea(),

    // 4 - Hidden: Normal Timer
    const NormalTimerScreen(),

    // 5 - Hidden: Interval Timer
    CreateTimerScreen(),
  ];

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _tabIndex, children: _pages),

          if (_activeTimer != null)
            Offstage(
              offstage: !_showingCountdown,
              child: CountdownScreen(
                timerData: _activeTimer!,
                onBack: () => setState(() => _showingCountdown = false),
                controller: _countdownController,
              ),
            ),
        ],
      ),

      // ---------- BOTTOM NAV ----------
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_activeTimer != null) _buildActiveTimerBanner(),
          BottomNavigationBar(
            currentIndex: _tabIndex > 3 ? 3 : _tabIndex, // restrict index for visible tabs
            onTap: (index) {
              if (_showingCountdown) _showingCountdown = false;
              setState(() => _tabIndex = index);
            },
            selectedItemColor: const Color(0xFF007BFF),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Create'),
              BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Routines'),
              BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Stopwatch'),
            ],
          ),

          // ---------- MIC BUTTON ----------
          GestureDetector(
            onTap: () async {
              if (_isListening) {
                await _voiceRouter.stopListening();
                setState(() => _isListening = false);
              } else {
                setState(() => _isListening = true);
                await _voiceRouter.listenAndRoute();
                setState(() => _isListening = false);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: _isListening ? Colors.redAccent : const Color(0xFF007BFF),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isListening ? Icons.mic : Icons.mic_off, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    _isListening ? "Listening... Tap to stop" : "Tap to Speak",
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- ACTIVE TIMER BANNER ----------
  Widget _buildActiveTimerBanner() {
    final active = _activeTimer;
    if (active == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => setState(() => _showingCountdown = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.blue.withOpacity(0.12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(active.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Text("Timer Running"),
              ],
            ),
            Text(
              _formatMMSS(active.totalTime),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: _stopTimer),
          ],
        ),
      ),
    );
  }

  String _formatMMSS(int secondsTotal) {
    final m = secondsTotal ~/ 60;
    final s = secondsTotal % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _addOrUpdateTimer(TimerData timer) async {
    final index = _timers.indexWhere((t) => t.id == timer.id);
    setState(() {
      if (index != -1) {
        _timers[index] = timer;
      } else {
        _timers.add(timer);
      }
    });
    await _saveTimers();
  }

  void _deleteTimer(String id) {
    setState(() => _timers.removeWhere((t) => t.id == id));
    _saveTimers();
  }
}
