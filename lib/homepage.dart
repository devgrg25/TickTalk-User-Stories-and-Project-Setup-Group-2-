import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'settings_page.dart';
import 'stopwatcht2us2.dart';
import 'create_timer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      bool available = await _speechToText.initialize(
        onStatus: (status) {
          print("🎙️ Speech status: $status");
          // Auto-restart listening when it stops
          if (status == 'notListening' && _isListening) {
            Future.delayed(const Duration(milliseconds: 300), _startListening);
          }
        },
        onError: (error) {
          print("⚠️ Speech error: $error");
          // Restart on error
          if (_isListening) {
            Future.delayed(const Duration(milliseconds: 500), _startListening);
          }
        },
      );

      if (available) {
        print("✅ Speech recognition initialized");
        _startListening(); // Auto-start listening
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
      await _speechToText.listen(
        onResult: _onSpeechResult,
        localeId: 'en_US',
      );
    } catch (e) {
      print("Error starting listening: $e");
      setState(() => _isListening = false);
      // Retry after delay
      Future.delayed(const Duration(seconds: 1), _startListening);
    }
  }

  void _stopListening() async {
    try {
      await _speechToText.stop();
      setState(() => _isListening = false);
    } catch (e) {
      print("Error stopping listening: $e");
    }
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5); // Reduced from 0.9 to 0.5 for slower speech
      await _tts.speak(text);
    } catch (e) {
      print("TTS error: $e");
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    String recognizedText = result.recognizedWords.toLowerCase();
    print("🎤 Recognized: $recognizedText");

    // Stopwatch command
    if (recognizedText.contains("hey tick talk") &&
        recognizedText.contains("start the stopwatch") ||
        recognizedText.contains("start stopwatch") ||
        recognizedText.contains("start the stopwatch")) {
      _speak("Starting stopwatch.");
      _openStopwatch();
    }

    // Rerun tutorial command
    if (recognizedText.contains("rerun tutorial")) {
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

  void _openStopwatch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StopwatchT2US2()),
    );
  }

  void _openCreateTimerScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateTimerScreen()),
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
        leading: IconButton(
          icon: Icon(
            _isListening ? Icons.mic : Icons.mic_off,
            color: _isListening ? Colors.red : Colors.black,
          ),
          onPressed: _isListening ? _stopListening : _startListening,
          tooltip: _isListening ? 'Stop listening' : 'Tap to speak',
        ),
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
            icon: const Icon(Icons.timer, color: Colors.black),
            onPressed: _openStopwatch,
            tooltip: 'Open Stopwatch',
          ),
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
              // Create New Timer Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 24),
                  label: const Text(
                    'Create New Timer',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007BFF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _openCreateTimerScreen,
                ),
              ),
              const SizedBox(height: 24),

              // Stopwatch Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF007BFF),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          'Quick Stopwatch',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Start timing instantly',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _openStopwatch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF007BFF),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Open Stopwatch',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Pre-defined Timer Routines
              const Text(
                'Pre-defined Timer Routines',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
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

              // Your Timers
              const Text(
                'Your Timers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              const TimerCard(
                title: 'Morning Workout',
                status: 'Active',
                feedback: 'Audio + Haptic',
                color: Color(0xFF007BFF),
              ),
              const TimerCard(
                title: 'Cooking Timer',
                status: 'Paused',
                feedback: 'Audio Only',
                color: Colors.grey,
              ),
              const TimerCard(
                title: 'Meditation',
                status: 'Completed',
                feedback: 'Haptic Only',
                color: Colors.green,
              ),
              const TimerCard(
                title: 'Study Break',
                status: 'Paused',
                feedback: 'Audio + Haptic',
                color: Colors.grey,
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
          if (index == 1) { // 'Create' is at index 1
            _openCreateTimerScreen();
          } else if (index == 4) {
            _openStopwatch();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Routines'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined), label: 'Activity'),
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

  const TimerCard({
    super.key,
    required this.title,
    required this.status,
    required this.feedback,
    required this.color,
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
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          Text(
            'Feedback: $feedback',
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.play_arrow, color: Colors.black54),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined, color: Colors.black54),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.delete_outline, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}