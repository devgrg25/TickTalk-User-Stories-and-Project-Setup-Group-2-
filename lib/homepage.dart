import 'package:flutter/material.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
//import 'dart:convert';
import 'settings_page.dart';
//import 'stopwatch_normal_mode.dart';
//import 'create_timer_screen.dart';
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
  final List<TimerData> timers;
  final Function(TimerData) onPlayTimer;
  final Function(TimerData) onEditTimer;
  final Function(String) onDeleteTimer;
  final void Function(int) onSwitchTab;
  final Function(TimerData) onStartTimer;
  final TimerData? activeTimer;

  const HomeScreen({
    super.key,
    required this.timers,
    required this.onPlayTimer,
    required this.onEditTimer,
    required this.onDeleteTimer,
    required this.onSwitchTab,
    required this.onStartTimer,
    this.activeTimer,
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final FlutterTts _tts = FlutterTts();
  final VoiceController _voiceController = VoiceController();
  bool _isListening = false;
  late PredefinedRoutines _routines;

  //static const String _timersKey = 'saved_timers_list';

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
    //await _loadTimers();
    await Future.delayed(const Duration(milliseconds: 1000));
    await _tts.speak("You are now on the home page.");
  }
/*
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

  void _deleteTimer(String timerId) {
    setState(() {
      _timers.removeWhere((timer) => timer.id == timerId);
    });
    _saveTimers();
  }

  void _addOrUpdateTimer(TimerData timer) {
    final index = widget.timers.indexWhere((t) => t.id == timer.id);
    setState(() {
      if (index != -1) {
        widget.timers[index] = timer;
      } else {
        widget.timers.add(timer);
      }
    });
    _saveTimers();
  }


  void _openCreateTimerScreen() async {
    final result = await Navigator.push<TimerData>(
      context,
      MaterialPageRoute(builder: (_) => const CreateTimerScreen()),
    );
    if (result != null){
      _addOrUpdateTimer(result);
    }
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
 */
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
        title: const Text('TickTalk', style: TextStyle(color: Color(0xFF007BFF), fontWeight: FontWeight.bold, fontSize: 30)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
            },
          ),
        ],
      ),

      // ----------------------- MAIN BODY ------------------------
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          // increased from 90
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline, size: 24),
                    label: const Text(
                      'Create New Timer',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007BFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => widget.onSwitchTab(1),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Pre-defined Timer Routines',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      RoutineCard(
                        title: 'Mindfulness Minute',
                        description:
                        'Structured meditation with spoken intervals.',
                        icon: Icons.spa_outlined,
                        onPressed: () async {
                          await _tts.speak(
                              "Starting Mindfulness Minute. Relax and focus on your breathing.");
                        },
                      ),
                      RoutineCard(
                        title: 'Simple Laundry Cycle',
                        description:
                        'Timed steps for washing, drying, and sorting items.',
                        icon: Icons.local_laundry_service_outlined,
                        onPressed: () async {
                          await _tts.speak(
                              "Starting Simple Laundry Cycle. Begin by loading your clothes.");
                        },
                      ),
                      RoutineCard(
                        title: 'The 20-20-20 Rule',
                        description:
                        'Reminds you to rest your eyes every 20 minutes.',
                        icon: Icons.remove_red_eye_outlined,
                        onPressed: () async {
                          await _tts.speak(
                              "Starting 20-20-20 rule. Remember to take regular eye breaks.");
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Your Timers',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                ),
                const SizedBox(height: 12),
                widget.timers.isEmpty
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      "You haven't created any timers yet.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 40),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.timers.length,
                  itemBuilder: (context, index) {
                    final timer = widget.timers[index];
                    final bool isActive = widget.activeTimer?.id == timer.id;

                    return TimerCard(
                      title: timer.name,
                      status: isActive ? 'Active' : 'Ready',
                      feedback: 'Audio + Haptic',
                      color: isActive ? Colors.green : const Color(0xFF007BFF),
                      onPlay: () {
                        if (!isActive) {
                          widget.onStartTimer(timer);
                        }
                        else {
                          widget.onPlayTimer(timer);
                        }
                      },
                      onEdit: () => widget.onEditTimer(timer),
                      onDelete: () => widget.onDeleteTimer(timer.id),
                    );

                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------
// RoutineCard
// ---------------------------------------------
class RoutineCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onPressed;

  const RoutineCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 250,
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF007BFF), size: 32),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 6),
          Expanded(
            child: Text(description,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
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
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title,
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
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