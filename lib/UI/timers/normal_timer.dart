import 'package:flutter/material.dart';
import '../../logic/models/timer_normal_model.dart';
import 'countdown_simple_screen.dart';

class NormalTimerScreen extends StatefulWidget {
  const NormalTimerScreen({super.key});

  @override
  State<NormalTimerScreen> createState() => _NormalTimerScreenState();
}

class _NormalTimerScreenState extends State<NormalTimerScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController();
  final TextEditingController _secondsController = TextEditingController();

  void _startTimer() {
    final name = _nameController.text.trim().isEmpty
        ? "Custom Timer"
        : _nameController.text.trim();

    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final seconds = int.tryParse(_secondsController.text) ?? 0;
    final totalSeconds = (minutes * 60) + seconds;

    if (totalSeconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid duration!")),
      );
      return;
    }

    final timer = TimerNormal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      totalTime: totalSeconds,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CountdownSimpleScreen(
          name: timer.name,
          totalSeconds: timer.totalTime,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF007BFF);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Normal Timer"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Timer Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minutesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Minutes",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _secondsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Seconds",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startTimer,
              icon: const Icon(Icons.play_arrow),
              label: const Text("Start Timer"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
