import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'routine_timer_model.dart';
import 'widgets/global_scaffold.dart'; // ✅ Global scaffold for mic bar

class CountdownScreenV extends StatefulWidget {
  final TimerDataV timerData;

  const CountdownScreenV({super.key, required this.timerData});

  @override
  State<CountdownScreenV> createState() => _CountdownScreenVState();
}

class _CountdownScreenVState extends State<CountdownScreenV> {
  late Timer _timer;
  int _currentSeconds = 0;
  int _elapsedTotalSeconds = 0;
  int _currentStepIndex = 0;

  bool _isPaused = false;
  bool _audioFeedbackOn = true;
  bool _hapticFeedbackOn = true;

  // --- Helpers ---
  TimerStep get _currentStep => widget.timerData.steps[_currentStepIndex];
  int get _totalSteps => widget.timerData.steps.length;
  int get _totalDurationInSeconds => widget.timerData.totalTime * 60;

  @override
  void initState() {
    super.initState();
    _startStep();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startStep() {
    _currentSeconds = _currentStep.durationInMinutes * 60;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isPaused) return;

      setState(() {
        _elapsedTotalSeconds++;

        if (_currentSeconds > 0) {
          _currentSeconds--;
        } else {
          _timer.cancel();
          _nextStep();
        }
      });
    });
  }

  void _nextStep() {
    if (_currentStepIndex < _totalSteps - 1) {
      setState(() => _currentStepIndex++);
      _startStep();
    } else {
      Navigator.of(context).pop();
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF007BFF);
    const Color cardBackground = Color(0xFFF9FAFB);
    const Color cardBorder = Color(0xFFE5E7EB);
    const Color textColor = Colors.black;
    const Color subtextColor = Colors.black54;

    return GlobalScaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Active Timer', style: TextStyle(color: textColor)),
        centerTitle: true,
        leading: const BackButton(color: textColor),
      ),

      // ✅ FIXED: Use child instead of body
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Current Timer Card ---
            Card(
              elevation: 0,
              color: cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: cardBorder),
              ),
              child: ListTile(
                title: const Text('Current Timer',
                    style: TextStyle(fontSize: 12, color: subtextColor)),
                subtitle: Text(
                  widget.timerData.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Main Timer Display ---
            Card(
              elevation: 0,
              color: cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: cardBorder),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Column(
                  children: [
                    Text(
                      'Step ${_currentStepIndex + 1} of $_totalSteps: '
                          '${_currentStep.name.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(_currentSeconds),
                      style: const TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Elapsed: ${_formatTime(_elapsedTotalSeconds)} / '
                          'Total: ${_formatTime(_totalDurationInSeconds)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Feedback Controls ---
            Card(
              elevation: 0,
              color: cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: cardBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFeedbackToggle(
                      icon: Icons.volume_up_outlined,
                      label: 'Audio Feedback',
                      isOn: _audioFeedbackOn,
                      onChanged: (value) =>
                          setState(() => _audioFeedbackOn = value),
                    ),
                    _buildFeedbackToggle(
                      icon: Icons.vibration_outlined,
                      label: 'Haptic Feedback',
                      isOn: _hapticFeedbackOn,
                      onChanged: (value) =>
                          setState(() => _hapticFeedbackOn = value),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // --- Pause / Resume Button ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() => _isPaused = !_isPaused);
                },
                icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, size: 24),
                label: Text(
                  _isPaused ? 'Resume Timer' : 'Pause Timer',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isPaused ? Colors.green : primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 👇 Mic button handled globally
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackToggle({
    required IconData icon,
    required String label,
    required bool isOn,
    required ValueChanged<bool> onChanged,
  }) {
    const Color primaryBlue = Color(0xFF007BFF);
    const Color inactiveGrey = Colors.grey;

    return Column(
      children: [
        Icon(icon, color: isOn ? primaryBlue : inactiveGrey),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        Switch(
          value: isOn,
          onChanged: onChanged,
          activeTrackColor: primaryBlue.withOpacity(0.3),
          activeColor: primaryBlue,
        ),
      ],
    );
  }
}
