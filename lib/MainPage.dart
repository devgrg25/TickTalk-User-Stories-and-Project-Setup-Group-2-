import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'dart:async';
import 'stopwatch_normal_mode.dart';
import 'homepage.dart';
import 'create_timer_screen.dart';
import 'timer_model.dart';
import 'countdown_screen.dart';
import 'countdown_screenV.dart';
import 'stopwatchmodeselecter.dart';
import 'voice_controller.dart';
import 'routine_timer_model.dart';
import 'routines.dart';
import 'routines_page.dart';

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
  //tutorial variables
  bool tutorialActive = false;
  bool tutorialPaused = false;
  int tutorialStep = 0;
  //create timer variables
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

  // ---------- INIT / DISPOSE ----------
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.tutorialMode) {
        _startTutorial();
      }
    });
    // TTS once
    _initTts();

    _routines = PredefinedRoutines(
      stopListening: _stopListening,
      speak: _speak,
      playTimer: _playTimerV,
    );

    _loadTimers();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.9);
    } catch (_) {
      // swallow; device/engine variance
    }
  }


  void _pauseTimer() {
    if (_ticker == null) return;
    _ticker!.cancel();
    _ticker = null;
    _speak("Timer paused.");
  }

  void _resumeTimer() {
    if (_activeTimer == null || _ticker != null) return;

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final current = _activeTimer!;
      final remaining = current.totalTime;

      if (remaining <= 0) {
        _stopTimer();
        return;
      }

      setState(() {
        _activeTimer = current.copyWith(totalTime: remaining - 1);
      });
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
      _voiceFilledTimer = null;   // prevent voice timer from overwriting edit data
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

  void _addTimer(TimerData newTimer) async {
    setState(() {
      _timers.add(newTimer);
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

  // ---------- TIMER CONTROL ----------
  void _playTimerV(TimerDataV timerToPlay) {
    // Left as-is per your code; safe isolate
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
    if ((timerData.totalTime) <= 0) {
      _speak("Timer duration is zero.");
      return;
    }

    // If this exact timer is already active, do nothing
    if (_activeTimer?.id == timerData.id && (_ticker?.isActive ?? false)) {
      return;
    }

    // Cancel any existing ticker
    _ticker?.cancel();

    if (!mounted) return;
    setState(() {
      // Use a detached copy to mutate countdown independently from list item
      _activeTimer = timerData.copyWith();
      _showingCountdown = true; // show fullscreen initially
    });

    // Periodic ticker
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_activeTimer == null) {
        timer.cancel();
        return;
      }

      // Basic single-phase countdown (work/break logic can be layered later)
      final current = _activeTimer!;
      final remaining = current.totalTime;

      if (remaining <= 0) {
        timer.cancel();
        if (!mounted) return;

        // Speak first (optional delay before screen change)
        _speak("Time's up.");

        // Safely return to home after a short delay
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          setState(() {
            _activeTimer = null;
            _showingCountdown = false;
            _tabIndex = 0; // ✅ ensures home screen is shown
          });
        });
        return;
      }

      // Decrement by 1s
      setState(() {
        _activeTimer = current.copyWith(totalTime: remaining - 1);
      });
    });
  }

  // Called when Create page saves a timer
  void _handleSaveTimer(TimerData timer) {
    _addOrUpdateTimer(timer);
    _startTimer(timer);

    if (!mounted) return;
    setState(() {
      _editingTimer = null;
      _voiceFilledTimer = null;
      _showingCountdown = true; // jump into fullscreen view
    });
  }

  // ---------- VOICE ----------
  Future<void> _startListening() async {
    await _tts.stop();
    _countdownController.stopSpeaking();
    if (_isListening) return;
    setState(() => _isListening = true);

    // CASE 0: Tutorial is active → only listen for skip / resume
    if (tutorialActive) {
      debugPrint('Case 0');
      setState(() => _isListening = true);

      await _voiceController.startListeningRaw(
        onCommand: (String heard) async {
          final words = heard.toLowerCase().trim();
          setState(() => _isListening = false);

          //SKIP / END tutorial commands
          if (words.contains("skip") ||
              words.contains("stop tutorial") ||
              words.contains("end tutorial") ||
              words.contains("cancel tutorial") ||
              words.contains("done")) {
            _endTutorial();
            return;
          }

          //No skip → Resume tutorial where it left off
          setState(() => tutorialPaused = false);
          _runTutorial();
        },
      );

      return; //STOP HERE (do NOT allow timer voice logic)
    }

    // CASE 1: There is an active timer → listen for pause/resume/stop
    if (_activeTimer != null) {
      debugPrint('Case 1');
      await _voiceController.startListeningForControl(
        onCommand: (cmd) async {
          setState(() => _isListening = false);

          final words = cmd.toLowerCase();
          debugPrint(words);

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

    // CASE 2: No timer active → treat as timer creation command
    await _voiceController.startListeningForTimer(
      onCommand: (ParsedVoiceCommand data) async {
        await _voiceController.stopListening();
        debugPrint('Case 2');
        if (!mounted) return;
        setState(() => _isListening = false);

        //await _voiceController.speak("Creating timer.");

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
          _editingTimer = null;
          _voiceFilledTimer = timerData;
          _tabIndex = 1; // switch to Create screen
        });
      },
    );
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;
    try {
      await _voiceController.stopListening();
    } finally {
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
  }
  //-----------Tutorial functions----------------
  void _endTutorial() async {
    setState(() {
      tutorialActive = false;
      tutorialPaused = false;
    });

    await _tts.stop();
    await _speakWait("Tutorial skipped. You can now explore the app freely.");
  }

  void _startTutorial() {
    setState(() {
      tutorialActive = true;
      tutorialPaused = false;
      tutorialStep = 0;
    });
    _runTutorial();
  }

  Future<void> _runTutorial() async {
    if (!mounted || tutorialPaused == true) return;

    switch (tutorialStep) {

    // STEP 0 — Create Timer Page
      case 0:
        setState(() => _tabIndex = 1);
        await _speakWait(
            'This is the timer creation page. Here is a step by step guide on how to use it. '
                'One: enter a timer name. Two: set work minutes. Three: set break minutes. Four: set the number of sets. '
                'You can also say: Start a study timer for four sets with twenty five minutes work and five minutes break.'
        );
        tutorialStep++;
        break;

    // STEP 1 — Stopwatch Selector
      case 1:
        setState(() => _tabIndex = 4);
        await _speakWait(
            'This is the stopwatch selector. Choose Normal Mode for a single stopwatch with voice control, '
                'or Player Mode to track up to six players.'
        );
        tutorialStep++;
        break;

    // STEP 2 — Normal Mode Page
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StopwatchNormalMode(autoStart: false)),
        );
        await Future.delayed(const Duration(milliseconds: 200));
        await _speakWait(
            'This is Normal Mode. Say start to begin, stop to pause, lap to mark a lap, and reset to clear it.'
        );
        tutorialStep++;
        break;

    // TUTORIAL DONE
      default:
        tutorialActive = false;
        await _speakWait("Tutorial complete. You can now explore the app freely.");
        break;
    }

    // Continue automatically unless paused
    if (tutorialActive && !tutorialPaused) {
      _runTutorial();
    }
  }
  Future<void> _speakWait(String text) async {
    await _tts.stop();
    await _tts.setSpeechRate(0.45);
    await _tts.awaitSpeakCompletion(true);
    await _tts.speak(text);

    // Wait here if paused (speech will be frozen)
    while (tutorialPaused) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }


  // ---------- UI HELPERS ----------
  String _formatMMSS(int secondsTotal) {
    final m = secondsTotal ~/ 60;
    final s = secondsTotal % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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
    ),
    // ValueKey forces Create page to rebuild when voice prefills change
    CreateTimerScreen(
      key: ValueKey(_voiceFilledTimer?.id ?? 'create_static'),
      existingTimer: _editingTimer ?? _voiceFilledTimer,
      onSaveTimer: _handleSaveTimer,
      startVoiceConfirmation: (_voiceFilledTimer != null && _editingTimer == null),
    ),
    RoutinesPage(routines: _routines),
    const Placeholder(), // Activity page
    const StopwatchModeSelector(),
  ];

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
              controller: _countdownController,
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
          if (_activeTimer != null) _buildActiveTimerBanner(),
          BottomNavigationBar(
            selectedItemColor: _showingCountdown
                ? Colors.grey             // No highlight when countdown is showing
                : const Color(0xFF007BFF),// Normal highlight when not in countdown

            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            currentIndex: _tabIndex,      // ← keep this unchanged
            onTap: (index) {
              setState(() {
                if (_showingCountdown) {
                  _showingCountdown = false; // Close countdown when switching tabs
                }
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
          GestureDetector(
            onTap: () async {
              if (_isListening) {
                // User finished speaking → Resume tutorial
                await _stopListening();

                if (tutorialActive) {
                  setState(() => tutorialPaused = false);
                  _runTutorial(); // resume
                }

              } else {
                // User starts speaking → Pause tutorial
                if (tutorialActive) {
                  setState(() => tutorialPaused = true);
                  await _tts.stop(); // stop speaking immediately
                }

                await _startListening();
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

  // ---------- BANNER ----------
  Widget _buildActiveTimerBanner() {
    final active = _activeTimer;
    if (active == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => setState(() => _showingCountdown = true), // <-- FULL BANNER IS TAPPABLE
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        color: Colors.blue.withOpacity(0.12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Name + status
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Text("Timer Running"),
              ],
            ),

            // Remaining time (no underline now, since whole banner is clickable)
            Text(
              _formatMMSS(active.totalTime),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),

            // Stop button still works independently
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
