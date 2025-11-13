import 'dart:math';
import 'package:flutter/material.dart';
import '../models/timer_model.dart';
import 'base/voice_controller_base.dart';

/// Voice controller for all timer-related commands.
/// Fully guided conversational flow for creating timers.
class TimerVoiceController extends VoiceControllerBase {
  // Callbacks wired from MainPage
  Function(TimerData)? onCreateTimer;
  Function(TimerData)? onStartTimer;
  VoidCallback? onStopTimer;
  VoidCallback? onPause;
  VoidCallback? onResume;
  Function(int index)? onNavigateToTab;
  Function(bool isInterval)? onSetVoiceTimerType;// 👈 NEW: tells UI what to prefill
  VoidCallback? onOpenTimer; // 👈 NEW: opens timer tab when user says "create timer"


  // State for guided creation
  _TimerFlowState _state = _TimerFlowState.idle;
  _PendingTimer? _pending;

  @override
  Future<void> handleCommand(String raw) async {
    final input = raw.trim().toLowerCase();
    if (input.isEmpty) return;
    debugPrint("🎙 TimerVoiceController received: $input");

    // Continue ongoing flow if in progress
    if (_state != _TimerFlowState.idle && _pending != null) {
      await _continueFlow(input);
      return;
    }

    // --- Global controls ---
    if (input.contains('pause')) {
      await speak('Pausing timer.');
      onPause?.call();
      return;
    }

    if (input.contains('resume') || input.contains('continue')) {
      await speak('Resuming timer.');
      onResume?.call();
      return;
    }

    if (input.contains('stop') || input.contains('cancel timer')) {
      await speak('Stopping timer.');
      onStopTimer?.call();
      return;
    }

    // --- Creation flow ---
    final mentionsTimer = input.contains('timer');
    final createWords = ['create', 'make', 'start', 'set up', 'setup', 'add'];
    final mentionsCreate = createWords.any(input.contains);

    if (mentionsTimer && mentionsCreate) {
      // ✅ Step 1: tell UI to switch to Timer tab (via MainPage callback)
      onOpenTimer?.call();

      // ✅ Step 2: wait a short delay so UI finishes switching
      await Future.delayed(const Duration(milliseconds: 500));

      // ✅ Step 3: begin normal guided flow (now on correct screen)
      _beginFlow();
      return;
    }
    // --- Direct navigation phrases like "go to timer" or "open timer" ---
    if (mentionsTimer && (input.contains('go to') || input.contains('open'))) {
      onOpenTimer?.call();
      await speak('Opening timer setup.');
      return;
    }




    // --- Quick one-shot timers like "10 minute timer" ---
    final quickMatch =
    RegExp(r'(\d+)\s*(minute|min|minutes|mins)').firstMatch(input);
    if (quickMatch != null) {
      final mins = int.tryParse(quickMatch.group(1)!);
      if (mins != null && mins > 0) {
        final timer = TimerData(
          id: DateTime.now().toIso8601String(),
          name: 'Quick Timer',
          totalTime: mins * 60,
          workInterval: mins,
          breakInterval: 0,
          totalSets: 1,
          currentSet: 1,
        );
        await speak('Starting a $mins minute timer.');
        onCreateTimer?.call(timer);
        onStartTimer?.call(timer);
        return;
      }
    }

    await speak(
      'I can help you create or control timers. '
          'Say, "create timer", "create interval timer", or "10 minute timer".',
    );
  }

  // =====================================================
  // FLOW ENTRY
  // =====================================================

  void _beginFlow() async {
    _pending = _PendingTimer();
    _state = _TimerFlowState.awaitingType;

    // 👇 Navigate to the TimerModeSelector screen first
    onNavigateToTab?.call(1);

    // 👇 Wait a moment for the UI to render, then speak
    await Future.delayed(const Duration(milliseconds: 400));

    await speak(
      'Okay, let\'s create a timer. '
          'Would you like a normal timer or an interval timer? '
          'Tap the blue bar and say "normal timer" or "interval timer".',
    );
  }


  // =====================================================
  // FLOW CONTINUATION
  // =====================================================

