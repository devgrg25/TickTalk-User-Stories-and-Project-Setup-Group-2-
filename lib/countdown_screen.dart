// countdown_screen.dart  (ADDED tutorialMode + overlay + TTS narration; original logic preserved)

import 'dart:async';
import 'dart:math'; // For min()
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart'; // 👈 added for narration
import 'create_timer_screen.dart'; // To access the TimerData class

class CountdownScreen extends StatefulWidget {
  final TimerData timerData;

  // 👇 optional tutorial hooks (non-breaking)
  final bool tutorialMode;
  final VoidCallback? onTutorialNext;

  const CountdownScreen({
    super.key,
    required this.timerData,
    this.tutorialMode = false,
    this.onTutorialNext,
  });

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  late Timer _timer;
  int _currentSeconds = 0;
  String _currentPhase = 'Work';
  bool _isPaused = false;

  int _elapsedTotalSeconds = 0;

  // TTS for tutorial narration
  FlutterTts? _tts;

  @override
  void initState() {
    super.initState();
    _currentPhase = 'Work';
    _currentSeconds =
        min(widget.timerData.workInterval * 60, widget.timerData.totalTime * 60);

    if (widget.tutorialMode) {
      _tts = FlutterTts();
      Future.microtask(() async {
        try {
          await _tts?.setLanguage('en-US');
          await _tts?.setSpeechRate(0.52);
          await _tts?.setPitch(1.0);
          await _tts?.awaitSpeakCompletion(true);
          await _tts?.speak(
            'This is the countdown timer. '
                'The ring drains as time passes. '
                'Pause or resume with the center button, skip to switch between Work and Break, '
                'and the red stop button exits. '
                'The thin bar at the top shows total progress through the whole session.',
          );
        } catch (_) {}
      });
    }

    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _tts?.stop();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Master check: if total time is up, stop everything.
      if (_elapsedTotalSeconds >= widget.timerData.totalTime * 60) {
        _timer.cancel();

        // In tutorial, proceed automatically to the next step instead of popping.
        if (widget.tutorialMode) {
          widget.onTutorialNext?.call();
        } else {
          if (mounted) Navigator.of(context).pop();
        }
        return;
      }

      if (!_isPaused) {
        setState(() => _elapsedTotalSeconds++);
      }

      if (_currentSeconds > 0) {
        if (!_isPaused) {
          setState(() => _currentSeconds--);
        }
      } else {
        // When a phase ends, toggle to the next one
        _timer.cancel();
        _togglePhase();
        _startTimer();
      }
    });
  }

  void _togglePhase() {
    setState(() {
      _currentPhase = (_currentPhase == 'Work') ? 'Break' : 'Work';

      final nextPhaseDuration = (_currentPhase == 'Work'
          ? widget.timerData.workInterval
          : widget.timerData.breakInterval) *
          60;

      final remainingTotalTime =
          (widget.timerData.totalTime * 60) - _elapsedTotalSeconds;

      _currentSeconds = min(nextPhaseDuration, remainingTotalTime);
    });
  }

  void _pauseOrResumeTimer() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  String get _formattedTime {
    int minutes = _currentSeconds ~/ 60;
    int seconds = _currentSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final Color phaseColor =
    _currentPhase == 'Work' ? Colors.blue.shade600 : Colors.green.shade600;
    final int totalPhaseSeconds = (_currentPhase == 'Work'
        ? widget.timerData.workInterval
        : widget.timerData.breakInterval) *
        60;
    final double phaseProgress =
    totalPhaseSeconds > 0 ? (_currentSeconds / totalPhaseSeconds).clamp(0.0, 1.0) : 0.0;

    final double totalProgress = (widget.timerData.totalTime * 60 > 0)
        ? _elapsedTotalSeconds / (widget.timerData.totalTime * 60)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.timerData.name),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // --- Original content ---
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: totalProgress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade700),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total Progress',
                      style: TextStyle(
                          color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _currentPhase,
                style: TextStyle(
                    fontSize: 40, fontWeight: FontWeight.bold, color: phaseColor),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 250,
                height: 250,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: 1.0 - phaseProgress, // Inverted to "drain"
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(phaseColor),
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Text(
                        _formattedTime,
                        style: const TextStyle(
                            fontSize: 60, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 50,
                    icon: const Icon(Icons.stop_circle_outlined,
                        color: Colors.redAccent),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    iconSize: 70,
                    icon: Icon(
                        _isPaused
                            ? Icons.play_circle_filled
                            : Icons.pause_circle_filled,
                        color: phaseColor),
                    onPressed: _pauseOrResumeTimer,
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    iconSize: 50,
                    icon: const Icon(Icons.skip_next_outlined),
                    onPressed: () {
                      _timer.cancel();
                      _togglePhase();
                      _startTimer();
                    },
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),

          // --- Tutorial overlay (non-intrusive) ---
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
                        '• Big ring drains as the current phase counts down.\n'
                            '• Pause/Resume with the center button.\n'
                            '• Skip moves between Work and Break.\n'
                            '• Red Stop exits.\n'
                            '• Thin bar at top = overall progress.',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              try { await _tts?.stop(); } catch (_) {}
                              widget.onTutorialNext?.call();
                            },
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Next: Stopwatch'),
                          ),
                          const Spacer(),
                          Icon(Icons.lightbulb, color: Colors.amber.shade700),
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
}
