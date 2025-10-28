import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';

import 'settings_page.dart';
import 'stopwatch_normal_mode.dart';
import 'create_timer_screen.dart';
import 'timer_model.dart';
import 'countdown_screen.dart';
import 'countdown_screenV.dart';
import 'stopwatchmodeselecter.dart';
import 'voice_controller.dart';
import 'routine_timer_model.dart';

import 'routines.dart'; // <-- Imports NEW routines
import 'routines_page.dart';

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
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.9);
      await _tts.speak(text);
    } catch (e) {
      print("TTS error: $e");
    }
  }

  Future<void> _initPage() async {
    await _voiceController.initialize();
    await _loadTimers();
    await _tts.speak("You are now on the home page.");
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

  void _openNormalStopwatch({bool autoStart = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StopwatchNormalMode(autoStart: autoStart),
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
    if (_isListening) return;
    setState(() => _isListening = true);

    await _voiceController.listenAndRecognize(onComplete: () {
      if (mounted) {
        setState(() => _isListening = false);
      }
    });
  }

  Future<void> _stopListening() async {
    setState(() => _isListening = false);
    await _voiceController.stopListening();
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
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'TickTalk',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black),
              onPressed: () {}),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (String result) {
              if (result == 'settings') {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsPage()));
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined),
                    SizedBox(width: 10),
                    Text("Settings"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      // ----------------------- MAIN BODY ------------------------
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 110), // increased from 90
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
                    onPressed: _openCreateTimerScreen,
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
                _timers.isEmpty
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
        ),
      ),

      // ----------------------- BOTTOM MIC BAR ------------------------
      /*bottomSheet: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BottomNavigationBar(
              selectedItemColor: const Color(0xFF007BFF),
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              onTap: (index) {
                if (index == 1) {
                  _openCreateTimerScreen();
                }
                else if(index == 2){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoutinesPage(routines: _routines),
                    ),
                  );
                }
                else if (index == 4) {
                  _openStopwatchSelector();
                }
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
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
              onTap: _isListening ? _stopListening : _startListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: _isListening
                    ? Colors.redAccent
                    : const Color(0xFF007BFF),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 28), // doubled tap area here
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
      ),*/
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
          const SizedBox(height: 8),
          TextButton(
            onPressed: onPressed ?? () {},
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Start Routine', style: TextStyle(fontSize: 14)),
                Icon(Icons.arrow_right_alt, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------
// TimerCard
// ---------------------------------------------
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
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
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
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(status,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 8),
          Text('Feedback: $feedback',
              style: const TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            IconButton(
                onPressed: onPlay,
                icon: const Icon(Icons.play_arrow, color: Colors.black54)),
            IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, color: Colors.black54)),
            IconButton(
                onPressed: onDelete,
                icon:
                const Icon(Icons.delete_outline, color: Colors.redAccent)),
          ]),
        ],
      ),
    );
  }
}
