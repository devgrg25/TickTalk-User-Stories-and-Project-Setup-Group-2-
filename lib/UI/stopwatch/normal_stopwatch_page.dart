import 'package:flutter/material.dart';
import '../../logic/stopwatch/stopwatch_controller.dart';
import '../../logic/stopwatch/stopwatch_manager.dart';

class NormalStopwatchPage extends StatefulWidget {
  const NormalStopwatchPage({super.key});

  @override
  State<NormalStopwatchPage> createState() => _NormalStopwatchPageState();
}

class _NormalStopwatchPageState extends State<NormalStopwatchPage> {
  StopwatchController? controller;

  @override
  void initState() {
    super.initState();
    controller = StopwatchManager.instance.startStopwatch();
    controller!.onTick = () => setState(() {});
  }

  @override
  void dispose() {
    StopwatchManager.instance.stopAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatted = StopwatchController.format(controller!.elapsedMs);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("Stopwatch"),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              formatted,
              style: const TextStyle(
                fontSize: 64,
                color: Colors.white,
                fontFamily: 'Courier',
              ),
            ),
            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: controller!.isPaused ? controller!.resume : controller!.pause,
                  child: Text(controller!.isPaused ? "Resume" : "Pause"),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: controller!.reset,
                  child: const Text("Reset"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Back"),
            ),
          ],
        ),
      ),
    );
  }
}
