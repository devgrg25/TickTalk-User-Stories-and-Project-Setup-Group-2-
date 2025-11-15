import 'package:flutter/material.dart';
import '../logic/timer/timer_controller.dart'; // <-- adjust path based on your folder

class CountdownScreen extends StatefulWidget {
  final int totalSeconds;
  const CountdownScreen({super.key, required this.totalSeconds});

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  late TimerController controller;

  @override
  void initState() {
    super.initState();
    controller = TimerController(widget.totalSeconds);
  }

  @override
  void dispose() {
    controller.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Center(
        child: StreamBuilder<int>(
          stream: controller.stream,
          initialData: widget.totalSeconds,
          builder: (context, snapshot) {
            final remaining = snapshot.data ?? 0;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 340,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
              decoration: BoxDecoration(
                color: const Color(0xFF171717),
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    offset: Offset(2, 5),
                    blurRadius: 10,
                    color: Colors.black54,
                  ),
                ],
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Countdown",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    TimerController.format(remaining),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _smallButton(
                        controller.isPaused ? "Resume" : "Pause",
                            () => controller.togglePause(),
                      ),
                      const SizedBox(width: 10),
                      _smallButton("+1 Min", () => controller.addOneMinute()),
                    ],
                  ),

                  const SizedBox(height: 14),

                  _stopButton("Stop", () {
                    controller.stop();
                    Navigator.pop(context);
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- Buttons (unchanged UI) ---

  Widget _smallButton(String text, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        backgroundColor: const Color(0xFF252525),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      onPressed: onTap,
      child: Text(text),
    );
  }

  Widget _stopButton(String text, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 12),
        backgroundColor: const Color(0xFF252525),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      onPressed: onTap,
      child: Text(text),
    );
  }
}
