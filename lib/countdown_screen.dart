// countdown_screen.dart

import 'dart:async';
import 'dart:math';
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
  int _elapsedTotalSeconds = 0;
  String _currentPhase = 'Work';
  bool _isPaused = false;

  bool _audioFeedbackOn = true;
  bool _hapticFeedbackOn = true;

  @override
  void initState() {
    super.initState();
    _currentPhase = 'Work';
    _currentSeconds =
        min(widget.timerData.workInterval * 60, widget.timerData.totalTime * 60);
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      if (_elapsedTotalSeconds >= widget.timerData.totalTime * 60) {
        _timer.cancel();
        Navigator.of(context).pop();
        return;
      }

      if (!_isPaused) {
        setState(() {
          _elapsedTotalSeconds++;
          if (_currentSeconds > 0) {
            _currentSeconds--;
          } else {
            _timer.cancel();
            _togglePhase();
            _startTimer();
          }
        });
      }
    });
  }

  void _togglePhase() {
    // UPDATED: Set the phase to 'Break' or 'Work'
    _currentPhase = (_currentPhase == 'Work') ? 'Break' : 'Work';

    final nextPhaseDuration = (_currentPhase == 'Work'
        ? widget.timerData.workInterval
        : widget.timerData.breakInterval) *
        60;

    final remainingTotalTime =
        (widget.timerData.totalTime * 60) - _elapsedTotalSeconds;

    _currentSeconds = min(nextPhaseDuration, remainingTotalTime);
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // --- COLOR PALETTE FROM HomeScreen ---
    const Color primaryBlue = Color(0xFF007BFF);
    const Color breakGreen = Colors.green; // Same as 'Completed' status
    const Color cardBackground = Color(0xFFF9FAFB);
    const Color cardBorder = Color(0xFFE5E7EB); // Equivalent to grey.shade300
    const Color inactiveGrey = Colors.grey;
    const Color textColor = Colors.black;
    const Color subtextColor = Colors.black54;

    // Determine the active color based on the current phase
    final Color activeColor = _currentPhase == 'Work' ? primaryBlue : breakGreen;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Active Timer', style: TextStyle(color: textColor)),
        centerTitle: true,
        leading: const BackButton(color: textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: textColor),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // "Current Timer" card
            Card(
              elevation: 0,
              color: cardBackground,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: cardBorder)),
              child: ListTile(
                title: const Text('Current Timer', style: TextStyle(fontSize: 12, color: subtextColor)),
                subtitle: Text(
                  widget.timerData.name,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Main timer display card
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
                      'Set ${widget.timerData.currentSet} of ${widget.timerData.totalSets}',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(_currentSeconds),
                      style: const TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Elapsed: ${_formatTime(_elapsedTotalSeconds)} / Total: ${_formatTime(widget.timerData.totalTime * 60)}',
                      style: TextStyle(
                          fontSize: 16,
                          color: textColor.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Feedback controls card
            Card(
              elevation: 0,
              color: cardBackground,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: cardBorder)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFeedbackToggle(
                      icon: Icons.volume_up_outlined,
                      label: 'Audio Feedback',
                      isOn: _audioFeedbackOn,
                      onChanged: (value) {
                        setState(() => _audioFeedbackOn = value);
                      },
                    ),
                    _buildFeedbackToggle(
                      icon: Icons.vibration_outlined,
                      label: 'Haptic Feedback',
                      isOn: _hapticFeedbackOn,
                      onChanged: (value) {
                        setState(() => _hapticFeedbackOn = value);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // "Tap to Speak" button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.mic, size: 24),
                label: const Text(
                  'Tap to Speak',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeColor, // UPDATED: Dynamic color
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Helper widget for the feedback toggles
  Widget _buildFeedbackToggle({
    required IconData icon,
    required String label,
    required bool isOn,
    required ValueChanged<bool> onChanged,
  }) {
    // UPDATED: Using the color palette from HomeScreen
    const Color primaryBlue = Color(0xFF007BFF);
    const Color inactiveGrey = Colors.grey;

    return Column(
      children: [
        Icon(
          icon,
          color: isOn ? primaryBlue : inactiveGrey,
        ),
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