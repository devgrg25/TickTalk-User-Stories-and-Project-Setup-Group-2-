import 'package:flutter/material.dart';
import '../../logic/timer/timer_controller.dart';
import '../../../logic/timer/timer_manager.dart';

class CountdownPage extends StatefulWidget {
  final TimerController controller;
  final VoidCallback onExit;

  const CountdownPage({
    super.key,
    required this.controller,
    required this.onExit,
  });

  @override
  State<CountdownPage> createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage> {
  late TimerController controller;

  @override
  void initState() {
    super.initState();
    controller = widget.controller;

    controller.onTick = () {
      if (mounted) setState(() {});
    };
    controller.onIntervalComplete = () {
      if (mounted) setState(() {});
    };
    controller.onTimerComplete = () => _showFinishDialog();
  }

  void _showFinishDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text("Timer Complete!",
            style: TextStyle(color: Colors.white, decoration: TextDecoration.none)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onExit();
            },
            child: const Text("OK",
                style: TextStyle(color: Colors.white, decoration: TextDecoration.none)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = controller.current;
    final next = controller.next;

    return Container(
      width: double.infinity,
      color: const Color(0xFF0F0F0F),
      child: Center(
        child: current == null
            ? const Text("Done!",
            style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                decoration: TextDecoration.none))
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// CURRENT INTERVAL NAME
            Text(
              current.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                decoration: TextDecoration.none,
              ),
            ),

            const SizedBox(height: 10),

            /// TIMER DIGITS
            Text(
              TimerController.format(controller.remainingSeconds),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 60,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),

            const SizedBox(height: 20),

            /// NEXT INTERVAL
            Text(
              next == null
                  ? "Next: — Finished —"
                  : "Next: ${next.name} (${TimerController.format(next.seconds)})",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontStyle: FontStyle.italic,
                decoration: TextDecoration.none,
              ),
            ),

            const SizedBox(height: 35),

            /// CONTROLS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: controller.isPaused
                      ? null
                      : () => setState(() => controller.pause()),
                  child: const Text("Pause",
                      style: TextStyle(decoration: TextDecoration.none)),
                ),
                const SizedBox(width: 12),

                ElevatedButton(
                  onPressed: controller.isPaused
                      ? () => setState(() => controller.resume())
                      : null,
                  child: const Text("Resume",
                      style: TextStyle(decoration: TextDecoration.none)),
                ),
                const SizedBox(width: 12),

                ElevatedButton(
                  onPressed: () =>
                      setState(() => controller.addTime(10)),
                  child: const Text("+10s",
                      style: TextStyle(decoration: TextDecoration.none)),
                ),
              ],
            ),

            const SizedBox(height: 30),

            /// STOP BUTTON
            TextButton(
              onPressed: () {
                controller.stop();
                widget.onExit();
              },
              child: const Text(
                "Stop Timer",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 18,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
