// lib/onboarding/welcome_screen.dart
import 'package:flutter/material.dart';
import 't1_us1.dart';
import 't2_us1.dart';
import 't3_us1.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final T1US1Manager t1;
  late final T2US1TTS t2;
  late final T3US1Persistence t3;

  @override
  void initState() {
    super.initState();
    t2 = T2US1TTS();
    t3 = T3US1Persistence();
    t1 = T1US1Manager(ttsManager: t2, persistence: t3);

    _initSequence();
  }

  Future<void> _initSequence() async {
    await t2.init();
    await t1.init();

    // Give TTS engine time to fully initialize before speaking
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 600));
      await t2.playWelcomeMessage(onComplete: () {
        t1.startListening(context);
      });
    });
  }


  @override
  void dispose() {
    t1.dispose();
    t2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Welcome")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Voice-Guided Tutorial",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Say 'start tutorial', 'skip', or 'repeat'. You can also use the buttons below.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            OnboardingFallbackButtons(
              onStart: () => Navigator.pushReplacementNamed(context, '/onboarding'),
              onSkip: () async {
                await t3.setWelcomePlayed();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/home');
              },
              onRepeat: () => t2.playWelcomeMessage(
                onComplete: () => t1.startListening(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
