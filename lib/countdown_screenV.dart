import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'routine_timer_model.dart';
import 'voice_controller.dart';

class CountdownScreenV extends StatefulWidget {
  final TimerDataV timerData;

  const CountdownScreenV({super.key, required this.timerData});

  @override
  State<CountdownScreenV> createState() => _CountdownScreenVState();
}

class _CountdownScreenVState extends State<CountdownScreenV> {
  late Timer _timer;
  int _currentStepIndex = 0;
  int _remainingSeconds = 0;
  bool _isPaused = false;

  final FlutterTts _tts = FlutterTts();
  // We can use a new instance or pass it down.
  // For simplicity here, a new instance to handle active-timer specific commands if needed later.
  final VoiceController _voiceController = VoiceController();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _voiceController.initialize();
    _startRoutine();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.9);
    await _tts.awaitSpeakCompletion(true);
  }

  @override
  void dispose() {
    _timer.cancel();
    _tts.stop();
    // Don't dispose _voiceController if you want it to persist,
    // but since we created a local instance, we should probably dispose it
    // or just let the main one handle it. safely:
    // _voiceController.dispose();
    super.dispose();
  }

  void _startRoutine() {
    _currentStepIndex = 0;
    if (widget.timerData.steps.isNotEmpty) {
      _setupStep(_currentStepIndex);
      _startTimerTicker();
    }
  }

  void _setupStep(int index) {
    setState(() {
      _currentStepIndex = index;
      _remainingSeconds = widget.timerData.steps[index].durationInMinutes * 60;
    });
    _announceStep();
  }

  Future<void> _announceStep() async {
    final stepName = widget.timerData.steps[_currentStepIndex].name;
    final duration = widget.timerData.steps[_currentStepIndex].durationInMinutes;
    await _tts.speak("Starting step: $stepName for $duration minutes.");
  }

  void _startTimerTicker() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          _timer.cancel();
          _nextStep();
        }
      }
    });
  }

  void _nextStep() async {
    if (_currentStepIndex < widget.timerData.steps.length - 1) {
      _setupStep(_currentStepIndex + 1);
      _startTimerTicker();
    } else {
      await _tts.speak("${widget.timerData.name} routine complete!");
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    if (_isPaused) {
      _tts.speak("Timer paused.");
    } else {
      _tts.speak("Resuming.");
    }
  }

  Future<void> _startListening() async {
    if (!_voiceController.isInitialized) return;
    setState(() => _isListening = true);
    await _tts.speak("Listening..."); // Use TTS for quick feedback
    await _voiceController.listenAndRecognize(
      onCommandRecognized: (command) {
        final cmd = command.toLowerCase();
        if (cmd.contains('pause') || cmd.contains('stop')) {
          if (!_isPaused) _togglePause();
        } else if (cmd.contains('resume') || cmd.contains('start') || cmd.contains('continue')) {
          if (_isPaused) _togglePause();
        } else if (cmd.contains('cancel') || cmd.contains('exit')) {
          Navigator.pop(context);
        }
      },
      onComplete: () {
        if (mounted) setState(() => _isListening = false);
      },
    );
  }

  Future<void> _stopListening() async {
    await _voiceController.stopListening();
    if (mounted) setState(() => _isListening = false);
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = widget.timerData.steps[_currentStepIndex];
    final nextStepName = (_currentStepIndex < widget.timerData.steps.length - 1)
        ? widget.timerData.steps[_currentStepIndex + 1].name
        : "None (Finishing)";

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(color: Colors.black, onPressed: () {
          _timer.cancel();
          Navigator.pop(context);
        }),
        title: Text(widget.timerData.name, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        // Added large bottom padding to clear the microphone bar
        padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 120.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- Step Info Card ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Step ${_currentStepIndex + 1} of ${widget.timerData.steps.length}",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentStep.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF007BFF)),
                  ),
                  const SizedBox(height: 32),
                  // --- Timer Display ---
                  Text(
                    _formatTime(_remainingSeconds),
                    style: const TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()], // Monospaced numbers if font supports it
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- Next Step Preview ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Up Next: ", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(nextStepName),
                ],
              ),
            ),
            const Spacer(),

            // --- Controls ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pause/Resume Button
                ElevatedButton.icon(
                  onPressed: _togglePause,
                  icon: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 32),
                  label: Text(_isPaused ? "RESUME" : "PAUSE", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPaused ? Colors.green : Colors.orangeAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
            // Extra space at bottom specifically requested to avoid mic overlap
            const SizedBox(height: 40),
          ],
        ),
      ),
      // --- Mic Bar ---
      bottomSheet: SafeArea(
        child: GestureDetector(
          onTap: _isListening ? _stopListening : _startListening,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            color: _isListening ? Colors.redAccent : const Color(0xFF007BFF),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}