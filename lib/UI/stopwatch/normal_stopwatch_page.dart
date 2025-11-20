import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../logic/stopwatch/normal_stopwatch_shared_controller.dart';
import '../widgets/glass_button.dart';

class NormalStopwatchPage extends StatefulWidget {
  final NormalStopwatchSharedController controller;
  final void Function(Duration total, List<Duration> laps) onStop;

  const NormalStopwatchPage({
    super.key,
    required this.controller,
    required this.onStop,
  });

  @override
  State<NormalStopwatchPage> createState() => _NormalStopwatchPageState();
}

class _NormalStopwatchPageState extends State<NormalStopwatchPage> {
  Timer? ticker;

  @override
  void initState() {
    super.initState();

    ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
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
              "Stopwatch",
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 26,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 40),

            Text(
              NormalStopwatchSharedController.format(c.elapsedMs),
              style: GoogleFonts.orbitron(
                color: Colors.blueAccent,
                fontSize: 64,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.blueAccent.withOpacity(0.6),
                    blurRadius: 30,
                  )
                ],
              ),
            ),

            const SizedBox(height: 40),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (!c.isRunning) GlassButton(text: "Start", onPressed: c.start),
                if (c.isRunning && !c.isPaused)
                  GlassButton(text: "Pause", onPressed: c.pause),
                if (c.isPaused) GlassButton(text: "Resume", onPressed: c.resume),
                if (c.isRunning) GlassButton(text: "Lap", onPressed: c.lap),
                if (c.isRunning)
                  GlassButton(
                    text: "Stop",
                    onPressed: () {
                      final total = c.elapsed;
                      final lapsCopy = List<Duration>.from(c.laps);

                      c.stop();
                      c.reset();
                      widget.onStop(total, lapsCopy);
                    },
                  ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: c.laps.isEmpty
                  ? const Center(
                child: Text(
                  "No laps yet",
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: c.laps.length,
                itemBuilder: (_, i) {
                  final lap = c.laps[i];
                  return ListTile(
                    title: Text(
                      "Lap ${c.laps.length - i}",
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: Text(
                      "${lap.inMinutes}:${lap.inSeconds % 60}",
                      style: const TextStyle(color: Colors.blueAccent),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
