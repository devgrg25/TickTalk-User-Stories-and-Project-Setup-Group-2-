import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../logic/timer/timer_controller.dart';
import '../theme/app_background.dart';
import '../widgets/glass_button.dart';

class CountdownPage extends StatefulWidget {
  final TimerController controller;
  final VoidCallback onExit;

  const CountdownPage({
    super.key,
    required this.controller,
    required this.onExit,
  });

  @override
  State<CountdownPage> createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();

    /// Refresh UI every 200ms for smoother ticking text
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) setState(() {});
    });

    /// If timer finishes while user is on this screen → exit automatically
    widget.controller.onTimerComplete = () {
      if (mounted) {
        widget.onExit();
      }
    };
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.controller.remainingSeconds;
    final display = TimerController.format(remaining ?? 0);

    final interval = widget.controller.current;
    final title = interval?.name ?? "TickTalk Timer";

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),

              /// Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 26,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 80),

              /// Countdown
              Text(
                display,
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  color: Colors.blueAccent,
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      color: Colors.blueAccent.withOpacity(0.8),
                      blurRadius: 25,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              /// Stop Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.controller.isRunning)
                    GlassButton(
                      text: "Pause",
                      onPressed: () {
                        widget.controller.pause();
                        setState(() {});
                      },
                    ),

                  if (!widget.controller.isRunning && !widget.controller.isStopped)
                    GlassButton(
                      text: "Resume",
                      onPressed: () {
                        widget.controller.resume();
                        setState(() {});
                      },
                    ),

                  const SizedBox(width: 12),

                  GlassButton(
                    text: "Stop Timer",
                    onPressed: () {
                      widget.controller.stop();
                      widget.onExit();
                    },
                  ),
                ],
              ),


              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
