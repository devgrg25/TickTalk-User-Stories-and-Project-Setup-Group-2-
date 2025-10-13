import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✨ ADDED: For SharedPreferences
import 'package:speech_to_text/speech_to_text.dart';         // ✨ ADDED: For voice commands
import 'package:speech_to_text/speech_recognition_result.dart';
import 'settings_page.dart';

// ✨ CHANGED: Converted to a StatefulWidget to manage listening state
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ✨ ADDED: State variables for speech recognition
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;

  // ✨ ADDED: Initialize speech recognition in initState
  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    await _speechToText.initialize();
  }

  // ✨ ADDED: Functions to start and stop listening
  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  // ✨ ADDED: Callback for when speech is recognized
  void _onSpeechResult(SpeechRecognitionResult result) {
    String recognizedText = result.recognizedWords.toLowerCase();

    // Check for the specific voice command
    if (recognizedText.contains("rerun tutorial")) {
      _rerunTutorial();
      _stopListening(); // Stop listening after command is found
    }
  }

  // ✨ ADDED: Logic to reset the tutorial flag and show a confirmation
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
        // ✨ ADDED: `leading` property for the voice button on the left
        leading: IconButton(
          icon: Icon(
            _isListening ? Icons.mic : Icons.mic_off , // Dynamic icon
            color: Colors.black,
          ),
          onPressed: _isListening ? _stopListening : _startListening, // Toggle listening
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
      // The rest of your body and bottomNavigationBar remains the same...
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
                  onPressed: () => Navigator.pushNamed(context, '/createTimer'),
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
                      description:
                      'Intervals for strength & cardio training.',
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Routines'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined), label: 'Activity'),
        ],
      ),
    );
  }
}

//---------------------------------------------
// Routine Card (auto-sizing, no overflow)
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
        mainAxisSize: MainAxisSize.min, // 👈 key line (fix overflow)
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
// Timer Card (unchanged)
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
