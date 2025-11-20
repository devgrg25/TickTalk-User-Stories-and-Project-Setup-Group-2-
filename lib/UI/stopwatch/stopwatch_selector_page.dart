import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../logic/stopwatch/normal_stopwatch_shared_controller.dart';

class StopwatchSelectorPage extends StatefulWidget {
  final void Function(int) onNavigate;
  final NormalStopwatchSharedController controller;

  final void Function(Duration total, List<Duration> laps) onStopFromPreview;

  const StopwatchSelectorPage({
    super.key,
    required this.onNavigate,
    required this.controller,
    required this.onStopFromPreview,
  });

  @override
  State<StopwatchSelectorPage> createState() => _StopwatchSelectorPageState();
}

class _StopwatchSelectorPageState extends State<StopwatchSelectorPage> {

  @override
  void initState() {
    super.initState();

    // Rebuild UI on tick (100 ms)
    widget.controller.onTick = () {
      if (mounted) setState(() {});
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            Text(
              "STOPWATCH MODES",
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 22,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 30),

            // NORMAL STOPWATCH TILE + PREVIEW
            GestureDetector(
              onTap: () => widget.onNavigate(5),
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blueAccent, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Normal Stopwatch",
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      NormalStopwatchSharedController.format(c.elapsedMs),
                      style: GoogleFonts.orbitron(
                        color: Colors.blueAccent,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (!c.isRunning)
                          _miniButton("Start", () {
                            c.start();
                            setState(() {});
                          }),

                        if (c.isRunning && !c.isPaused)
                          _miniButton("Pause", () {
                            c.pause();
                            setState(() {});
                          }),

                        if (c.isPaused)
                          _miniButton("Resume", () {
                            c.resume();
                            setState(() {});
                          }),

                        if (c.isRunning)
                          _miniButton("Lap", () {
                            c.lap();
                            setState(() {}); // <-- REQUIRED
                          }),

                        if (c.isRunning)
                          _miniButton("Stop", () {
                            final total = c.elapsed;
                            final lapsCopy = List<Duration>.from(c.laps);

                            c.stop();
                            c.reset();

                            widget.onStopFromPreview(total, lapsCopy);
                          }),
                      ],
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            ListTile(
              leading: const Icon(Icons.group, color: Colors.white),
              title: Text("Player Mode",
                  style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16)),
              subtitle: const Text(
                "Track up to 6 players independently",
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () => widget.onNavigate(7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent.withOpacity(0.2),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(text),
    );
  }
}
