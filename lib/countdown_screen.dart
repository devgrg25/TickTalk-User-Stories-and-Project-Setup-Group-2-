import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'timer_model.dart';
import 'widgets/global_scaffold.dart'; // ✅ Import global mic wrapper

class CountdownScreen extends StatefulWidget {
  final TimerData timerData;
  final int startingSet;
  final bool tutorialMode;
  final VoidCallback? onTutorialNext;

  const CountdownScreen({
    super.key,
    required this.timerData,
    this.startingSet = 1,
    this.tutorialMode = false,
    this.onTutorialNext,
  });

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  late FlutterTts _tts;
  late Timer _timer;
  int _currentSeconds = 0;
  int _elapsedTotalSeconds = 0;
  String _currentPhase = 'Work';
  late int _currentSet;
  bool _isPaused = false;

  bool _audioFeedbackOn = true;
  bool _hapticFeedbackOn = true;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _currentPhase = 'Work';
    _currentSet = widget.startingSet;
    _currentSeconds =
        min(widget.timerData.workInterval * 60, widget.timerData.totalTime * 60);
    _initTtsAndStart();
  }

  Future<void> _initTtsAndStart() async {
    await _initTts();
    await Future.delayed(const Duration(milliseconds: 700));
    _startTimer();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {
      debugPrint("TTS initialization failed");
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _tts.stop();
    super.dispose();
  }

  Future<void> _speakTimerDetails() async {
    if (!_audioFeedbackOn) return;

    final workMin = widget.timerData.workInterval;
    final breakMin = widget.timerData.breakInterval;
    final sets = widget.timerData.totalSets;
    final name = widget.timerData.name;

    final message = 'Starting timer "$name". '
        'Work for $workMin minutes, '
        'then break for $breakMin minutes, '
        'repeat for $sets sets.';

    try {
      await _tts.stop();
      await _tts.speak(message);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  Future<void> _speak(String message) async {
    if (!_audioFeedbackOn) return;
    try {
      await _tts.stop();
      await _tts.speak(message);
    } catch (_) {}
  }

  void _startTimer() {
    if (_audioFeedbackOn) {
      if (_currentPhase == 'Work' && _currentSet == 1) {
        _speakTimerDetails();
      } else if (_currentPhase == 'Work' && _currentSet != 1) {
        _speak("Set $_currentSet: Work for ${widget.timerData.workInterval} minutes.");
      } else {
        _speak("Time for a break of ${widget.timerData.breakInterval} minutes.");
      }
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      if (_elapsedTotalSeconds >= widget.timerData.totalTime * 60 ||
          _currentSet > widget.timerData.totalSets) {
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
            if (_audioFeedbackOn) {
              if (_currentPhase == 'Work') {
                _speak("Work session completed. Take a short break.");
              } else {
                _speak("Break over. Starting the next set.");
              }
            }
            _togglePhase();
            _startTimer();
          }
        });
      }
    });
  }

  void _togglePhase() {
    if (_currentPhase == 'Break') {
      _currentSet++;
      if (_currentSet > widget.timerData.totalSets) {
        return;
      }
    }

    _currentPhase = (_currentPhase == 'Work') ? 'Break' : 'Work';

    final nextPhaseDuration = (_currentPhase == 'Work'
        ? widget.timerData.workInterval
        : widget.timerData.breakInterval) * 60;

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
    const Color primaryBlue = Color(0xFF007BFF);
    const Color breakGreen = Colors.green;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: textColor),
            onPressed: () {},
          ),
        ],
      ),

      // ✅ Fixed: Use `child:` instead of `body:`
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Current Timer Card
            Card(
              elevation: 0,
              color: cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: cardBorder),
              ),
              child: ListTile(
                title: const Text(
                  'Current Timer',
                  style: TextStyle(fontSize: 12, color: subtextColor),
                ),
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

            // Timer Display
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
                      'Set $_currentSet of ${widget.timerData.totalSets}',
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
                          'Total: ${_formatTime(widget.timerData.totalTime * 60)}',
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

            // Feedback Controls
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
            const SizedBox(height: 16),
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
