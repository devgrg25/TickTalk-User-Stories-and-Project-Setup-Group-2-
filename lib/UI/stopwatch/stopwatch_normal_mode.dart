import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // for Ticker

class StopwatchNormalMode extends StatefulWidget {
  final VoidCallback? onBack; // callback to return to MainPage

  const StopwatchNormalMode({super.key, this.onBack});

  @override
  State<StopwatchNormalMode> createState() => _StopwatchNormalModeState();
}

class _StopwatchNormalModeState extends State<StopwatchNormalMode>
    with TickerProviderStateMixin {
  late Stopwatch _stopwatch;
  late Duration _elapsed;
  late Ticker _ticker;
  bool _isRunning = false;

  final List<Duration> _laps = [];
  final ScrollController _scrollController = ScrollController();

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
    _scrollController.dispose();
    _stopwatch.stop();
    super.dispose();
  }

  // --- Called on every tick while running
  void _onTick(Duration _) {
    if (_stopwatch.isRunning && mounted) {
      setState(() => _elapsed = _stopwatch.elapsed);
    }
  }

  // --- Stopwatch control methods
  void _start() {
    if (_isRunning) return;
    _stopwatch.start();
    _ticker.start();
    setState(() => _isRunning = true);
  }

  void _stop() {
    if (!_isRunning) return;
    _stopwatch.stop();
    _ticker.stop();
    setState(() => _isRunning = false);
  }

  void _reset() {
    _stopwatch.stop();
    _ticker.stop();
    _stopwatch.reset();
    setState(() {
      _elapsed = Duration.zero;
      _isRunning = false;
      _laps.clear();
    });
  }

  void _lap() {
    if (_isRunning) {
      setState(() {
        _laps.add(_elapsed);
      });
      // auto-scroll to show latest lap
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.minScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  // --- Formatting helper
  String _formatTime(Duration duration) {
    final minutes =
    duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
    duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final centiseconds =
    (duration.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$centiseconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Stopwatch',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Time Display ---
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  _formatTime(_elapsed),
                  style: const TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),

            // --- Buttons Row ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton(
                  label: 'Lap',
                  icon: Icons.flag,
                  onPressed: _isRunning ? _lap : null,
                  color: primary,
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
                  onPressed: _laps.isNotEmpty || _elapsed > Duration.zero
                      ? _reset
                      : null,
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Laps Section ---
            if (_laps.isNotEmpty) ...[
              const Divider(),
              const Text(
                'Laps',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _laps.length,
                  reverse: true,
                  itemBuilder: (context, index) {
                    final lapNumber = _laps.length - index;
                    final lapTime = _laps[_laps.length - 1 - index];
                    final diff = index == 0
                        ? lapTime
                        : lapTime - _laps[_laps.length - index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primary,
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
                      subtitle: Text(
                        '+${_formatTime(diff)} since last lap',
                        style: const TextStyle(color: Colors.black54),
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

  // --- Button Builder ---
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
        backgroundColor: onPressed != null ? color : Colors.grey.shade300,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
