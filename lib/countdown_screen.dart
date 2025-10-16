// countdown_screen.dart

import 'dart:async';
import 'dart:math'; // For min()
import 'package:flutter/material.dart';
import 'create_timer_screen.dart'; // To access the TimerData class

class CountdownScreen extends StatefulWidget {
  final TimerData timerData;

  const CountdownScreen({super.key, required this.timerData});

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  late Timer _timer;
  int _currentSeconds = 0;
  String _currentPhase = 'Work';
  bool _isPaused = false;

  // --- 1. ADD THIS STATE VARIABLE ---
  int _elapsedTotalSeconds = 0;

  @override
  void initState() {
    super.initState();
    _currentPhase = 'Work';
    // Set the first interval, ensuring it's not longer than the total time allowed.
    _currentSeconds = min(widget.timerData.workInterval * 60, widget.timerData.totalTime * 60);
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Master check: if total time is up, stop everything.
      if (_elapsedTotalSeconds >= widget.timerData.totalTime * 60) {
        _timer.cancel();
        // Pop back to the create screen when the total time is finished.
        if (mounted) Navigator.of(context).pop();
        return;
      }

      // --- 2. INCREMENT THE TOTAL ELAPSED TIME ---
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
          : widget.timerData.breakInterval) * 60;

      final remainingTotalTime = (widget.timerData.totalTime * 60) - _elapsedTotalSeconds;

      // Ensure the next phase doesn't run longer than the remaining total time.
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
    final Color phaseColor = _currentPhase == 'Work' ? Colors.blue.shade600 : Colors.green.shade600;
    final int totalPhaseSeconds = (_currentPhase == 'Work' ? widget.timerData.workInterval : widget.timerData.breakInterval) * 60;
    final double phaseProgress = totalPhaseSeconds > 0 ? (_currentSeconds / totalPhaseSeconds).clamp(0.0, 1.0) : 0.0;

    // --- 3. CALCULATE TOTAL PROGRESS AND ADD THE WIDGET ---
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
      body: Column( // Changed to Column to easily add the progress bar
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
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
                  style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Spacer(), // Added to push content to the center
          Text(
            _currentPhase,
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: phaseColor),
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
                    style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
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
                icon: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 20),
              IconButton(
                iconSize: 70,
                icon: Icon(_isPaused ? Icons.play_circle_filled : Icons.pause_circle_filled, color: phaseColor),
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
          const Spacer(), // Added for balance
        ],
      ),
    );
  }
}