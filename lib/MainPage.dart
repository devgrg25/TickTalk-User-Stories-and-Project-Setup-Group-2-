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
    _initPage();
  }

  Future<void> _initPage() async {
    await _voiceController.initialize();
    await _loadTimers();
    await _speak("You are now on the home page.");
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

  void _playTimerV(TimerDataV timerToPlay) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CountdownScreenV(timerData: timerToPlay),
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

    await _voiceController.startListening(
      onCommand: (ParsedVoiceCommand data) async {

        await _voiceController.stopListening();
        if (mounted) setState(() => _isListening = false);
          // 🎯 Go to CreateTimerScreen and fill recognized values
          _voiceController.speak("Opening create timer screen.");

          final timerData = TimerData(
            id: DateTime.now().toIso8601String(),
            name: data.name ?? "New Timer",
            workInterval: (data.workMinutes ?? data.simpleTimerMinutes ?? 0),
            breakInterval: (data.breakMinutes ?? 0),
            totalSets: data.sets ?? 1,
            totalTime: (data.workMinutes ?? data.simpleTimerMinutes ?? 0 * (data.sets ?? 1)) + ((data.breakMinutes ?? 0) * ((data.sets ?? 1) - 1)),
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

  // ----------------- PAGES LIST -----------------
  List<Widget> get _pages => [
    const HomeScreen(),
    CreateTimerScreen(key: ValueKey(_voiceFilledTimer?.id ?? DateTime.now().millisecondsSinceEpoch),
      existingTimer: _voiceFilledTimer,),
    RoutinesPage(routines: _routines),
    const Placeholder(), // Activity page
    const StopwatchModeSelector(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
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
