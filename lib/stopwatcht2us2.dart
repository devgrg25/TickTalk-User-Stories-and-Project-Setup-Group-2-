// stopwatcht2us2.dart  (ADDED tutorialMode + overlay + TTS narration; original logic preserved)

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_tts/flutter_tts.dart'; // 👈 added for narration

class StopwatchT2US2 extends StatefulWidget {
  const StopwatchT2US2({
    super.key,
    this.tutorialMode = false,
    this.onTutorialFinish,
  });

  // optional tutorial hooks (non-breaking)
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

  FlutterTts? _tts;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _elapsed = Duration.zero;
    _ticker = createTicker(_onTick);

    if (widget.tutorialMode) {
      _tts = FlutterTts();
      Future.microtask(() async {
        try {
          await _tts?.setLanguage('en-US');
          await _tts?.setSpeechRate(0.52);
          await _tts?.setPitch(1.0);
          await _tts?.awaitSpeakCompletion(true);
          await _tts?.speak(
            'This is the stopwatch. '
                'Tap Start to begin, Pause to hold, and Reset to clear the time. '
                'We show minutes, seconds, and centiseconds.',
          );
        } catch (_) {}
      });
    }

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
    _tts?.stop();
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
      appBar: AppBar(
        title: const Text('TickTalk Stopwatch'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Stack(
        children: [
          // --- Original content ---
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatTime(_elapsed),
                  style: const TextStyle(
                      fontSize: 72, fontWeight: FontWeight.bold),
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

          // --- Tutorial overlay ---
          if (widget.tutorialMode)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: Material(
                borderRadius: BorderRadius.circular(12),
                elevation: 6,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How this screen works',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Start begins counting; Pause holds the time.\n'
                            '• Reset clears back to 00:00:00.\n'
                            '• Time shows minutes : seconds : centiseconds.',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              try { await _tts?.stop(); } catch (_) {}
                              widget.onTutorialFinish?.call();
                            },
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Finish Tutorial'),
                          ),
                          const Spacer(),
                          const Icon(Icons.timer_outlined, color: Colors.blue),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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
        style:
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}
