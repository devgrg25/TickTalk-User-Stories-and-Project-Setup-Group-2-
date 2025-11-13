import 'package:flutter/material.dart';

class StopwatchModeSelector extends StatelessWidget {
  final void Function(String mode)? onSelectMode;

  const StopwatchModeSelector({super.key, this.onSelectMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_outlined,
                size: 80, color: Color(0xFF007BFF)),
            const SizedBox(height: 24),
            const Text(
              'Choose Stopwatch Mode',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select how you want to use the stopwatch',
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            _buildModeCard(
              title: 'Normal Mode',
              description: 'Single stopwatch mode',
              icon: Icons.timer,
              color: const Color(0xFF007BFF),
              onTap: () => onSelectMode?.call('normal'),
            ),
            const SizedBox(height: 16),

            _buildModeCard(
              title: 'Player Mode',
              description: 'Track up to 6 players simultaneously',
              icon: Icons.groups,
              color: Colors.green,
              onTap: () => onSelectMode?.call('player'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
