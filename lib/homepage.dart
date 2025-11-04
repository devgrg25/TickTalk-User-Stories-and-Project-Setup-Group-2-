import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'dart:math' as math;

import 'settings_page.dart';
import 'stopwatch_normal_mode.dart';
import 'create_timer_screen.dart';
import 'timer_model.dart';
import 'countdown_screen.dart';
import 'countdown_screenV.dart';
import 'stopwatchmodeselecter.dart';
import 'voice_controller.dart';
import 'routine_timer_model.dart';
import 'routines_page.dart';
import 'routines.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  final VoiceController _voiceController = VoiceController();
  late PredefinedRoutines _routines;

  bool _isListening = false;
  List<TimerData> _timers = [];
  static const String _timersKey = 'saved_timers_list';

  late final AnimationController _micController;

  @override
  void initState() {
    super.initState();
    _initPage();
    _routines = PredefinedRoutines(
      stopListening: _stopListening,
      speak: _speak,
      playTimer: _playTimerV,
    );

    _micController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
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

  // -----------------------------------------------------------------
  // VOICE HANDLING
  // -----------------------------------------------------------------
  Future<void> _startListening() async {
    if (_isListening) return;
    setState(() => _isListening = true);
    _micController.repeat();

    await _voiceController.listenAndRecognize(
      onCommandRecognized: (String command) async {
        final normalized = command.toLowerCase().trim();
        debugPrint("Recognized voice command: $normalized");

        if (normalized.contains('create timer') ||
            normalized.contains('new timer') ||
            normalized.contains('start timer') ||
            normalized.contains('open timer') ||
            normalized == 'timer') {
          await _tts.speak("Opening timer creation screen.");
          _openCreateTimerScreen();
        } else if (normalized.contains('start stopwatch') ||
            normalized.contains('open stopwatch') ||
            normalized == 'stopwatch') {
          await _tts.speak("Opening stopwatch.");
          _openStopwatchSelector();
        } else if (normalized.contains('open settings') ||
            normalized == 'settings') {
          await _tts.speak("Opening settings.");
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsPage()),
          );
        } else {
          await _tts.speak("Sorry, I didn't understand that command.");
        }
      },
      onComplete: () {
        if (mounted) {
          setState(() => _isListening = false);
          _micController.stop();
        }
      },
    );
  }

  Future<void> _stopListening() async {
    setState(() => _isListening = false);
    _micController.stop();
    await _voiceController.stopListening();
  }

  @override
  void dispose() {
    _tts.stop();
    _voiceController.dispose();
    _micController.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------
  // UI
  // -----------------------------------------------------------------
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
          padding: const EdgeInsets.only(bottom: 110),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _openCreateTimerScreen,
                  child: const RealisticClockWidget(),
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

      // ----------------------- BOTTOM BAR WITH ANIMATED MIC ------------------------
      bottomSheet: SafeArea(
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
                } else if (index == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoutinesPage(routines: _routines),
                    ),
                  );
                } else if (index == 4) {
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
                color:
                _isListening ? Colors.redAccent : const Color(0xFF007BFF),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🔹 Animated glowing mic icon
                    AnimatedBuilder(
                      animation: _micController,
                      builder: (_, child) {
                        final rotation = Tween(begin: 0.0, end: 2 * math.pi)
                            .evaluate(_micController);
                        return Transform.rotate(
                          angle: rotation,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const SweepGradient(
                                colors: [
                                  Color(0xFFFFBF48),
                                  Color(0xFFBE4A1D),
                                  Color(0xFFFFBF47),
                                  Color(0xFFBE4A1D),
                                  Color(0xFFFFBF48),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orangeAccent.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                _isListening ? Icons.mic : Icons.mic_off,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        );
                      },
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
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Realistic Dark-Metallic Clock
// -----------------------------------------------------------------------------
class RealisticClockWidget extends StatefulWidget {
  const RealisticClockWidget({super.key});

  @override
  State<RealisticClockWidget> createState() => _RealisticClockWidgetState();
}

class _RealisticClockWidgetState extends State<RealisticClockWidget>
    with TickerProviderStateMixin {
  late final AnimationController _secondController;
  late final AnimationController _minuteController;
  late final AnimationController _hourController;

  @override
  void initState() {
    super.initState();
    _secondController =
    AnimationController(vsync: this, duration: const Duration(seconds: 60))
      ..repeat();
    _minuteController =
    AnimationController(vsync: this, duration: const Duration(hours: 1))
      ..repeat();
    _hourController =
    AnimationController(vsync: this, duration: const Duration(hours: 12))
      ..repeat();
  }

  @override
  void dispose() {
    _secondController.dispose();
    _minuteController.dispose();
    _hourController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 250,
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFF333333), Color(0xFF111111)],
          center: Alignment.center,
          radius: 0.8,
        ),
        border: Border.all(color: Color(0xFFCEC5C5), width: 10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient:
              RadialGradient(colors: [Color(0xFF666666), Color(0xFF333333)]),
            ),
          ),
          AnimatedBuilder(
            animation: _hourController,
            builder: (_, child) =>
                Transform.rotate(angle: _hourController.value * 2 * math.pi, child: child),
            child: Container(
              width: 8,
              height: 70,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1D6981), Color(0xFF444444)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _minuteController,
            builder: (_, child) =>
                Transform.rotate(angle: _minuteController.value * 2 * math.pi, child: child),
            child: Container(
              width: 6,
              height: 90,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFBBBBBB), Color(0xFF666666)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.all(Radius.circular(3)),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _secondController,
            builder: (_, child) =>
                Transform.rotate(angle: _secondController.value * 2 * math.pi, child: child),
            child: Container(width: 3, height: 110, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TimerCard
// -----------------------------------------------------------------------------
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