  Future<void> _continueFlow(String input) async {
    switch (_state) {
      case _TimerFlowState.awaitingType:
        await _handleType(input);
        break;
      case _TimerFlowState.awaitingName:
        await _handleName(input);
        break;
      case _TimerFlowState.awaitingTotalMinutes:
        await _handleTotalMinutes(input);
        break;
      case _TimerFlowState.awaitingWorkMinutes:
        await _handleWork(input);
        break;
      case _TimerFlowState.awaitingBreakMinutes:
        await _handleBreak(input);
        break;
      case _TimerFlowState.awaitingSets:
        await _handleSets(input);
        break;
      case _TimerFlowState.confirming:
        await _handleConfirm(input);
        break;
      default:
        _reset();
        break;
    }
  }

  // =====================================================
  // EACH STEP HANDLER
  // =====================================================

  Future<void> _handleType(String input) async {
    if (input.contains('normal')) {
      _pending!.isInterval = false;
      _state = _TimerFlowState.awaitingName;

      // 👇 Navigate to Normal Timer screen (index 4)
      onNavigateToTab?.call(4);

      await Future.delayed(const Duration(milliseconds: 400));
      await speak(
        'Normal timer selected. Please enter the timer name and duration.',
      );
      return;
    }

    if (input.contains('interval')) {
      _pending!.isInterval = true;
      _state = _TimerFlowState.awaitingName;

      // 👇 Navigate to Interval Timer screen (index 5)
      onNavigateToTab?.call(5);

      await Future.delayed(const Duration(milliseconds: 400));
      await speak(
        'Interval timer selected. Please set your work and break intervals.',
      );
      return;
    }

    await speak(
      'I did not catch that. Tap the blue bar and say "normal timer" or "interval timer".',
    );
  }




  Future<void> _handleName(String input) async {
    final name = _cleanName(input);
    _pending!.name = name;

    if (_pending!.isInterval) {
      _state = _TimerFlowState.awaitingWorkMinutes;
      await speak('Great. Tap the blue bar and say how many minutes for each work interval.');
    } else {
      _state = _TimerFlowState.awaitingTotalMinutes;
      await speak('Great. Tap the blue bar and say the total minutes for this timer.');
    }
  }

  Future<void> _handleTotalMinutes(String input) async {
    final minutes = _extractNumber(input);
    if (minutes == null || minutes <= 0) {
      await speak('Please tap the blue bar and say the total duration in minutes, like "25".');
      return;
    }

    _pending!.totalMinutes = minutes;
    _state = _TimerFlowState.confirming;
    await _speakSummary();
  }

  Future<void> _handleWork(String input) async {
    final minutes = _extractNumber(input);
    if (minutes == null || minutes <= 0) {
      await speak('Please tap the blue bar and say the work minutes, for example "30".');
      return;
    }

    _pending!.workMinutes = minutes;
    _state = _TimerFlowState.awaitingBreakMinutes;
    await speak('Okay. Tap the blue bar and say how many minutes for each break.');
  }

  Future<void> _handleBreak(String input) async {
    final minutes = _extractNumber(input);
    if (minutes == null || minutes < 0) {
      await speak('Please tap the blue bar and say the break minutes, like "5". You can also say zero.');
      return;
    }

    _pending!.breakMinutes = minutes;
    _state = _TimerFlowState.awaitingSets;
    await speak('Got it. Tap the blue bar and say how many sets you want.');
  }

  Future<void> _handleSets(String input) async {
    final sets = _extractNumber(input);
    if (sets == null || sets <= 0) {
      await speak('Please tap the blue bar and say a valid number of sets, for example "4".');
      return;
    }

    _pending!.sets = sets;
    _state = _TimerFlowState.confirming;
    await _speakSummary();
  }

  Future<void> _handleConfirm(String input) async {
    if (input.contains('confirm') || input.contains('yes') || input.contains('save')) {
      final timer = _buildTimer();
      if (timer == null) {
        await speak(
          'Sorry, something went wrong while creating the timer. Let\'s try again later.',
        );
        _reset();
        return;
      }

      // ✅ Actually create & start the timer in the app
      onCreateTimer?.call(timer);
      onStartTimer?.call(timer);

      // 👇 Navigate back to home so user sees the active timer
      onNavigateToTab?.call(0);

      await speak('Timer "${timer.name}" created and started.');
      _reset();
      return;
    }

    if (input.contains('cancel') || input.contains('no') || input.contains('stop')) {
      await speak('Okay, I cancelled this timer setup.');
      _reset();
      return;
    }

    await speak(
      'Please say "confirm" to save and start this timer, or "cancel" to discard it.',
    );
  }


