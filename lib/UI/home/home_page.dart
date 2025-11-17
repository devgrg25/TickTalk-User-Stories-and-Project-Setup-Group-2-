import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../logic/timer/timer_manager.dart';
import '../../../logic/timer/timer_controller.dart';
import '../theme/app_background.dart';
import '../widgets/animated_page_title.dart';
import '../timer/countdown_page.dart';

import 'package:ticktalk_app/logic/haptics/haptics_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StreamSubscription? sub;

  @override
  void initState() {
    super.initState();

    // Listen for timer changes
    sub = TimerManager.instance.onChange.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  void _openCountdown(ActiveTimer t) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CountdownPage(
          controller: t.controller,
          onExit: () => Navigator.pop(context),
        ),
      ),
    );
  }

  // 🔔 Test haptic vibration
  Future<void> _testVibration() async {
    debugPrint("Sending haptic test pulse...");
    HapticsService.instance.countdownPulse();
  }

  @override
  Widget build(BuildContext context) {
    final timers = TimerManager.instance.timers;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),

              Text(
                "Welcome to",
                style: GoogleFonts.orbitron(
                  color: Colors.white70,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 4),
              const AnimatedPageTitle(title: "TickTalk"),
              const SizedBox(height: 30),

              Expanded(
                child: timers.isEmpty
                    ? Center(
                  child: Text(
                    "No active timers",
                    style: GoogleFonts.orbitron(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                )
                    : ListView.builder(
                  itemCount: timers.length,
                  itemBuilder: (_, i) {
                    final t = timers[i];
                    final current = t.controller.current;
                    final isFinished = t.finished || current == null;

                    final subtitle = isFinished
                        ? "Finished"
                        : "${current.name} — "
                        "${TimerController.format(t.controller.remainingSeconds)}";

                    return ListTile(
                      onTap: () => _openCountdown(t),
                      title: Text(
                        t.name,
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text(
                        subtitle,
                        style: TextStyle(
                          color: isFinished
                              ? Colors.redAccent
                              : Colors.white70,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _testVibration,
        child: const Icon(Icons.vibration),
      ),
    );
  }
}
