import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
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
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  final FlutterTts _tts = FlutterTts();

  List<TimerData> _timers = [];
  static const String _timersKey = 'saved_timers_list';

  @override
  void initState() {
    super.initState();
    _loadTimers();
    _initSpeech();
  }

  // Load timers from SharedPreferences
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

  // Save the current list of timers to SharedPreferences
  Future<void> _saveTimers() async {
    final prefs = await SharedPreferences.getInstance();
    final String timersString = jsonEncode(_timers.map((timer) => timer.toJson()).toList());
    await prefs.setString(_timersKey, timersString);
  }

  // Add or update a timer in the list
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

  // Delete a timer
  void _deleteTimer(String timerId) {
    setState(() {
      _timers.removeWhere((timer) => timer.id == timerId);
    });
    _saveTimers();
  }

  // Navigate to create screen for a NEW timer
  void _openCreateTimerScreen() async {
    final result = await Navigator.push<TimerData>(
      context,
      MaterialPageRoute(builder: (_) => const CreateTimerScreen()),
    );
    if (result != null) {
      _addOrUpdateTimer(result);
    }
  }

  // Navigate to create screen to EDIT an existing timer
  void _editTimer(TimerData timerToEdit) async {
    final result = await Navigator.push<TimerData>(
      context,
      MaterialPageRoute(builder: (_) => CreateTimerScreen(existingTimer: timerToEdit)),
    );
    if (result != null) {
      _addOrUpdateTimer(result);
    }
  }

  // Navigate to the countdown screen to PLAY a timer
  void _playTimer(TimerData timerToPlay) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CountdownScreen(timerData: timerToPlay),
      ),
    );
  }

  void _initSpeech() async {
    try {
      bool available = await _speechToText.initialize(
        onStatus: (status) {
          print("🎙️ Speech status: $status");
          if (status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          print("⚠️ Speech error: $error");
          setState(() => _isListening = false);
        },
      );

      if (available) {
        print("✅ Speech recognition initialized");
      } else {
        print("❌ Speech recognition not available");
      }
    } catch (e) {
      print("❌ Error: $e");
    }
  }

  void _startListening() async {
    if (_isListening) return;
    try {
      setState(() => _isListening = true);

      // Provide audio feedback
      await _speak("Listening");

      await _speechToText.listen(
        onResult: _onSpeechResult,
        localeId: 'en_US',
        listenMode: ListenMode.confirmation,
        partialResults: true,
      );
    } catch (e) {
      print("Error starting listening: $e");
      setState(() => _isListening = false);
    }
  }

  void _stopListening() async {
    try {
      await _speechToText.stop();
      setState(() => _isListening = false);
      await _speak("Stopped listening");
    } catch (e) {
      print("Error stopping listening: $e");
    }
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

  void _onSpeechResult(SpeechRecognitionResult result) {
    String recognizedText = result.recognizedWords.toLowerCase();
    print("🎤 Recognized: $recognizedText");

    // FIXED: Only act on final results to prevent multiple triggers
    if (!result.finalResult) return;

    // Start stopwatch command - directly open Normal Mode with auto-start
    // Voice commands bypass the mode selector for quick access
    if (recognizedText.contains("start") &&
        (recognizedText.contains("stopwatch") || recognizedText.contains("stop watch"))) {
      _stopListening(); // Turn off mic FIRST
      _speak("Starting stopwatch");
      _openNormalStopwatch(autoStart: true);
      return;
    }

    if (recognizedText.contains("hey tick talk") &&
        (recognizedText.contains("start the stopwatch") ||
            recognizedText.contains("start stopwatch"))) {
      _stopListening(); // Turn off mic FIRST
      _speak("Starting stopwatch");
      _openNormalStopwatch(autoStart: true);
      return;
    }

    if (recognizedText.contains("rerun tutorial") ||
        recognizedText.contains("korean tutorial") ||
        recognizedText.contains("show tutorial again")) {
      _rerunTutorial();
      _stopListening();
    }
  }

  @override
  void dispose() {
    _speechToText.cancel();
    _tts.stop();
    super.dispose();
  }

  // Open Normal Mode stopwatch directly (used for voice commands with auto-start)
  void _openNormalStopwatch({bool autoStart = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StopwatchNormalMode(autoStart: autoStart)),
    );
  }

  // Open the stopwatch mode selector (used for manual navigation)
  void _openStopwatchSelector() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StopwatchModeSelector()),
    );
  }

  void _rerunTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcome', false);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Command recognized! Tutorial will show on next app start.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'TickTalk',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ====== LARGE ACCESSIBLE MIC BUTTON ======
              Center(
                child: Semantics(
                  label: _isListening
                      ? 'Voice control is active. Double tap to stop listening'
                      : 'Voice control button. Double tap to start listening for commands like start stopwatch',
                  button: true,
                  hint: 'Say start stopwatch or rerun tutorial',
                  enabled: true,
                  child: GestureDetector(
                    onTap: _isListening ? _stopListening : _startListening,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening ? Colors.red : const Color(0xFF007BFF),
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening ? Colors.red : const Color(0xFF007BFF))
                                .withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 8,
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  _isListening ? '🎤 LISTENING' : 'TAP TO SPEAK',
                  style: TextStyle(
                    color: _isListening ? Colors.red : Colors.black87,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: (_isListening ? Colors.red : const Color(0xFF007BFF)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: (_isListening ? Colors.red : const Color(0xFF007BFF)).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    _isListening
                        ? 'I\'m listening for your command...'
                        : 'Say: "start stopwatch"',
                    style: TextStyle(
                      color: _isListening ? Colors.red : const Color(0xFF007BFF),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Create New Timer Button
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

              // Pre-defined Routines section
              const Text('Pre-defined Timer Routines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: const [
                    RoutineCard(
                      title: 'Exercise Sets',
                      description: 'Intervals for strength & cardio training.',
                      icon: Icons.fitness_center,
                    ),
                    RoutineCard(
                      title: 'Pomodoro Focus',
                      description: '25-min work, 5-min break cycles.',
                      icon: Icons.timer_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Your Timers section
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color(0xFF007BFF),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) {
            _openCreateTimerScreen();
          } else if (index == 4) {
            // FIXED: Now opens the mode selector instead of going directly to Normal Mode
            _openStopwatchSelector();
          }
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
}

//---------------------------------------------
// Routine Card
//---------------------------------------------
class RoutineCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const RoutineCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {},
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

//---------------------------------------------
// Timer Card
//---------------------------------------------
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
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