  // =====================================================
  // BUILD & SUMMARY
  // =====================================================

  Future<void> _speakSummary() async {
    final p = _pending!;
    if (p.isInterval) {
      if (p.name != null && p.workMinutes != null && p.breakMinutes != null && p.sets != null) {
        await speak(
          'Here is your interval timer: '
              '${p.name}, ${p.workMinutes} minutes work, '
              '${p.breakMinutes} minutes break, ${p.sets} sets. '
              'Tap the blue bar and say "confirm" to start it, or "cancel" to discard.',
        );
      } else {
        await speak('I am missing some details. Say "create timer" to begin again.');
        _reset();
      }
    } else {
      if (p.name != null && p.totalMinutes != null) {
        await speak(
          'Here is your normal timer: '
              '${p.name}, ${p.totalMinutes} minutes total. '
              'Tap the blue bar and say "confirm" to start it, or "cancel" to discard.',
        );
      } else {
        await speak('I am missing some details. Say "create timer" to begin again.');
        _reset();
      }
    }
  }

  TimerData? _buildTimer() {
    final p = _pending;
    if (p == null || p.name == null) return null;

    if (p.isInterval) {
      if (p.workMinutes == null || p.breakMinutes == null || p.sets == null) return null;

      final work = p.workMinutes!;
      final brk = p.breakMinutes!;
      final sets = p.sets!;
      final totalMinutes = (work * sets) + (brk * max(0, sets - 1));

      return TimerData(
        id: DateTime.now().toIso8601String(),
        name: p.name!,
        totalTime: (totalMinutes * 60).toInt(),
        workInterval: work,
        breakInterval: brk,
        totalSets: sets,
        currentSet: 1,
      );
    } else {
      if (p.totalMinutes == null) return null;
      final mins = p.totalMinutes!;
      return TimerData(
        id: DateTime.now().toIso8601String(),
        name: p.name!,
        totalTime: mins * 60,
        workInterval: mins,
        breakInterval: 0,
        totalSets: 1,
        currentSet: 1,
      );
    }
  }

  // =====================================================
  // HELPERS
  // =====================================================

  int? _extractNumber(String input) {
    final m = RegExp(r'(\d+)').firstMatch(input);
    if (m == null) return null;
    return int.tryParse(m.group(1)!);
  }

  String _cleanName(String input) {
    var name = input;
    for (final p in ['call it ', 'name it ', 'named ', 'timer ']) {
      if (name.startsWith(p)) {
        name = name.substring(p.length);
        break;
      }
    }
    return name.trim().isEmpty ? 'My Timer' : name.trim();
  }

  void _reset() {
    _state = _TimerFlowState.idle;
    _pending = null;
  }
}

enum _TimerFlowState {
  idle,
  awaitingType,
  awaitingName,
  awaitingTotalMinutes,
  awaitingWorkMinutes,
  awaitingBreakMinutes,
  awaitingSets,
  confirming,
}

class _PendingTimer {
  String? name;
  bool isInterval = false;
  int? totalMinutes; // for normal timer
  int? workMinutes;
  int? breakMinutes;
  int? sets;
}
extension TimerVoiceFlow on TimerVoiceController {
  bool get isInFlow => _state != _TimerFlowState.idle;
  // =====================================================
  // PREFILL HELPER (for CreateTimerScreen)
  // =====================================================
  TimerData? pendingAsTimerData() {
    final p = _pending;
    if (p == null || p.name == null) return null;

    if (p.isInterval) {
      final work = p.workMinutes ?? 0;
      final brk = p.breakMinutes ?? 0;
      final sets = p.sets ?? 1;
      final total = (work * sets) + (brk * (sets - 1));

      return TimerData(
        id: DateTime.now().toIso8601String(),
        name: p.name!,
        totalTime: total * 60,
        workInterval: work,
        breakInterval: brk,
        totalSets: sets,
        currentSet: 1,
      );
    } else {
      final total = p.totalMinutes ?? 0;
      return TimerData(
        id: DateTime.now().toIso8601String(),
        name: p.name!,
        totalTime: total * 60,
        workInterval: total,
        breakInterval: 0,
        totalSets: 1,
        currentSet: 1,
      );
    }
  }



}

