import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'settings_page.dart';
import 'stopwatch_normal_mode.dart';
import 'create_timer_screen.dart';
import 'dart:convert';
import 'timer_model.dart';
import 'countdown_screen.dart';
import 'stopwatchmodeselecter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // UPDATED: Changed _HomeScreenState to the public HomeScreenState
  State<HomeScreen> createState() => HomeScreenState();
}

// UPDATED: Renamed class to be public
class HomeScreenState extends State<HomeScreen> {
  final FlutterTts _tts = FlutterTts();
  List<TimerData> _timers = [];
  static const String _timersKey = 'saved_timers_list';

  @override
  void initState() {
    super.initState();
    _loadTimers();
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
    final String timersString = jsonEncode(_timers.map((timer) => timer.toJson()).toList());
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
    if (result != null) {
      _addOrUpdateTimer(result);
    }
  }

  void _editTimer(TimerData timerToEdit) async {
    final result = await Navigator.push<TimerData>(
      context,
      MaterialPageRoute(builder: (_) => CreateTimerScreen(existingTimer: timerToEdit)),
    );
    if (result != null) {
      _addOrUpdateTimer(result);
    }
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

  void _showSnackbar(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // --- PUBLIC METHODS FOR THE AppShell TO CALL ---
  void startMindfulnessMinute() async {
    _speak("Starting Mindfulness Minute. Find a comfortable position.");
    _showSnackbar('Phase 1: 30 seconds of focused breathing.');
    await Future.delayed(const Duration(seconds: 5));
    _speak("Time's up. Phase two: Now, for fifteen seconds, notice any sounds around you.");
    _showSnackbar('Phase 2: 15 seconds of silence/listening.');
    await Future.delayed(const Duration(seconds: 5));
    _speak("Mindfulness Minute complete. Return to your daily activity.");
    _showSnackbar('Mindfulness Minute complete.');
  }

  void startSimpleLaundryCycle() async {
    _speak("Starting Simple Laundry Cycle. Time to load the clothes.");
    _showSnackbar('Phase 1: 2 minutes to load clothes and start the wash.');
    await Future.delayed(const Duration(seconds: 5));
    _speak("Phase two: Wash cycle complete. You have three minutes to transfer clothes to the dryer.");
    _showSnackbar('Phase 2: 3 minutes to transfer to dryer.');
    await Future.delayed(const Duration(seconds: 5));
    _speak("Transfer time is over. Drying cycle complete. Time to sort the laundry for storage!");
    _showSnackbar('Laundry cycle complete.');
  }

  void start202020Rule() async {
    _speak("Starting 20-20-20 rule. You will be reminded every 20 minutes to take a break.");
    _showSnackbar('20-20-20 Rule started! Reminder in 20 minutes.');
    await Future.delayed(const Duration(seconds: 5));
    _speak("20-20-20 break now. Turn away from your focus area and rest your eyes for 20 seconds.");
    _showSnackbar('20-second break: Turn away and rest.');
    await Future.delayed(const Duration(seconds: 5));
    _speak("Break over. Return to work. Next reminder in 20 minutes.");
  }

  void openNormalStopwatch({bool autoStart = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StopwatchNormalMode(autoStart: autoStart)),
    );
  }

  void rerunTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcome', false);
    if (context.mounted) {
      _showSnackbar('Command recognized! Tutorial will show on next app start.');
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This Scaffold now only contains the content for the home page.
    // No BottomNavigationBar or microphone bar.
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('TickTalk', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (String result) {
              if (result == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.chrome_reader_mode_outlined),
                    SizedBox(width: 10),
                    Text("About"),
                  ],
                ),
              ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline, size: 24),
                label: const Text('Create New Timer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007BFF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _openCreateTimerScreen,
              ),
            ),
            const SizedBox(height: 24),
            const Text('Pre-defined Timer Routines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  RoutineCard(title: 'Exercise Sets', description: 'Intervals for strength & cardio training.', icon: Icons.fitness_center),
                  RoutineCard(title: 'Pomodoro Focus', description: '25-min work, 5-min break cycles.', icon: Icons.timer_outlined),
                  RoutineCard(title: 'Mindfulness Minute', description: 'Structured meditation with spoken intervals.', icon: Icons.spa_outlined, onPressed: startMindfulnessMinute),
                  RoutineCard(title: 'Simple Laundry Cycle', description: 'Timed steps for washing, drying, and sorting items for storage.', icon: Icons.local_laundry_service_outlined, onPressed: startSimpleLaundryCycle),
                  RoutineCard(title: 'Morning Independence', description: '3 min wash, 2 min dress, 5 min eat cycle.', icon: Icons.wb_sunny_outlined),
                  RoutineCard(title: 'Recipe Prep Guide', description: 'Sequential timers for common cooking steps.', icon: Icons.restaurant_menu),
                  RoutineCard(title: 'The 20-20-20 Rule', description: 'Audible guide for muscle relaxation: turn away from your focus every 20 mins for a 20-second break.', icon: Icons.remove_red_eye_outlined, onPressed: start202020Rule),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Your Timers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 12),
            _timers.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text("You haven't created any timers yet.", style: TextStyle(color: Colors.grey)),
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
    );
  }
}

// These helper widgets are used by HomeScreen
class RoutineCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onPressed;

  const RoutineCard({super.key, required this.title, required this.description, required this.icon, this.onPressed});

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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF007BFF), size: 32),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 6),
          Expanded(child: Text(description, style: const TextStyle(fontSize: 13, color: Colors.black54), maxLines: 3, overflow: TextOverflow.ellipsis)),
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

class TimerCard extends StatelessWidget {
  final String title, status, feedback;
  final Color color;
  final VoidCallback onPlay, onEdit, onDelete;

  const TimerCard({super.key, required this.title, required this.status, required this.feedback, required this.color, required this.onPlay, required this.onEdit, required this.onDelete});

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Feedback: $feedback', style: const TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(onPressed: onPlay, icon: const Icon(Icons.play_arrow, color: Colors.black54)),
              IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, color: Colors.black54)),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Colors.redAccent)),
            ],
          ),
        ],
      ),
    );
  }
}

