import 'package:flutter/material.dart';

class TimerModeSelector extends StatelessWidget {
  // Callback to tell MainPage what the user picked
  final void Function(String mode)? onSelectMode;

  const TimerModeSelector({
    super.key,
    this.onSelectMode,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF007BFF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Select Timer Type"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            const Text(
              "Choose your timer mode",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // --- NORMAL TIMER BUTTON ---
            _buildModeButton(
              context,
              title: "Normal Timer",
              subtitle: "A simple countdown timer for one session",
              icon: Icons.timer_outlined,
              color: primaryBlue,
              onTap: () {
                // Tell MainPage: user chose normal timer
                if (onSelectMode != null) {
                  onSelectMode!("normal");
                }
              },
            ),

            const SizedBox(height: 20),

            // --- INTERVAL TIMER BUTTON ---
            _buildModeButton(
              context,
              title: "Interval Timer",
              subtitle: "Set work/break intervals and multiple sets",
              icon: Icons.repeat,
              color: Colors.green,
              onTap: () {
                // Tell MainPage: user chose interval timer
                if (onSelectMode != null) {
                  onSelectMode!("interval");
                }
              },
            ),

            const Spacer(),

            // --- Cancel button ---
            TextButton(
              onPressed: () {
                if (onSelectMode != null) {
                  onSelectMode!("cancel");
                } else {
                  Navigator.pop(context);
                }
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              radius: 28,
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}
