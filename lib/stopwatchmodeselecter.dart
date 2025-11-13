import 'package:flutter/material.dart';
import 'stopwatch_normal_mode.dart';
import 'stopwatch_player_mode.dart';

class StopwatchModeSelector extends StatelessWidget {
  const StopwatchModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Stopwatch', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.timer_outlined,
              size: 80,
              color: Color(0xFF007BFF),
            ),
            const SizedBox(height: 24),
            const Text(
              'Choose Stopwatch Mode',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select how you want to use the stopwatch',
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Normal Mode Button
            _buildModeCard(
              context,
              title: 'Normal Mode',
              description: 'Single stopwatch with voice control',
              icon: Icons.timer,
              color: const Color(0xFF007BFF),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StopwatchNormalMode(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Player Mode Button
            _buildModeCard(
              context,
              title: 'Player Mode',
              description: 'Track up to 6 players simultaneously',
              icon: Icons.groups,
              color: Colors.green,
              onTap: () {
                _showPlayerCountDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard(
      BuildContext context, {
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
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

  void _showPlayerCountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Number of Players'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(6, (index) {
            final playerCount = index + 1;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF007BFF),
                child: Text(
                  '$playerCount',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text('$playerCount Player${playerCount > 1 ? 's' : ''}'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StopwatchPlayerMode(playerCount: playerCount),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}