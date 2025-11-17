// countdown_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../timer_models/timer_model.dart';

class CountdownController {
  VoidCallback? _pause;
  VoidCallback? _resume;
  VoidCallback? _stop;

  void _bind({
    required VoidCallback pause,
    required VoidCallback resume,
    required VoidCallback stop,
  }) {
    _pause = pause;
    _resume = resume;
    _stop = stop;
  }

  void pause() => _pause?.call();
  void resume() => _resume?.call();
  void stopSpeaking() => _stop?.call();
}

class CountdownScreen extends StatefulWidget {
  final TimerData timerData;
  final VoidCallback? onBack;
  final CountdownController? controller;

  const CountdownScreen({
    super.key,
    required this.timerData,
    this.onBack,
    this.controller,
  });

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  late Timer _timer;
  late FlutterTts _tts;
  bool _isPaused = false;

  int _elapsedTotalSeconds = 0;   // MASTER CLOCK
  String _lastSpokenPhase = "";

  // ------------------------------------------------------------
  // INITIALIZATION
  // ------------------------------------------------------------
  @override
  void initState() {
    super.initState();

    _tts = FlutterTts();
    _initTts();

    widget.controller?._bind(
      pause: _pauseTimer,
      resume: _resumeTimer,
      stop: () => _tts.stop(),
    );

    _speakStartMessage();
    _startTimerEngine();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.awaitSpeakCompletion(true);
  }

  // Speak the initial description of the timer
  Future<void> _speakStartMessage() async {
    final workMin = widget.timerData.workInterval;
    final breakMin = widget.timerData.breakInterval;
    final sets = widget.timerData.totalSets;
    final name = widget.timerData.name;

    String message = 'Starting timer "$name". '
        'Work for $workMin minutes, break for $breakMin minutes, '
        'for $sets sets.';

    await _tts.speak(message);
  }

  // ------------------------------------------------------------
  // MASTER CLOCK ENGINE — Runs once per second
  // ------------------------------------------------------------
  void _startTimerEngine() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isPaused) return;

      setState(() {
        _elapsedTotalSeconds++;
      });

      _speakPhaseAnnouncements();

      if (_elapsedTotalSeconds >= totalSec) {
        _finishTimer();
      }
    });
  }

  // ------------------------------------------------------------
  // CALCULATIONS (Approach 1 — All derived from _elapsedTotalSeconds)
  // ------------------------------------------------------------

  int get workSec => widget.timerData.workInterval * 60;
  int get breakSec => widget.timerData.breakInterval * 60;

  // One full set duration (Work + Break)
  int get cycleSec => workSec + breakSec;

  // Total sets
  int get totalSets => widget.timerData.totalSets;

  // Total duration (no final break)
  int get totalSec =>
      workSec * totalSets + breakSec * (totalSets - 1);

  // Which set we are in
  int get currentSet => (_elapsedTotalSeconds ~/ cycleSec) + 1;

  // Seconds into this set
  int get secondsIntoSet => _elapsedTotalSeconds % cycleSec;

  // Work or break phase
  bool get inWorkPhase => secondsIntoSet < workSec;

  // Remaining seconds in this phase
  int get phaseRemaining {
    if (inWorkPhase) {
      return workSec - secondsIntoSet;
    } else {
      int intoBreak = secondsIntoSet - workSec;
      return breakSec - intoBreak;
    }
  }

  // Remaining total
  int get totalRemaining => totalSec - _elapsedTotalSeconds;

  String get phaseLabel => inWorkPhase ? "Work" : "Break";

  // ------------------------------------------------------------
  // TTS Phase Announcements
  // ------------------------------------------------------------
  void _speakPhaseAnnouncements() {
    if (_elapsedTotalSeconds == 0) return;

    if (phaseLabel != _lastSpokenPhase) {
      _lastSpokenPhase = phaseLabel;

      if (phaseLabel == "Work") {
        _tts.speak("Start working.");
      } else {
        _tts.speak("Take a break.");
      }
    }
  }

  // ------------------------------------------------------------
  // PAUSE / RESUME / FINISH
  // ------------------------------------------------------------
  void _pauseTimer() {
    setState(() => _isPaused = true);
    _tts.speak("Timer paused.");
  }

  void _resumeTimer() {
    setState(() => _isPaused = false);
    _tts.speak("Resuming.");
  }

  void _finishTimer() {
    _timer.cancel();
    _tts.speak("Timer completed.");
    widget.onBack?.call();
  }

  // ------------------------------------------------------------
  // HELPER
  // ------------------------------------------------------------
  String _format(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer.cancel();
    _tts.stop();
    super.dispose();
  }

  // ------------------------------------------------------------
  // UI — Restored from your original design
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    const Color cardBackground = Color(0xFFF9FAFB);
    const Color cardBorder = Color(0xFFE5E7EB);
    const Color textColor = Colors.black;
    const Color subtextColor = Colors.black54;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Active Timer', style: TextStyle(color: textColor)),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // ---- CURRENT TIMER NAME ----
              Card(
                elevation: 0,
                color: cardBackground,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: cardBorder)),
                child: ListTile(
                  title: const Text('Current Timer',
                      style: TextStyle(fontSize: 12, color: subtextColor)),
                  subtitle: Text(widget.timerData.name,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                ),
              ),
              const SizedBox(height: 24),

              // ---- MAIN TIMER DISPLAY ----
              Card(
                elevation: 0,
                color: cardBackground,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: cardBorder)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Column(
                    children: [
                      Text(
                        'Set $currentSet of ${widget.timerData.totalSets}',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        _format(phaseRemaining),
                        style: const TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.bold,
                            color: textColor),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'Phase: $phaseLabel',
                        style:
                        TextStyle(fontSize: 16, color: textColor.withOpacity(0.6)),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'Elapsed: ${_format(_elapsedTotalSeconds)} / Total: ${_format(totalSec)}',
                        style: TextStyle(
                            fontSize: 16, color: textColor.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
