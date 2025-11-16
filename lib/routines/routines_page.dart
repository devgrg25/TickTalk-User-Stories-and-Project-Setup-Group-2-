import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'routines.dart';
import '../timer_models/routine_timer_model.dart';
import 'create_routine_page.dart';

class RoutinesPage extends StatefulWidget {
  final PredefinedRoutines routines;

  const RoutinesPage({super.key, required this.routines});

  @override
  State<RoutinesPage> createState() => RoutinesPageState();
}

// Class name is public (no underscore) to allow access via GlobalKey
class RoutinesPageState extends State<RoutinesPage> {
  // --- Data ---
  final List<TimerDataV> _customRoutines = [];

  // --- Feedback (Text-to-Speech) ---
  final FlutterTts _tts = FlutterTts();

  // --- Theme Colors ---
  static const Color primaryBlue = Color(0xFF007BFF);
  static const Color cardBackground = Color(0xFFF9FAFB);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color textColor = Colors.black;
  static const Color subtextColor = Colors.black54;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint("TTS Error: $e");
    }
  }

  // --- PUBLIC VOICE COMMAND HANDLER ---
  // Call this method from your Global Button in MainPage
  void handleVoiceCommand(String command) {
    final lower = command.toLowerCase().trim();
    debugPrint("RoutinesPage processing command: $lower");

    // 1. CREATE ROUTINE
    if (lower.contains('create') || lower.contains('new routine')) {
      _speak("Opening routine creator.");
      _navigateToCreateRoutine();
      return;
    }

    // 2. LIST ROUTINES
    if (lower.contains('list') || lower.contains('read') || lower.contains('show routines')) {
      _speakListRoutines();
      return;
    }

    // 3. START ROUTINE
    if (lower.contains('start') || lower.contains('play') || lower.contains('begin')) {
      // Remove the trigger word to isolate the routine name
      String target = lower.replaceAll('start', '')
          .replaceAll('play', '')
          .replaceAll('begin', '')
          .trim();
      _attemptStartRoutine(target);
      return;
    }

    // Fallback if command not understood
    _speak("I didn't catch that. Try saying 'Create routine', 'List routines', or 'Start' followed by a name.");
  }

  void _speakListRoutines() {
    if (_customRoutines.isEmpty) {
      _speak("You have no custom routines. Predefined routines include Pomodoro, Exercise, and Mindfulness.");
    } else {
      String names = _customRoutines.map((e) => e.name).join(", ");
      _speak("You have ${_customRoutines.length} custom routines: $names.");
    }
  }

  void _attemptStartRoutine(String targetName) {
    if (targetName.isEmpty) {
      _speak("Please say the name of the routine to start.");
      return;
    }

    // A. Check Custom Routines (Fuzzy Match)
    final customMatch = _customRoutines.firstWhere(
          (r) => r.name.toLowerCase().contains(targetName),
      orElse: () => TimerDataV(id: 'null', name: 'null', steps: []),
    );

    if (customMatch.name != 'null') {
      _speak("Starting ${customMatch.name}");
      widget.routines.playTimer(customMatch);
      return;
    }

    // B. Check Predefined Routines (Keyword Mapping)
    if (targetName.contains('pomodoro')) {
      _speak("Starting Pomodoro Focus.");
      widget.routines.startPomodoroTimer();
    } else if (targetName.contains('exercise') || targetName.contains('workout')) {
      _speak("Starting Exercise Sets.");
      widget.routines.startExerciseTimer();
    } else if (targetName.contains('eye') || targetName.contains('20')) {
      _speak("Starting 20 20 20 rule.");
      widget.routines.start202020Rule();
    } else if (targetName.contains('mindfulness') || targetName.contains('breath')) {
      _speak("Starting Mindfulness Minute.");
      widget.routines.startMindfulnessMinute();
    } else if (targetName.contains('laundry')) {
      _speak("Starting Laundry Cycle.");
      widget.routines.startSimpleLaundryCycle();
    } else if (targetName.contains('morning')) {
      _speak("Starting Morning Independence.");
      widget.routines.startMorningIndependence();
    } else if (targetName.contains('recipe') || targetName.contains('cook')) {
      _speak("Starting Recipe Prep.");
      widget.routines.startRecipePrep();
    } else {
      _speak("I couldn't find a routine named $targetName.");
    }
  }

  // --- Navigation ---
  void _navigateToCreateRoutine() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateRoutinePage()),
    );

    if (result != null && result is TimerDataV) {
      setState(() {
        _customRoutines.add(result);
      });
      _speak("Routine ${result.name} created successfully.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Routines', style: TextStyle(color: textColor)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [

          // --- 1. CREATE BUTTON (Top Center) ---
          Center(
            child: ElevatedButton.icon(
              onPressed: _navigateToCreateRoutine,
              icon: const Icon(Icons.add),
              label: const Text(
                'Create New Routine',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // --- 2. YOUR ROUTINES SECTION ---
          if (_customRoutines.isNotEmpty) ...[
            const Text(
              'Your Routines',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            ..._customRoutines.map((timer) => _buildRoutineListItem(
              title: timer.name,
              description: '${timer.totalSteps} steps • ${timer.totalTime} mins',
              icon: Icons.star,
              onPressed: () {
                widget.routines.stopListening();
                widget.routines.speak("Starting ${timer.name}");
                widget.routines.playTimer(timer);
              },
              onDelete: () {
                setState(() {
                  _customRoutines.remove(timer);
                });
                _speak("Deleted ${timer.name}");
              },
            )),
            const SizedBox(height: 24),
            const Divider(thickness: 1),
            const SizedBox(height: 24),
          ],

          // --- 3. PREDEFINED ROUTINES SECTION ---
          const Text(
            'Predefined Routines',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          _buildRoutineListItem(
            title: 'Pomodoro Focus',
            description: '25-min work, 5-min break cycles.',
            icon: Icons.timer_outlined,
            onPressed: widget.routines.startPomodoroTimer,
          ),
          _buildRoutineListItem(
            title: 'Exercise Sets',
            description: 'Intervals for strength & cardio training.',
            icon: Icons.fitness_center,
            onPressed: widget.routines.startExerciseTimer,
          ),
          _buildRoutineListItem(
            title: 'The 20-20-20 Rule',
            description: 'Eye strain relief: 20 mins work, 20 sec break.',
            icon: Icons.remove_red_eye_outlined,
            onPressed: widget.routines.start202020Rule,
          ),
          _buildRoutineListItem(
            title: 'Mindfulness Minute',
            description: 'A 1-minute guided breathing exercise.',
            icon: Icons.spa_outlined,
            onPressed: widget.routines.startMindfulnessMinute,
          ),
          _buildRoutineListItem(
            title: 'Simple Laundry Cycle',
            description: '2 min load + 3 min transfer timer.',
            icon: Icons.local_laundry_service_outlined,
            onPressed: widget.routines.startSimpleLaundryCycle,
          ),
          _buildRoutineListItem(
            title: 'Morning Independence',
            description: '3 min wash, 2 min dress, 5 min eat cycle.',
            icon: Icons.wb_sunny_outlined,
            onPressed: widget.routines.startMorningIndependence,
          ),
          _buildRoutineListItem(
            title: 'Recipe Prep Guide',
            description: 'Sequential timers for cooking steps.',
            icon: Icons.restaurant_menu,
            onPressed: widget.routines.startRecipePrep,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Helper widget for consistent list items
  Widget _buildRoutineListItem({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback? onPressed,
    VoidCallback? onDelete,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      color: cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          leading: Icon(icon, color: primaryBlue, size: 32),
          title: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            description,
            style: const TextStyle(fontSize: 13, color: subtextColor),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Delete button (only for custom routines)
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Delete Routine',
                ),
              const SizedBox(width: 4),
              // Start Button
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('Start'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}