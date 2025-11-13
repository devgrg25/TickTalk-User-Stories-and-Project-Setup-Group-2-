import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';

class StopwatchT2US2 extends StatefulWidget {
  const StopwatchT2US2({
    super.key,
    this.tutorialMode = false,
    this.onTutorialFinish,
  });

  // optional tutorial hooks (kept for future use)
  final bool tutorialMode;
  final VoidCallback? onTutorialFinish;

  @override
  State<StopwatchT2US2> createState() => _StopwatchT2US2State();
}

class _StopwatchT2US2State extends State<StopwatchT2US2>
    with TickerProviderStateMixin {
  late Stopwatch _stopwatch;
  late Duration _elapsed;
  late Ticker _ticker;
  bool _isRunning = false;

  // Lap tracking
  List<Duration> _laps = [];

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _elapsed = Duration.zero;
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _stopwatch.stop();
    super.dispose();
  }

  void _onTick(Duration duration) {
    if (mounted) {
      setState(() {
        _elapsed = _stopwatch.elapsed;
      });
    }
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
    _laps.clear();
    setState(() => _elapsed = Duration.zero);
  }

  void _lap() {
    if (_isRunning) {
      setState(() {
        _laps.add(_elapsed);
      });
    }
  }

  String _formatTime(Duration duration) {
    final minutes =
    duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
    duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final centiseconds =
    (duration.inMilliseconds.remainder(1000) ~/ 10)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds:$centiseconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Stopwatch', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Timer Display
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  _formatTime(_elapsed),
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),

            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton(
                  label: 'Lap',
                  icon: Icons.flag,
                  onPressed: _isRunning ? _lap : null,
                  color: const Color(0xFF007BFF),
                ),
                _buildButton(
                  label: _isRunning ? 'Stop' : 'Start',
                  icon: _isRunning ? Icons.pause : Icons.play_arrow,
                  onPressed: _isRunning ? _stop : _start,
                  color: _isRunning ? Colors.orange : Colors.green,
                ),
                _buildButton(
                  label: 'Reset',
                  icon: Icons.refresh,
                  onPressed: _reset,
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Laps List
            if (_laps.isNotEmpty) ...[
              const Divider(),
              const Text(
                'Laps',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _laps.length,
                  reverse: true,
                  itemBuilder: (context, index) {
                    final lapNumber = _laps.length - index;
                    final lapTime = _laps[_laps.length - 1 - index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF007BFF),
                        child: Text(
                          '$lapNumber',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        _formatTime(lapTime),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 18,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        disabledBackgroundColor: Colors.grey.shade300,
      ),
    );
  }
}
