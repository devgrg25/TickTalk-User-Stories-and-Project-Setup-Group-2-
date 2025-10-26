import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'widgets/global_scaffold.dart'; // ✅ Import the global mic wrapper

class StopwatchNormalMode extends StatefulWidget {
  final bool autoStart; // Flag to check if auto-started from homepage

  const StopwatchNormalMode({super.key, this.autoStart = false});

  @override
  State<StopwatchNormalMode> createState() => _StopwatchNormalModeState();
}

class _StopwatchNormalModeState extends State<StopwatchNormalMode>
    with TickerProviderStateMixin {
  late Stopwatch _stopwatch;
  late Duration _elapsed;
  late Ticker _ticker;
  bool _isRunning = false;

  final FlutterTts _tts = FlutterTts();
  List<Duration> _laps = [];
  Duration _lastAnnouncedTime = Duration.zero;
  bool _showSummary = false;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _elapsed = Duration.zero;
    _ticker = createTicker(_onTick);
    _initTts();

    // Auto-start if coming from homepage
    if (widget.autoStart) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _start();
        }
      });
    }
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.3);
    await _tts.setPitch(1.0);
  }

  void _onTick(Duration duration) {
    if (mounted) {
      setState(() {
        _elapsed = _stopwatch.elapsed;
      });
      _checkTimeAnnouncement();
    }
  }

  void _checkTimeAnnouncement() {
    final currentSeconds = _elapsed.inSeconds;
    final lastAnnouncedSeconds = _lastAnnouncedTime.inSeconds;

    if (currentSeconds > 0 &&
        currentSeconds % 30 == 0 &&
        currentSeconds != lastAnnouncedSeconds) {
      _lastAnnouncedTime = _elapsed;
      _announceTime();
    }
  }

  Future<void> _announceTime() async {
    final minutes = _elapsed.inMinutes;
    final seconds = _elapsed.inSeconds.remainder(60);
    String announcement = minutes > 0
        ? "$minutes minute${minutes != 1 ? 's' : ''} $seconds second${seconds != 1 ? 's' : ''}"
        : "$seconds second${seconds != 1 ? 's' : ''}";
    await _tts.speak(announcement);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _stopwatch.stop();
    _tts.stop();
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
    _laps.clear();
    _lastAnnouncedTime = Duration.zero;
    setState(() {
      _elapsed = Duration.zero;
      _isRunning = false;
    });
    _ticker.stop();
  }

  void _lap() {
    if (_isRunning) {
      setState(() {
        _laps.add(_elapsed);
      });
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
    if (_showSummary) {
      return _buildSummaryScreen();
    }

    return GlobalScaffold( // ✅ Replaces Scaffold — brings in global mic
      appBar: AppBar(
        title: const Text('Normal Mode', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(
          color: Colors.black,
          onPressed: () {
            _tts.stop();
            Navigator.of(context).pop();
          },
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatTime(_elapsed),
                  style: const TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildControlButton(
                      label: 'Lap',
                      icon: Icons.flag,
                      onPressed: _isRunning ? _lap : null,
                      color: const Color(0xFF007BFF),
                    ),
                    const SizedBox(width: 16),
                    _buildControlButton(
                      label: _isRunning ? 'Stop' : 'Start',
                      icon: _isRunning ? Icons.pause : Icons.play_arrow,
                      onPressed: _isRunning ? _stop : _start,
                      color: _isRunning ? Colors.orange : Colors.green,
                    ),
                    const SizedBox(width: 16),
                    _buildControlButton(
                      label: 'Reset',
                      icon: Icons.refresh,
                      onPressed: _reset,
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: _laps.isNotEmpty
                      ? () => setState(() => _showSummary = true)
                      : null,
                  icon: const Icon(Icons.list_alt),
                  label: Text(
                      _laps.isEmpty ? 'No Laps Yet' : 'View ${_laps.length} Laps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007BFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryScreen() {
    return GlobalScaffold(
      appBar: AppBar(
        title: const Text('Lap Summary', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Icon(Icons.flag, size: 64, color: Color(0xFF007BFF)),
                const SizedBox(height: 12),
                Text(
                  '${_laps.length} Lap${_laps.length > 1 ? 's' : ''} Recorded',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Time: ${_formatTime(_elapsed)}',
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _laps.length,
              itemBuilder: (context, index) {
                final lapNumber = index + 1;
                final lapTime = _laps[index];
                final lapDuration = index == 0
                    ? lapTime
                    : Duration(
                    milliseconds:
                    lapTime.inMilliseconds - _laps[index - 1].inMilliseconds);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF007BFF),
                      child: Text('$lapNumber',
                          style: const TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                    title: Text(
                      'Total: ${_formatTime(lapTime)}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                    ),
                    subtitle: Text(
                      'Split: ${_formatTime(lapDuration)}',
                      style: const TextStyle(
                          fontSize: 14, color: Colors.black54, fontFamily: 'monospace'),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
