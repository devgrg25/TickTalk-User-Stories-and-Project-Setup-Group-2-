import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'dart:async';

import 'homepage.dart';                 // HomeScreen
import 'create_timer_screen.dart';
import 'timer_model.dart';
import 'countdown_screen.dart';
import 'countdown_screenV.dart';
import 'stopwatchmodeselecter.dart';
import 'stopwatch_normal_mode.dart';
import 'voice_controller.dart';
import 'routine_timer_model.dart';
import 'routines.dart';
import 'routines_page.dart';

class MainPage extends StatefulWidget {
  final bool tutorialMode; // <— NEW
  const MainPage({super.key, this.tutorialMode = false});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _tabIndex = 0;
  bool _showingCountdown = false;

  /// Global mic state
  bool _isListening = false;

  /// Tutorial lock — while true, mic only accepts “skip” and we won’t run creation/navigation voice flows
  bool _tutorialActive = false;

  TimerData? _editingTimer;
  TimerData? _activeTimer;
  Timer? _ticker;

  final FlutterTts _tts = FlutterTts();
  final VoiceController _voiceController = VoiceController();
  late final PredefinedRoutines _routines;
  final CountdownController _countdownController = CountdownController();

  List<TimerData> _timers = [];
  TimerData? _voiceFilledTimer;

  static const String _timersKey = 'saved_timers_list';

