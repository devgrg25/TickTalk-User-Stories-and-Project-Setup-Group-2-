// main_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'dart:convert';
import 'homepage.dart';
import 'create_timer_screen.dart';
import 'timer_models/timer_model.dart';
import 'countdown_screen.dart';
import 'countdown_screenV.dart';
import 'stopwatch/stopwatchmodeselecter.dart';
import 'controllers/mic_controller.dart';
import 'timer_models/routine_timer_model.dart';
import 'routines/routines.dart';
import 'routines/routines_page.dart';
import 'controllers/voice_logic.dart';
import 'controllers/tutorial_controller.dart';

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

  // Timers
  TimerData? _editingTimer;
  TimerData? _activeTimer;
  Timer? _ticker; // single global ticker

  final FlutterTts _tts = FlutterTts();
  final VoiceController _voiceController = VoiceController();
  late final PredefinedRoutines _routines;

  List<TimerData> _timers = [];
  TimerData? _voiceFilledTimer;

  late ListenController _listen;
  late TutorialController tutorial;

  static const String _timersKey = 'saved_timers_list';

  final GlobalKey<RoutinesPageState> _routinesKey =
  GlobalKey<RoutinesPageState>();

  // ---------- INIT / DISPOSE ----------
  @override
  void initState() {
    super.initState();

    _initTts();

    tutorial = TutorialController(
      context: context,
      goToTab: (index) => setState(() => _tabIndex = index),
      pushPage: (page) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page),
      ),
    );

    _listen = ListenController(
      voice: _voiceController,
      getIsListening: () => _isListening,
      setIsListening: (v) => _isListening = v,
      getActiveTimer: () => _activeTimer,
      getTabIndex: () => _tabIndex,
      pauseTimer: _pauseTimer,
      resumeTimer: _resumeTimer,
      stopTimer: _stopTimer,
      setEditingTimer: (v) => _editingTimer = v,
      setVoiceFilledTimer: (v) => _voiceFilledTimer = v,
      setTabIndex: (v) => _tabIndex = v,
      getTimers: () => _timers,
      generateUniqueName: _generateUniqueTimerName,
      stopPageTts: () => _tts.stop(),
      routinesKey: _routinesKey,
      mounted: () => mounted,
      setState: setState,
      tutorialController: tutorial,
    );

    _routines = PredefinedRoutines(
      stopListening: _listen.stopListening,
      speak: _speak,
      playTimer: _playTimerV,
    );

    _loadTimers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.tutorialMode) {
        tutorial.start();
      }
    });
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.9);
    } catch (_) {
      // swallow device differences
    }
  }

  String _generateUniqueTimerName(List<TimerData> timers) {
    int counter = 1;
    while (true) {
      final name = "Timer $counter";
      final exists = timers.any((t) => t.name == name);
      if (!exists) return name;
      counter++;
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _voiceController.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  // ---------- NAV / TABS ----------
  void _switchTab(int index) {
    if (!mounted) return;
    setState(() => _tabIndex = index);
  }

  void _exitCountdown() {
    if (!mounted) return;
    setState(() {
      _showingCountdown = false;
      _tabIndex = 0; // back to Home
    });
  }

  // ---------- PERSISTENCE ----------
  Future<void> _loadTimers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? timersString = prefs.getString(_timersKey);
    if (timersString == null) return;

    final List<dynamic> timerJson = jsonDecode(timersString);
    if (!mounted) return;
    setState(() {
      _timers = timerJson.map((json) => TimerData.fromJson(json)).toList();
    });
  }

  Future<void> _saveTimers() async {
    final prefs = await SharedPreferences.getInstance();
    final String timersString =
    jsonEncode(_timers.map((t) => t.toJson()).toList());
    await prefs.setString(_timersKey, timersString);
  }

  // ---------- CRUD ----------
  void _deleteTimer(String timerId) {
    setState(() {
      _timers.removeWhere((t) => t.id == timerId);
    });
    _saveTimers();
  }

  void _editTimer(TimerData timerToEdit) {
    setState(() {
      _editingTimer = timerToEdit;
      _voiceFilledTimer =
      null; // prevent voice timer from overwriting edit data
      _tabIndex = 1;
    });
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

  // ---------- TTS ----------
  Future<void> _speak(String text) async {
    try {
      await _tts.speak(text);
    } catch (e) {
      debugPrint("TTS error: $e");
    }
  }

  // ---------- TIMER ENGINE ----------
  void _playTimerV(TimerDataV timerToPlay) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CountdownScreenV(timerData: timerToPlay),
      ),
    );
  }

  void _playTimer(TimerData timerToPlay) {
    _startTimer(timerToPlay);
  }

  void _startTimer(TimerData timerData) {
    // Ignore zero/negative durations
    if (timerData.totalTime <= 0) {
      _speak("Timer duration is zero.");
      return;
    }

    // If this exact timer is already active, and ticking, do nothing
    if (_activeTimer?.id == timerData.id && (_ticker?.isActive ?? false)) {
      return;
    }

    // Cancel any existing ticker
    _ticker?.cancel();

    if (!mounted) return;
    setState(() {
      _activeTimer = timerData.copyWith();
      _showingCountdown = true; // show fullscreen
    });

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_activeTimer == null) {
        timer.cancel();
        return;
      }

      final current = _activeTimer!;
      final remaining = current.totalTime;

      if (remaining <= 0) {
        timer.cancel();
        if (!mounted) return;

        _speak("Time's up.");

        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          setState(() {
            _activeTimer = null;
            _showingCountdown = false;
            _tabIndex = 0;
          });
        });
        return;
      }

      setState(() {
        _activeTimer = current.copyWith(totalTime: remaining - 1);
      });
    });
  }

  void _pauseTimer() {
    if (_ticker == null) return;
    _ticker!.cancel();
    _ticker = null;
    _speak("Timer paused.");
    setState(() {}); // to refresh isPaused in HomeScreen
  }

  void _resumeTimer() {
    if (_activeTimer == null || _ticker != null) return;

    _speak("Resuming timer.");

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_activeTimer == null) {
        timer.cancel();
        return;
      }

      final current = _activeTimer!;
      final remaining = current.totalTime;

      if (remaining <= 0) {
        timer.cancel();
        _speak("Time's up.");
        setState(() {
          _activeTimer = null;
          _showingCountdown = false;
          _tabIndex = 0;
        });
        return;
      }

      setState(() {
        _activeTimer = current.copyWith(totalTime: remaining - 1);
      });
    });

    setState(() {}); // refresh isPaused
  }

  void _stopTimer() {
    _ticker?.cancel();
    _ticker = null;

    if (!mounted) return;
    setState(() {
      _activeTimer = null;
      _showingCountdown = false;
    });

    _speak("Timer stopped.");
  }

  // ---------- PAGES ----------
  List<Widget> get _pages => [
    HomeScreen(
      timers: _timers,
      onPlayTimer: _playTimer,
      onEditTimer: _editTimer,
      onDeleteTimer: _deleteTimer,
      onSwitchTab: _switchTab,
      onStartTimer: _startTimer,
      activeTimer: _activeTimer,
      onShowCountdown: () {
        setState(() => _showingCountdown = true);
      },
      isPaused: _activeTimer != null && _ticker == null,
      onPause: _pauseTimer,
      onResume: _resumeTimer,
    ),
    CreateTimerScreen(
      key: ValueKey(_voiceFilledTimer?.id ?? 'create_static'),
      existingTimer: _editingTimer ?? _voiceFilledTimer,
      onSaveTimer: _handleSaveTimer,
      startVoiceConfirmation:
      (_voiceFilledTimer != null && _editingTimer == null),
    ),
    RoutinesPage(
      key: _routinesKey,
      routines: _routines,
    ),
    const Placeholder(),
    const StopwatchModeSelector(),
  ];

  void _handleSaveTimer(TimerData timer) {
    _addOrUpdateTimer(timer);
    _startTimer(timer);

    if (!mounted) return;
    setState(() {
      _editingTimer = null;
      _voiceFilledTimer = null;
      _showingCountdown = true;
    });
  }

  Widget _buildBody() {
    return Stack(
      children: [
        IndexedStack(
          index: _tabIndex,
          children: _pages,
        ),

        if (_activeTimer != null)
          Offstage(
            offstage: !_showingCountdown,
            child: CountdownScreen(
              timerData: _activeTimer!,
              onBack: _exitCountdown,
            ),
          ),
      ],
    );
  }

  // ---------- BUILD ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BottomNavigationBar(
            selectedItemColor: _showingCountdown
                ? Colors.grey
                : const Color(0xFF007BFF),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            currentIndex: _tabIndex,
            onTap: (index) {
              setState(() {
                if (_showingCountdown) {
                  _showingCountdown = false;
                }
                _tabIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.add_circle_outline), label: 'Create'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.list_alt), label: 'Routines'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_outlined), label: 'Activity'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.timer), label: 'Stopwatch'),
            ],
          ),
          GestureDetector(
            onTap: () async {
              if (_isListening) {
                await _listen.stopListening();

                if (tutorial.isActive) tutorial.resume();
                  } else {
                if (tutorial.isActive) tutorial.pause();
                await _listen.startListening();
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
                  Icon(
                    _isListening ? Icons.mic : Icons.mic_off,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isListening ? "Listening... Tap to stop" : "Tap to Speak",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
