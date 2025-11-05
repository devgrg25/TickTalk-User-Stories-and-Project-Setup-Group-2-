import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';

import 'settings_page.dart';
import 'stopwatch_normal_mode.dart';
import 'create_timer_screen.dart';
import 'timer_model.dart';
import 'countdown_screen.dart';
import 'stopwatchmodeselecter.dart';

import 'voice_controller.dart';
import 'routine_timer_model.dart';
import 'countdown_screenV.dart';
import 'routines.dart';
import 'routines_page.dart';
import 'create_routine_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final FlutterTts _tts = FlutterTts();
  final VoiceController _voiceController = VoiceController();
  late PredefinedRoutines _routines;

  bool _isListening = false;
  List<TimerData> _timers = [];
  static const String _timersKey = 'saved_timers_list';

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initPage();

    _routines = PredefinedRoutines(
      stopListening: _stopListening,
      speak: _speak,
      playTimer: _playTimerV,
    );
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
    if (_voiceController.isInitialized) {
      await _voiceController.speak(text);
    } else {
      try {
        await _tts.setLanguage('en-US');
        await _tts.setSpeechRate(0.9);
        await _tts.speak(text);
      } catch (e) {
        print("TTS error: $e");
      }
    }
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
      try {
        final List<dynamic> timerJson = jsonDecode(timersString);
        setState(() {
          _timers = timerJson.map((json) => TimerData.fromJson(json)).toList();
        });
      } catch (e) {
        print("Could not load original timers, format might be wrong: $e");
        await prefs.remove(_timersKey);
        _timers = [];
      }
    }
  }

  Future<void> _saveTimers() async {
    final prefs = await SharedPreferences.getInstance();
    final String timersString =
    jsonEncode(_timers.map((timer) => timer.toJson()).toList());
    await prefs.setString(_timersKey, timersString);
  }

  void _addOrUpdateTimer(TimerData timer) {
    final index = _timers.indexWhere((t) => t.id == timer.id);
    setState(() {
      if (index != -1) {
        _timers[index] = timer;
      } else {
        _timers.add(timer);
      }
    });
    _saveTimers();
  }

  void _deleteTimer(String timerId) {
    setState(() {
      _timers.removeWhere((timer) => timer.id == timerId);
    });
    _saveTimers();
  }

  void _openCreateTimerScreen() async {
    final result = await Navigator.push<TimerData>(
      context,
      MaterialPageRoute(builder: (_) => const CreateTimerScreen()),
    );
    if (result != null) _addOrUpdateTimer(result);
  }

  void _editTimer(TimerData timerToEdit) async {
    final result = await Navigator.push<TimerData>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTimerScreen(existingTimer: timerToEdit),
      ),
    );
    if (result != null) _addOrUpdateTimer(result);
  }

  void _playTimer(TimerData timerToPlay) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CountdownScreen(timerData: timerToPlay),
      ),
    );
  }

  void _openStopwatchSelector() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StopwatchModeSelector()),
    );
  }

  Future<void> _startListening() async {
    if (!_voiceController.isInitialized) {
      await _voiceController.initialize();
      if (!_voiceController.isInitialized) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice controller not ready. Please check permissions.')),
        );
        return;
      }
    }
    setState(() => _isListening = true);
    await _voiceController.speak("Listening");

    await _voiceController.listenAndRecognize(
      onCommandRecognized: (String command) async {
        if (!mounted) return;
        _handleVoiceCommand(command);
      },
      onComplete: () {
        if (mounted && _isListening) {
          setState(() => _isListening = false);
        }
      },
    );
  }

  Future<void> _stopListening() async {
    if (!mounted || !_isListening) return;
    setState(() => _isListening = false);
    await _voiceController.stopListening();
  }

  void _handleVoiceCommand(String command) async {
    final normalized = command.toLowerCase().trim();
    debugPrint("Homepage Recognized: $normalized");

    if (normalized.startsWith('hey tick talk')) {
      String routineCmd = normalized.replaceFirst('hey tick talk', '').trim();
      bool routineMatched = true;

      if (routineCmd.contains('mindfulness')) {
        _routines.startMindfulnessMinute();
      } else if (routineCmd.contains('laundry')) {
        _routines.startSimpleLaundryCycle();
      } else if (routineCmd.contains('20 20 20')) {
        _routines.start202020Rule();
      } else if (routineCmd.contains('pomodoro') || routineCmd.contains('focus')) {
        _routines.startPomodoroTimer();
      } else if (routineCmd.contains('exercise') || routineCmd.contains('workout')) {
        _routines.startExerciseTimer();
      } else if (routineCmd.contains('morning')) {
        _routines.startMorningIndependence();
      } else if (routineCmd.contains('recipe')) {
        _routines.startRecipePrep();
      } else {
        routineMatched = false;
        _speak("Sorry, I heard 'Hey Tick Talk' but didn't recognize that routine.");
      }
      if (routineMatched) return;
    }

    if (normalized.contains('create timer') ||
        normalized.contains('new timer') ||
        normalized == 'timer') {
      await _speak("Opening timer creation screen.");
      _openCreateTimerScreen();
    } else if (normalized.contains('start stopwatch') ||
        normalized.contains('open stopwatch') ||
        normalized == 'stopwatch') {
      await _speak("Opening stopwatch.");
      _openStopwatchSelector();
    } else if (normalized.contains('open settings') ||
        normalized == 'settings') {
      await _speak("Opening settings.");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsPage()),
      );
    } else {
      if (!normalized.startsWith('hey tick talk')) {
        await _speak("Sorry, I didn't understand that command.");
      }
    }
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0: // Home
        setState(() => _selectedIndex = 0);
        break;
      case 1: // Create
        _openCreateTimerScreen();
        break;
      case 2: // Routines
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoutinesPage(
              routines: _routines,
              voiceController: _voiceController,
            ),
          ),
        );
        break;
      case 3: // Activity
        setState(() => _selectedIndex = 3);
        break;
      case 4: // Stopwatch
        _openStopwatchSelector();
        break;
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _voiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FA),
      appBar: AppBar(
        title: const Text('TickTalk', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openCreateTimerScreen,
                icon: const Icon(Icons.add_circle_outline, size: 28),
                label: const Text('Create New Timer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007BFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              "Your Timers",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _timers.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  "You haven't created any timers yet.",
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _timers.length,
              itemBuilder: (context, index) {
                final timer = _timers[index];
                return TimerCard(
                  title: timer.name,
                  status: 'Ready',
                  feedback: 'Audio + Haptic',
                  color: const Color(0xFF007BFF),
                  onPlay: () => _playTimer(timer),
                  onEdit: () => _editTimer(timer),
                  onDelete: () => _deleteTimer(timer.id),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF007BFF),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Routines',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer),
            label: 'Stopwatch',
          ),
        ],
      ),
      bottomSheet: SafeArea(
        child: GestureDetector(
          onTap: _isListening ? _stopListening : _startListening,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            color: _isListening ? Colors.redAccent : const Color(0xFF007BFF),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

class TimerCard extends StatelessWidget {
  final String title;
  final String status;
  final String feedback;
  final Color color;
  final VoidCallback onPlay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TimerCard({
    super.key,
    required this.title,
    required this.status,
    required this.feedback,
    required this.color,
    required this.onPlay,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Feedback: $feedback',
              style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: onPlay,
                icon: const Icon(Icons.play_circle_fill, color: Color(0xFF007BFF), size: 32),
              ),
              IconButton(
                onPressed: onEdit,
                icon: Icon(Icons.edit, color: Colors.grey[600]),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}