  @override
  void initState() {
    super.initState();
    _initTts();

    _routines = PredefinedRoutines(
      stopListening: _stopListening,
      speak: _speak,
      playTimer: _playTimerV,
    );

    _loadTimers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.tutorialMode) _runTutorial();
    });
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.85);           // general comfy rate
      await _tts.awaitSpeakCompletion(true);     // speak sequentially
    } catch (_) {}
  }

  // ---------------------- Tutorial ----------------------
  Future<void> _runTutorial() async {
    _tutorialActive = true;
    try {
      // 1) Create tab
      if (!mounted) return;
      setState(() => _tabIndex = 1);
      await Future.delayed(const Duration(milliseconds: 250));
      await _tts.stop();
      await _tts.setSpeechRate(0.55);
      await _tts.speak(
          'This is the timer creation page. '
              'One, enter a name, for example study. '
              'Two, set work minutes, twenty five. '
              'Three, set break minutes, five. '
              'Four, set sets, four. '
              'You can also say: start a study timer for four sets with twenty five minute work and five minute break.'
      );

      // 2) Stopwatch selector tab
      if (!_tutorialActive || !mounted) return;
      setState(() => _tabIndex = 4);
      await Future.delayed(const Duration(milliseconds: 250));
      await _tts.stop();
      await _tts.setSpeechRate(0.50);
      await _tts.speak(
          'This is the stopwatch selector. '
              'Choose Normal Mode for a single stopwatch with voice control, '
              'or Player Mode for multiple timers.'
      );

      // 3) Normal Mode page
      if (!_tutorialActive || !mounted) return;
      await Future.delayed(const Duration(milliseconds: 300));
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const StopwatchNormalMode(autoStart: false),
        ),
      );

      if (!_tutorialActive) return;
      await _tts.stop();
      await _tts.setSpeechRate(0.35); // slower here
      await _tts.speak(
          'This is Normal Mode. Say start to begin, stop to pause, '
              'lap to mark a lap, and reset to clear. '
              'Buttons on screen also work.'
      );

      // 4) Back to Home
      if (!mounted) return;
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      setState(() => _tabIndex = 0);

      await _tts.setSpeechRate(0.85);
      await _tts.speak('Tutorial complete. You are back on the home screen.');
    } catch (_) {
      // swallow
    } finally {
      _tutorialActive = false;
    }
  }

  Future<void> _endTutorial({bool speak = true}) async {
    // Cancels tutorial flow and returns to Home; used by “skip” voice
    _tutorialActive = false;
    try {
      await _tts.stop();
    } catch (_) {}
    if (!mounted) return;
    while (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    setState(() => _tabIndex = 0);
    if (speak) {
      await _tts.setSpeechRate(0.85);
      await _tts.speak('Tutorial skipped. You are on the home screen.');
    }
  }

  // ---------------------- Persistence ----------------------
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

  // ---------------------- Timers ----------------------
  void _playTimerV(TimerDataV timerToPlay) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CountdownScreenV(timerData: timerToPlay),
      ),
    );
  }

  void _playTimer(TimerData timerToPlay) => _startTimer(timerToPlay);

  void _startTimer(TimerData timerData) {
    if ((timerData.totalTime) <= 0) {
      _speak("Timer duration is zero.");
      return;
    }
    if (_activeTimer?.id == timerData.id && (_ticker?.isActive ?? false)) {
      return;
    }
    _ticker?.cancel();

    if (!mounted) return;
    setState(() {
      _activeTimer = timerData.copyWith();
      _showingCountdown = true;
    });

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_activeTimer == null) { timer.cancel(); return; }

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
    _ticker?.cancel();
    _ticker = null;
    _speak("Timer paused.");
  }

  void _resumeTimer() {
    if (_activeTimer == null || _ticker != null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final current = _activeTimer!;
      final remaining = current.totalTime;
      if (remaining <= 0) { _stopTimer(); return; }
      setState(() => _activeTimer = current.copyWith(totalTime: remaining - 1));
    });
    _speak("Resuming timer.");
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

  String _generateUniqueTimerName(List<TimerData> timers) {
    int i = 1;
    while (true) {
      final name = "Timer $i";
      if (!timers.any((t) => t.name == name)) return name;
      i++;
    }
  }

  void _editTimer(TimerData timerToEdit) {
    setState(() {
      _editingTimer = timerToEdit;
      _tabIndex = 1;
    });
  }

  Future<void> _addOrUpdateTimer(TimerData timer) async {
    final index = _timers.indexWhere((t) => t.id == timer.id);
    setState(() {
      if (index != -1) _timers[index] = timer; else _timers.add(timer);
    });
    await _saveTimers();
  }

  void _addTimer(TimerData newTimer) async {
    setState(() => _timers.add(newTimer));
    await _saveTimers();
  }

  Future<void> _speak(String text) async {
    try { await _tts.speak(text); } catch (e) { debugPrint("TTS error: $e"); }
  }

  // ---------------------- Voice ----------------------
  Future<void> _startListening() async {
    await _tts.stop();
    _countdownController.stopSpeaking();
    if (_isListening) return;
    setState(() => _isListening = true);

    // While tutorial is active: ONLY listen for "skip" (or similar)
    if (_tutorialActive) {
      await _voiceController.startListeningForControl(
        onCommand: (cmd) async {
          if (!mounted) return;
          setState(() => _isListening = false);
          final w = cmd.toLowerCase();
          if (w.contains('skip') || w.contains('exit') || w.contains('stop tutorial') || w.contains('cancel')) {
            await _endTutorial();
          } else {
            await _voiceController.speak('During the tutorial, say "skip" to exit.');
          }
        },
      );
      return;
    }

    // Normal behavior
    if (_activeTimer != null) {
      await _voiceController.startListeningForControl(
        onCommand: (cmd) async {
          if (!mounted) return;
          setState(() => _isListening = false);

          final words = cmd.toLowerCase();
          if (words.contains("pause") || words.contains("hold")) {
            _countdownController.pause();
            _pauseTimer();
          } else if (words.contains("resume") || words.contains("continue")) {
            _countdownController.resume();
            _resumeTimer();
          } else if (words.contains("stop") || words.contains("end")) {
            _stopTimer();
          } else {
            _voiceController.speak("Command not recognized while timer is running.");
          }
        },
      );
      return;
    }

    await _voiceController.startListeningForTimer(
      onCommand: (ParsedVoiceCommand data) async {
        await _voiceController.stopListening();
        if (!mounted) return;
        setState(() => _isListening = false);

        await _voiceController.speak("Creating timer.");

        final work = data.workMinutes ?? data.simpleTimerMinutes ?? 0;
        final sets = data.sets ?? 1;
        final breaks = data.breakMinutes ?? 0;
        final totalTime = ((work * sets) + (breaks * (sets - 1))) * 60;

        final timerData = TimerData(
          id: DateTime.now().toIso8601String(),
          name: (data.name?.trim().isNotEmpty ?? false)
              ? data.name!
              : _generateUniqueTimerName(_timers),
          workInterval: work,
          breakInterval: breaks,
          totalSets: sets,
          totalTime: totalTime,
          currentSet: 1,
        );

        if (!mounted) return;
        setState(() {
          _voiceFilledTimer = timerData;
          _tabIndex = 1;
        });
      },
    );
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;
    try { await _voiceController.stopListening(); } finally {
      if (mounted) setState(() => _isListening = false);
    }
  }

  // ---------------------- UI helpers ----------------------
  void _switchTab(int index) {
    if (!mounted) return;
    setState(() => _tabIndex = index);
  }

  void _exitCountdown() {
    if (!mounted) return;
    setState(() {
      _showingCountdown = false;
      _tabIndex = 0;
    });
  }

  String _formatMMSS(int secondsTotal) {
    final m = secondsTotal ~/ 60;
    final s = secondsTotal % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ---------------------- Pages ----------------------
  List<Widget> get _pages => [
    HomeScreen(
      timers: _timers,
      onPlayTimer: _playTimer,
      onEditTimer: _editTimer,
      onDeleteTimer: (id) => setState(() {
        _timers.removeWhere((t) => t.id == id);
        _saveTimers();
      }),
      onSwitchTab: _switchTab,
      onStartTimer: _startTimer,
      activeTimer: _activeTimer,
    ),
    CreateTimerScreen(
      key: ValueKey(_voiceFilledTimer?.id ?? 'create_static'),
      existingTimer: _editingTimer ?? _voiceFilledTimer,
      onSaveTimer: (t) {
        _addOrUpdateTimer(t);
        _startTimer(t);
        setState(() {
          _editingTimer = null;
          _voiceFilledTimer = null;
          _showingCountdown = true;
        });
      },
    ),
    RoutinesPage(routines: _routines),
    const Placeholder(),
    const StopwatchModeSelector(),
  ];

  Widget _buildBody() {
    return Stack(
      children: [
        IndexedStack(index: _tabIndex, children: _pages),

        if (_activeTimer != null)
          Offstage(
            offstage: !_showingCountdown,
            child: CountdownScreen(
              timerData: _activeTimer!,
              onBack: _exitCountdown,
              controller: _countdownController,
            ),
          ),
      ],
    );
  }

  // ---------------------- Build (overflow-safe overlays) ----------------------
  @override
  Widget build(BuildContext context) {
    const double navHeight = kBottomNavigationBarHeight; // ~56
    return Scaffold(
      body: Stack(
        children: [
          _buildBody(),

          // Active timer banner overlay (if any)
          if (_activeTimer != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: navHeight + 72,
              child: _buildActiveTimerBanner(),
            ),

          // Global mic bar overlay (always above pages, just over nav)
          Positioned(
            left: 0,
            right: 0,
            bottom: navHeight,
            child: GestureDetector(
              onTap: _isListening ? _stopListening : _startListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: _isListening ? Colors.redAccent : const Color(0xFF007BFF),
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_isListening ? Icons.mic : Icons.mic_off, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      _tutorialActive
                          ? 'Tutorial active — say "skip"'
                          : (_isListening ? "Listening... Tap to stop" : "Tap to Speak"),
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
          ),
        ],
      ),

      // BottomNavigationBar only (no mic, no banner) to avoid overflow
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color(0xFF007BFF),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        currentIndex: _tabIndex,
        onTap: (index) {
          setState(() {
            if (_showingCountdown) _showingCountdown = false;
            _tabIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Routines'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Activity'),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Stopwatch'),
        ],
      ),
    );
  }

  // ---------------------- Banner ----------------------
  Widget _buildActiveTimerBanner() {
    final active = _activeTimer;
    if (active == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => setState(() => _showingCountdown = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        color: Colors.blue.withOpacity(0.12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(active.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Text("Timer Running"),
              ],
            ),
            Text(
              _formatMMSS(active.totalTime),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: _stopTimer,
              tooltip: 'Stop timer',
            ),
          ],
        ),
      ),
    );
  }
}
