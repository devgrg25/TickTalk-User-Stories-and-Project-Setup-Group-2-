import 'package:flutter/material.dart';
import '../../logic/routines/routines.dart'; // Imports the logic class
import '../../logic/models/timer_model.dart'; // We also need this for the typedefs in routines.dart

class RoutinesPage extends StatelessWidget {
  final PredefinedRoutines routines;

  const RoutinesPage({super.key, required this.routines});

  // UI Theme Colors (matching your app)
  static const Color primaryBlue = Color(0xFF007BFF);
  static const Color cardBackground = Color(0xFFF9FAFB);
  static const Color cardBorder = Color(0xFFE5E7EB); // grey.shade300
  static const Color textColor = Colors.black;
  static const Color subtextColor = Colors.black54;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Routines', style: TextStyle(color: textColor)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Interval Timers Section ---
          const Text(
            'Interval Routines',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildRoutineListItem(
            title: 'Pomodoro Focus',
            description: '25-min work, 5-min break cycles.',
            icon: Icons.timer_outlined,
            onPressed: routines.startPomodoroTimer,
          ),
          _buildRoutineListItem(
            title: 'Exercise Sets',
            description: 'Intervals for strength & cardio training.',
            icon: Icons.fitness_center,
            onPressed: routines.startExerciseTimer,
          ),
          _buildRoutineListItem(
            title: 'The 20-20-20 Rule',
            description: 'Every 20 mins, look at 20 ft away for 20 secs.',
            icon: Icons.remove_red_eye_outlined,
            onPressed: routines.start202020Rule,
          ),

          const SizedBox(height: 24),

          // --- Accessibility Timers Section ---
          const Text(
            'Accessibility Routines',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildRoutineListItem(
            title: 'Mindfulness Minute',
            description: 'A 1-minute guided breathing exercise.',
            icon: Icons.spa_outlined,
            onPressed: routines.startMindfulnessMinute,
          ),
          _buildRoutineListItem(
            title: 'Simple Laundry Cycle',
            description: '2 min load + 3 min transfer timer.',
            icon: Icons.local_laundry_service_outlined,
            onPressed: routines.startSimpleLaundryCycle,
          ),

          const SizedBox(height: 24),

          // --- Sequential Timers (Now Enabled) ---
          const Text(
            'Sequential Routines', // <-- REMOVED "(Coming Soon)"
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildRoutineListItem(
            title: 'Morning Independence',
            description: '3 min wash, 2 min dress, 5 min eat cycle.',
            icon: Icons.wb_sunny_outlined,
            onPressed: routines.startMorningIndependence, // <-- ENABLED
          ),
          _buildRoutineListItem(
            title: 'Recipe Prep Guide',
            description: 'Sequential timers for cooking steps.',
            icon: Icons.restaurant_menu,
            onPressed: routines.startRecipePrep, // <-- ENABLED
          ),
        ],
      ),
    );
  }

  /// A helper widget to create a consistent list item for each routine.
  /// This is styled to match the TimerCard from homepage.dart.
  Widget _buildRoutineListItem({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      color: cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          leading: Icon(icon, color: primaryBlue, size: 40),
          title: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            description,
            style: const TextStyle(fontSize: 13, color: subtextColor),
          ),
          trailing: ElevatedButton(
            onPressed: onPressed, // Button is enabled/disabled based on this
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              // Make the button look disabled if onPressed is null
              disabledBackgroundColor: Colors.grey.shade300,
            ),
            child: const Text('Start'),
          ),
        ),
      ),
    );
  }
}