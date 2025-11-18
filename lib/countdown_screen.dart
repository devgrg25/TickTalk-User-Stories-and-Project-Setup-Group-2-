// countdown_screen.dart
import 'package:flutter/material.dart';
import '../timer_models/timer_model.dart';

class CountdownScreen extends StatelessWidget {
  final TimerData timerData;
  final VoidCallback? onBack;

  const CountdownScreen({
    super.key,
    required this.timerData,
    this.onBack,
  });

  int get _workSec => timerData.workInterval * 60;
  int get _breakSec => timerData.breakInterval * 60;
  int get _cycleSec => _workSec + _breakSec;
  int get _totalSets => timerData.totalSets;

  /// Full duration assuming Work + Break for each set,
  /// with NO break after the last work interval.
  int get _totalDurationSec =>
      _workSec * _totalSets + _breakSec * (_totalSets - 1);

  String _format(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    const Color cardBackground = Color(0xFFF9FAFB);
    const Color cardBorder = Color(0xFFE5E7EB);
    const Color textColor = Colors.black;
    const Color subtextColor = Colors.black54;

    final int totalSec = _totalDurationSec;

    // Remaining total from TimerData (authoritative)
    final int remainingTotal =
    timerData.totalTime.clamp(0, totalSec); // safe clamp

    final int elapsedTotal = (totalSec - remainingTotal).clamp(0, totalSec);

    // --- derive set / phase info from elapsed ---
    final int currentSet = (elapsedTotal ~/ _cycleSec) + 1;
    final int secondsIntoSet = elapsedTotal % _cycleSec;
    final bool inWorkPhase = secondsIntoSet < _workSec;

    final String phaseLabel = inWorkPhase ? "Work" : "Break";

    final int phaseRemaining = inWorkPhase
        ? _workSec - secondsIntoSet
        : _breakSec - (secondsIntoSet - _workSec);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Active Timer',
          style: TextStyle(color: textColor),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: onBack,
        ),
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
                  side: const BorderSide(color: cardBorder),
                ),
                child: ListTile(
                  title: const Text(
                    'Current Timer',
                    style: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                  subtitle: Text(
                    timerData.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ---- MAIN TIMER DISPLAY ----
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
                        'Set $currentSet of $_totalSets',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Remaining time in *this phase*
                      Text(
                        _format(phaseRemaining.clamp(0, totalSec)),
                        style: const TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'Phase: $phaseLabel',
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'Elapsed: ${_format(elapsedTotal)} / Total: ${_format(totalSec)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor.withValues(alpha: 0.7),
                        ),
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
