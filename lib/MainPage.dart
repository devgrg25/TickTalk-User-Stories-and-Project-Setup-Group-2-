import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';

import 'homepage.dart';
import 'settings_page.dart';
import 'stopwatch_normal_mode.dart';
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
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  bool _isListening = false;
  TimerData? _editingTimer;

  final FlutterTts _tts = FlutterTts();
  final VoiceController _voiceController = VoiceController();
  late PredefinedRoutines _routines;

  List<TimerData> _timers = [];
  TimerData? _voiceFilledTimer;
  static const String _timersKey = 'saved_timers_list';

  @override
  void initState() {
    super.initState();
    _routines = PredefinedRoutines(
      stopListening: _stopListening,
      speak: _speak,
      playTimer: _playTimerV,
    );
    _loadTimers();
  }

  void _switchTab(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _loadTimers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? timersString = prefs.getString(_timersKey);
    if (timersString != null) {
      final List<dynamic> timerJson = jsonDecode(timersString);
      setState(() {
        _timers = timerJson.map((json) => TimerData.fromJson(json)).toList();
      });
    }
  }

  Future<void> _saveTimers() async {
    final prefs = await SharedPreferences.getInstance();
    final String timersString =
    jsonEncode(_timers.map((timer) => timer.toJson()).toList());
    await prefs.setString(_timersKey, timersString);
  }

  void _deleteTimer(String timerId) {
    setState(() {
      _timers.removeWhere((timer) => timer.id == timerId);
    });
    _saveTimers();
  }

  void _editTimer(TimerData timerToEdit) {
    setState(() {
      _editingTimer = timerToEdit;
      _selectedIndex = 1;
    });
  }

  void _addOrUpdateTimer(TimerData timer) async {
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


  void _playTimerV(TimerDataV timerToPlay) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CountdownScreenV(timerData: timerToPlay),
      ),
    );
  }

  void _playTimer(TimerData timerToPlay) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CountdownScreen(timerData: timerToPlay),
      ),
    );
  }


  Future<void> _speak(String text) async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.9);
      await _tts.speak(text);
    } catch (e) {
      print("TTS error: $e");
    }
  }

  // ----------------- VOICE FUNCTIONS -----------------
  Future<void> _startListening() async {
    if (_isListening) return;
    setState(() => _isListening = true);

    await _voiceController.startListeningForTimer(
      onCommand: (ParsedVoiceCommand data) async {

        await _voiceController.stopListening();
        if (mounted) setState(() => _isListening = false);
          // 🎯 Go to CreateTimerScreen and fill recognized values
          _voiceController.speak("Opening create timer screen.");

        final work = data.workMinutes ?? data.simpleTimerMinutes ?? 0;
        final sets = data.sets ?? 1;
        final breaks = data.breakMinutes ?? 0;
        final totalTime = (work * sets) + (breaks * (sets - 1));

          final timerData = TimerData(
            id: DateTime.now().toIso8601String(),
            name: data.name ?? "New Timer",
            workInterval: work,
            breakInterval: breaks,
            totalSets: data.sets ?? 1,
            totalTime: totalTime,
            currentSet: 1,
          );

          // Save it for CreateTimerScreen to use
          setState(() {
            _voiceFilledTimer = timerData;
            _selectedIndex = 1; // 👈 switch to “Create” tab
          });
      },
    );
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;
    setState(() => _isListening = false);
    await _voiceController.stopListening();
  }

  @override
  void dispose() {
    _tts.stop();
    _voiceController.dispose();
    super.dispose();
  }

  void _addTimer(TimerData newTimer) async {
    setState(() {
      _timers.add(newTimer);
    });
    await _saveTimers();
  }

  // ----------------- PAGES LIST -----------------
  List<Widget> get _pages => [
    HomeScreen(
      timers: _timers,
      onPlayTimer: _playTimer,
      onEditTimer: _editTimer,
      onDeleteTimer: _deleteTimer,
      onSwitchTab: _switchTab,
    ),
    CreateTimerScreen(key: ValueKey(_voiceFilledTimer?.id ?? DateTime.now().millisecondsSinceEpoch),
      existingTimer: _editingTimer ?? _voiceFilledTimer,
      onSaveTimer: _addTimer,
    ),
    RoutinesPage(routines: _routines),
    const Placeholder(), // Activity page
    const StopwatchModeSelector(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: List.generate(_pages.length, (index) {
          return Offstage(
            offstage: _selectedIndex != index,
            child: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => _pages[index],
              ),
            ),
          );
        }),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BottomNavigationBar(
            selectedItemColor: const Color(0xFF007BFF),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Create'),
              BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Routines'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Activity'),
              BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Stopwatch'),
            ],
          ),
          GestureDetector(
            onTap: _isListening ? _stopListening : _startListening,
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
}
