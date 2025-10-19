import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'settings_page.dart';
import 'stopwatcht2us2.dart';
import 'create_timer_screen.dart';
import 'dart:convert';
import 'timer_model.dart';
import 'countdown_screen.dart';

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
        // This is an update
        _timers[index] = timer;
      } else {
        // This is a new timer
        _timers.add(timer);
      }
    });
    _saveTimers(); // Persist changes
  }

  // Delete a timer
  void _deleteTimer(String timerId) {
    setState(() {
      _timers.removeWhere((timer) => timer.id == timerId);
    });
    _saveTimers(); // Persist changes
  }

  // --- NAVIGATION METHODS ---

  // Navigate to create screen for a NEW timer
  void _openCreateTimerScreen() async {
    final result = await Navigator.push<TimerData>(
      context,
      MaterialPageRoute(builder: (_) => const CreateTimerScreen()),
    );
    // If a new timer was created and returned, add it to our list
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
    // If the timer was edited and returned, update it in our list
    if (result != null) {
      _addOrUpdateTimer(result);
    }
  }

  // Navigate to the countdown screen to PLAY a timer
  void _playTimer(TimerData timerToPlay) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Pass the whole timer object directly.
        // The CountdownScreen will handle the sets internally.
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
            // Update the UI to show the mic is off.
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          print("⚠️ Speech error: $error");
          // Also ensure the mic icon is off if an error occurs.
          setState(() => _isListening = false);
        },
      );

      if (available) {
        print("✅ Speech recognition initialized");
        _startListening();
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
      await _tts.setSpeechRate(0.5); // Reduced for slower speec
      await _tts.setSpeechRate(0.5);
main
      await _tts.speak(text);
    } catch (e) {
      print("TTS error: $e");
    }
  }

  // Helper function for quick feedback
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

  // --- TIMER ROUTINE IMPLEMENTATIONS ---

  // Mindfulness Minute
  void _startMindfulnessMinute() async {
    _stopListening();
    _speak("Starting Mindfulness Minute. Find a comfortable position.");
    _showSnackbar('Phase 1: 30 seconds of focused breathing.');
    await Future.delayed(const Duration(seconds: 5));
    _speak("Time's up. Phase two: Now, for fifteen seconds, notice any sounds around you.");
    _showSnackbar('Phase 2: 15 seconds of silence/listening.');
    await Future.delayed(const Duration(seconds: 5));
    _speak("Mindfulness Minute complete. Return to your daily activity.");
    _showSnackbar('Mindfulness Minute complete.');
    _startListening();
  }

  // Simple Laundry Cycle
  void _startSimpleLaundryCycle() async {
    _stopListening();
    _speak("Starting Simple Laundry Cycle. Time to load the clothes.");
    _showSnackbar('Phase 1: 2 minutes to load clothes and start the wash.');
    await Future.delayed(const Duration(seconds: 5));
    _speak("Phase two: Wash cycle complete. You have three minutes to transfer clothes to the dryer.");
    _showSnackbar('Phase 2: 3 minutes to transfer to dryer.');
    await Future.delayed(const Duration(seconds: 5));
    _speak("Transfer time is over. Drying cycle complete. Time to sort the laundry for storage!");
    _showSnackbar('Laundry cycle complete.');
    _startListening();
  }

  // 20-20-20 Rule (Placeholder for full implementation)
  void _start202020Rule() async {
    _stopListening();
    _speak("Starting 20-20-20 rule. You will be reminded every 20 minutes to take a break.");
    // In a real app, this would set a repeating timer.
    _showSnackbar('20-20-20 Rule started! Reminder in 20 minutes.');
    await Future.delayed(const Duration(seconds: 5));
    _speak("20-20-20 break now. Turn away from your focus area and rest your eyes for 20 seconds.");
    _showSnackbar('20-second break: Turn away and rest.');
    await Future.delayed(const Duration(seconds: 5));
    _speak("Break over. Return to work. Next reminder in 20 minutes.");
    _startListening();
  }

  // --- END TIMER ROUTINE IMPLEMENTATIONS ---

  void _onSpeechResult(SpeechRecognitionResult result) {
    String recognizedText = result.recognizedWords.toLowerCase();
    print("🎤 Recognized: $recognizedText");


    // Stopwatch command (Voice command remains active)

 main
    if (recognizedText.contains("hey tick talk") &&
        (recognizedText.contains("start the stopwatch") ||
            recognizedText.contains("start stopwatch") ||
            recognizedText.contains("open stopwatch"))) {
      _speak("Starting stopwatch.");
      _openStopwatch();
    }


    // NEW STT COMMANDS
    if (recognizedText.contains("hey tick talk") &&
        recognizedText.contains("start mindfulness")) {
      _startMindfulnessMinute();
    }

    if (recognizedText.contains("hey tick talk") &&
        recognizedText.contains("start laundry")) {
      _startSimpleLaundryCycle();
    }

    if (recognizedText.contains("hey tick talk") &&
        recognizedText.contains("start 20 20 20")) {
      _start202020Rule();
    }

    // Rerun tutorial command
    if (recognizedText.contains("rerun tutorial")) {

    if (recognizedText.contains("rerun tutorial") ||
        recognizedText.contains("korean tutorial") ||
        recognizedText.contains("show tutorial again")) {
 main
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

          // REMOVED: Stopwatch icon from the AppBar
          /*
          IconButton(
            icon: const Icon(Icons.timer, color: Colors.black),
            onPressed: _openStopwatch,
            tooltip: 'Open Stopwatch',
          ),
          */

          // Stopwatch icon removed here ✅
 main
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
              // Create New Timer Button (functionality is now updated)
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

              // REMOVED: The "Quick Stopwatch" Feature Block
              /*
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
                    const Row(
                      children: [
                        Icon(Icons.timer, color: Colors.white, size: 28),
                        SizedBox(width: 12),
                        Text(
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
              */

              // If the Stopwatch section is removed, the spacing needs adjusting.
              // We'll keep the separation as it was for now, but a single SizedBox(height: 24) is cleaner.

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
                  children: [
                    // Existing Routines
                    RoutineCard(
                      title: 'Exercise Sets',
                      description: 'Intervals for strength & cardio training.',
                      icon: Icons.fitness_center,
                      onPressed: () {},
                    ),
                    RoutineCard(
                      title: 'Pomodoro Focus',
                      description: '25-min work, 5-min break cycles.',
                      icon: Icons.timer_outlined,
                      onPressed: () {},
                    ),

                    // --- NEW ACCESSIBILITY ROUTINES ---

                    // Mindfulness Minute (Functional)
                    RoutineCard(
                      title: 'Mindfulness Minute',
                      description: 'Structured meditation with spoken intervals.',
                      icon: Icons.spa_outlined,
                      onPressed: _startMindfulnessMinute,
                    ),
                    // Simple Laundry Cycle (Functional)
                    RoutineCard(
                      title: 'Simple Laundry Cycle',
                      description: 'Timed steps for washing, drying, and sorting items for storage.',
                      icon: Icons.local_laundry_service_outlined,
                      onPressed: _startSimpleLaundryCycle,
                    ),
                    // Morning Independence (Placeholder)
                    RoutineCard(
                      title: 'Morning Independence',
                      description: '3 min wash, 2 min dress, 5 min eat cycle.',
                      icon: Icons.wb_sunny_outlined,
                      onPressed: () {},
                    ),
                    // Recipe Prep Guide (Placeholder)
                    RoutineCard(
                      title: 'Recipe Prep Guide',
                      description: 'Sequential timers for common cooking steps.',
                      icon: Icons.restaurant_menu,
                      onPressed: () {},
                    ),
                    // The 20-20-20 Rule (UPDATED DESCRIPTION & LINKED)
                    RoutineCard(
                      title: 'The 20-20-20 Rule',
                      description: 'Audible guide for muscle relaxation: turn away from your focus every 20 mins for a 20-second break.',
                      icon: Icons.remove_red_eye_outlined,
                      onPressed: _start202020Rule,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- DYNAMIC "YOUR TIMERS" SECTION ---
              const Text('Your Timers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
              const SizedBox(height: 12),

              // If there are no timers, show a message. Otherwise, build the list.
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
                    status: 'Ready', // Status can be enhanced later
                    feedback: 'Audio + Haptic', // This can also be saved in TimerData
                    color: const Color(0xFF007BFF),
                    // --- WIRE UP THE BUTTONS ---
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
      // RETAINED: Only the Bottom Navigation Bar Stopwatch icon remains
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color(0xFF007BFF),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) {
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
// Routine Card (Fixed size implemented)
//---------------------------------------------
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
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
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

//---------------------------------------------
// Timer Card (Unchanged)
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
          Text('Feedback: $feedback', style: const TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(onPressed: onPlay, icon: const Icon(Icons.play_arrow, color: Colors.black54)),
              IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, color: Colors.black54)),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Colors.redAccent)), // Made delete icon red for clarity
            ],
          ),
        ],
      ),
    );
  }
}
