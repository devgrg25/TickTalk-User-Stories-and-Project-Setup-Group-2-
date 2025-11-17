import 'package:flutter/services.dart';

class HapticsService {
  HapticsService._();
  static final HapticsService instance = HapticsService._();

  Future<void> countdownPulse() async {
    await HapticFeedback.mediumImpact();
  }

  Future<void> finishLong() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.heavyImpact();
  }
}
