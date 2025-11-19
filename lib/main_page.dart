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
import 'controllers/listen_controller.dart';
import 'controllers/tutorial_controller.dart';

class MainPage extends StatefulWidget {
  final bool tutorialMode;
  const MainPage({super.key, this.tutorialMode = false});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _tabIndex = 0;
  bool _isListening = false;
  TimerData? _selectedTimer;

  // Timers
  TimerData? _editingTimer;
  List<TimerData> _timers = [];
  TimerData? _voiceFilledTimer;

  // Voice / TTS / Routines
  final FlutterTts _tts = FlutterTts();
  final VoiceController _voiceController = VoiceController();
  late final PredefinedRoutines _routines;
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
      getActiveTimer: () => _selectedTimer,
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
      // ignore device-specific failures
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
    super.dispose();
  }

  // ---------- NAV / TABS ----------
  void _switchTab(int index) {
    if (!mounted) return;
    setState(() => _tabIndex = index);
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
      if (_selectedTimer != null && _selectedTimer!.id == timerId) {
        _selectedTimer = null;
      }
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
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint("TTS error: $e");
    }
  }

  // ---------- HELPERS ----------
  /// Compute the *full* original duration of a timer in seconds
  /// using work/break intervals and sets.
  int _fullDurationSeconds(TimerData t) {
    final int workSecPerSet = t.workInterval * 60;
    final int breakSecPerSet = t.breakInterval * 60;
    // Work for each set + breaks between sets (no break after last)
    return workSecPerSet * t.totalSets +
        breakSecPerSet * (t.totalSets - 1);
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

  // ---------------- MULTI-TIMER ENGINE ----------------

  void _startTimer(TimerData timer, {bool restart = false}) {
    // If restarting, reset remaining time + set counter
    if (restart) {
      timer.totalTime = _fullDurationSeconds(timer);
      timer.currentSet = 1;
    }

    if (timer.isRunning) return;

    timer.start(
          () => setState(() {}), // onTick
          () {
        // onFinish: behave like "stop" + speak "Time's up"
        _stopTimer(timer,
            announceStopped: false,
            resetToFull: true); // resets & closes fullscreen
        _speak("Time's up for ${timer.name}");
      },
    );

    setState(() {
      _selectedTimer = timer;
    });
    _saveTimers();
  }

  void _pauseTimer(TimerData timer) {
    timer.pause();
    _speak("${timer.name} paused");
    setState(() {});
    _saveTimers();
  }

  void _resumeTimer(TimerData timer) {
    timer.resume(
          () => setState(() {}),
          () {
        // If it finishes after resuming
        _stopTimer(timer,
            announceStopped: false,
            resetToFull: true);
        _speak("Time's up for ${timer.name}");
      },
    );
    setState(() {});
    _saveTimers();
  }

  void _stopTimer(
      TimerData timer, {
        bool announceStopped = true,
        bool resetToFull = true,
      }) {
    // Cancel ticker + clear running flag
    timer.stop();

    if (resetToFull) {
      timer.totalTime = _fullDurationSeconds(timer);
      timer.currentSet = 1;
    }

    if (announceStopped) {
      _speak("${timer.name} stopped");
    }

    setState(() {
      if (_selectedTimer == timer) {
        _selectedTimer = null; // close countdown screen
      }
    });

    _saveTimers();
  }

  // ---------- PAGES ----------
  List<Widget> get _pages => [
    HomeScreen(
      timers: _timers,
      onPlayTimer: _startTimer,
      onEditTimer: _editTimer,
      onDeleteTimer: _deleteTimer,
      onSwitchTab: _switchTab,
      onStartTimer: _startTimer,
      onPauseTimer: _pauseTimer,
      onResumeTimer: _resumeTimer,
      onStopTimer: _stopTimer,
      onOpenCountdown: (timer) {
        setState(() {
          _selectedTimer =
              _timers.firstWhere((t) => t.id == timer.id);
        });
      },
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
    });
  }

  Widget _buildBody() {
    return Stack(
      children: [
        IndexedStack(
          index: _tabIndex,
          children: _pages,
        ),

        // Single fullscreen countdown for the *selected* timer
        if (_selectedTimer != null)
          CountdownScreen(
            timerData: _selectedTimer!,
            onBack: () {
              setState(() => _selectedTimer = null);
            },
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
            selectedItemColor: _selectedTimer != null
                ? Colors.grey
                : const Color(0xFF007BFF),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            currentIndex: _tabIndex,
            onTap: (index) {
              setState(() {
                _selectedTimer = null;  // close fullscreen countdown
                _tabIndex = index;      // navigate normally
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
              color:
              _isListening ? Colors.redAccent : const Color(0xFF007BFF),
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
                    _isListening
                        ? "Listening... Tap to stop"
                        : "Tap to Speak",
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
