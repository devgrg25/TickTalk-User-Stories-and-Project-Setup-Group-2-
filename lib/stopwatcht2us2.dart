import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class StopwatchT2US2 extends StatefulWidget {
  const StopwatchT2US2({super.key});

  @override
  State<StopwatchT2US2> createState() => _StopwatchT2US2State();
}

class _StopwatchT2US2State extends State<StopwatchT2US2>
    with TickerProviderStateMixin {
  late Stopwatch _stopwatch;
  late Duration _elapsed;
  late Ticker _ticker;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _elapsed = Duration.zero;
    // Use Flutter's built-in Ticker
    _ticker = createTicker(_onTick);
    _start(); // Auto-start stopwatch
  }

  void _onTick(Duration duration) {
    if (mounted) {
      setState(() {
        _elapsed = _stopwatch.elapsed;
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _stopwatch.stop();
    super.dispose();
  }

  void _start() {
    if (!_isRunning) {
      _stopwatch.start();
      _ticker.start();
      setState(() => _isRunning = true);
    }
  }

  void _stop() {
    if (_isRunning) {
      _stopwatch.stop();
      _ticker.stop();
      setState(() => _isRunning = false);
    }
  }

  void _reset() {
    _stopwatch.reset();
    setState(() => _elapsed = Duration.zero);
    if (_isRunning) {
      _start();
    }
  }

  void _resume() {
    if (!_isRunning) {
      _stopwatch.start();
      _ticker.start();
      setState(() => _isRunning = true);
    }
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final centiseconds =
    (duration.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds:$centiseconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TickTalk Stopwatch'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatTime(_elapsed),
              style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButton(
                  label: _isRunning ? 'Pause' : 'Start',
                  onPressed: _isRunning ? _stop : _resume,
                  color: _isRunning ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 16),
                _buildButton(
                  label: 'Reset',
                  onPressed: () => _reset(),
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}