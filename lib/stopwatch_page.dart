import 'dart:async';
import 'package:flutter/material.dart';

class StopwatchPage extends StatefulWidget {
  const StopwatchPage({super.key});

  @override
  State<StopwatchPage> createState() => _StopwatchPageState();
}

class _StopwatchPageState extends State<StopwatchPage> {
  final Stopwatch _stopwatch = Stopwatch();
  // Timer to update the UI
  Timer? _timer;
  String _displayTime = '00:00.00';

  @override
  void dispose() {
    // Cancel the timer to avoid memory leaks
    _timer?.cancel();
    super.dispose();
  }

  void _startStop() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _timer?.cancel();
    } else {
      _stopwatch.start();
      // Update the UI every 30 milliseconds for a smooth display
      _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
        setState(() {
          _displayTime = _formatTime(_stopwatch.elapsed);
        });
      });
    }
    // Update the button text (Start/Stop)
    setState(() {});
  }

  void _reset() {
    _stopwatch.stop();
    _stopwatch.reset();
    _timer?.cancel();
    setState(() {
      _displayTime = '00:00.00';
    });
  }

  String _formatTime(Duration duration) {
    // Format the duration into MM:SS:ms
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    String twoDigitMilliseconds =
    twoDigits(duration.inMilliseconds.remainder(1000) ~/ 10);
    return "$twoDigitMinutes:$twoDigitSeconds.$twoDigitMilliseconds";
  }

  @override
  Widget build(BuildContext context) {
    // Get text style from the app's theme
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _displayTime,
              style: textTheme.displayLarge?.copyWith(
                fontSize: 80,
                fontFamily: 'monospace', // Gives a classic digital clock feel
              ),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset Button
                ElevatedButton(
                  onPressed: _reset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Reset'),
                ),
                const SizedBox(width: 20),
                // Start/Stop Button
                ElevatedButton(
                  onPressed: _startStop,
                  child: Text(_stopwatch.isRunning ? 'Stop' : 'Start'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}