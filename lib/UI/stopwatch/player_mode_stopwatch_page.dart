import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../logic/stopwatch/stopwatch_controller.dart';
import '../widgets/glass_button.dart';

class PlayerModeStopwatchPage extends StatefulWidget {
  final int playerCount;
  final VoidCallback onExit;

  const PlayerModeStopwatchPage({
    super.key,
    required this.playerCount,
    required this.onExit,
  });

  @override
  State<PlayerModeStopwatchPage> createState() => _PlayerModeStopwatchPageState();
}

class _PlayerModeStopwatchPageState extends State<PlayerModeStopwatchPage> {
  List<StopwatchController> controllers = [];
  List<List<Duration>> laps = [];
  Timer? ticker;

  @override
  void initState() {
    super.initState();
    _initPlayers();
  }

  @override
  void didUpdateWidget(covariant PlayerModeStopwatchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playerCount != widget.playerCount) {
      _disposePlayers();
      _initPlayers();
    }
  }

  void _initPlayers() {
    controllers = List.generate(widget.playerCount, (_) => StopwatchController());
    laps = List.generate(widget.playerCount, (_) => []);

    ticker?.cancel();
    ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
  }

  void _disposePlayers() {
    for (var c in controllers) {
      c.stop();
    }
    controllers.clear();
    laps.clear();
    ticker?.cancel();
    ticker = null;
  }

  @override
  void dispose() {
    _disposePlayers();
    super.dispose();
  }

  String format(int ms) => StopwatchController.format(ms);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              "Player Mode (${widget.playerCount} Players)",
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 22,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                itemCount: controllers.length, // use controllers length for safety
                itemBuilder: (_, i) {
                  final c = controllers[i];
                  final lapList = laps[i];

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Player ${i + 1}",
                          style: GoogleFonts.orbitron(
                            color: Colors.blueAccent,
                            fontSize: 18,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          format(c.elapsedMs),
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            if (!c.isPaused && c.elapsedMs == 0)
                              GlassButton(text: "Start", onPressed: () => c.start()),

                            if (!c.isPaused && c.elapsedMs > 0)
                              GlassButton(text: "Pause", onPressed: () => c.pause()),

                            if (c.isPaused)
                              GlassButton(text: "Resume", onPressed: () => c.resume()),

                            if (c.elapsedMs > 0)
                              GlassButton(
                                text: "Lap",
                                onPressed: () {
                                  setState(() {
                                    lapList.insert(
                                      0,
                                      Duration(milliseconds: c.elapsedMs),
                                    );
                                  });
                                },
                              ),

                            if (c.elapsedMs > 0)
                              GlassButton(
                                text: "Stop",
                                onPressed: () {
                                  c.stop();
                                  c.reset();
                                  setState(() => lapList.clear());
                                },
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        if (lapList.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Laps",
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              ...lapList.map(
                                    (lap) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    format(lap.inMilliseconds),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: widget.onExit,
              child: const Text("Exit Player Mode"),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
