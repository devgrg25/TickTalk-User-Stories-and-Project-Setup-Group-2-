import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 't2_us1.dart';
import 't3_us1.dart';

/// T1_US1: Handles first-launch voice onboarding logic.
/// Voice Recognition for “Start Tutorial”, “Skip”, and “Repeat”.
class T1US1Manager {
  final stt.SpeechToText _stt = stt.SpeechToText();
  final T2US1TTS ttsManager;
  final T3US1Persistence persistence;

  bool _isListening = false;
  bool _initialized = false;

  T1US1Manager({
    required this.ttsManager,
    required this.persistence,
  });

  /// Initialize Speech-to-Text with error/status logging
  Future<void> init() async {
    _initialized = await _stt.initialize(
      onError: (err) => debugPrint("❌ Speech init error: $err"),
      onStatus: (status) => debugPrint("🎙️ Speech status: $status"),
    );

    if (!_initialized) {
      debugPrint("⚠️ Speech recognition not available.");
    } else {
      debugPrint("✅ Speech recognition ready.");
    }
  }

  /// Start listening for user commands
  Future<void> startListening(BuildContext context) async {
    if (!_initialized) {
      debugPrint("⚠️ Tried to start listening before init.");
      return;
    }

    if (_isListening) {
      debugPrint("⏳ Already listening...");
      return;
    }

    _isListening = true;
    debugPrint("🎧 Listening for voice commands...");

    await _stt.listen(
      onResult: (res) async {
        final cmd = res.recognizedWords.toLowerCase().trim();
        debugPrint("🗣️ Heard: $cmd");

        if (cmd.isEmpty) return;

        if (cmd.contains('start tutorial') || cmd.contains('start')) {
          await _handleCommand(context, route: '/onboarding');
        } else if (cmd.contains('skip')) {
          await persistence.setWelcomePlayed();
          await _handleCommand(context, route: '/home');
        } else if (cmd.contains('repeat')) {
          await _stt.stop();
          await ttsManager.playWelcomeMessage(onComplete: () {
            startListening(context);
          });
        }
      },
      listenFor: const Duration(seconds: 15), // more forgiving
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
      listenMode: stt.ListenMode.confirmation,
      localeId: 'en_US',
    );
  }

  /// Common logic for handling navigation commands
  Future<void> _handleCommand(BuildContext context, {required String route}) async {
    debugPrint("➡️ Navigating to: $route");

    await _stt.stop();
    await ttsManager.stop();
    HapticFeedback.mediumImpact();

    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, route);
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _stt.stop();
      _isListening = false;
      debugPrint("🛑 Stopped listening.");
    }
  }

  void dispose() {
    _stt.cancel();
  }
}
