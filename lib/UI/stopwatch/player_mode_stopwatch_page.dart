import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../logic/stopwatch/player_mode_manager.dart';
import '../../../logic/stopwatch/stopwatch_controller.dart';
import '../widgets/glass_button.dart';
import 'multi_player_summary_page.dart';

class PlayerModeStopwatchPage extends StatefulWidget {
  final int playerCount;
  final VoidCallback onExit;

  const PlayerModeStopwatchPage({
    super.key,
    required this.playerCount,
    required this.onExit,
  });

  @override
  State<PlayerModeStopwatchPage> createState() =>
      _PlayerModeStopwatchPageState();
}

class _PlayerModeStopwatchPageState extends State<PlayerModeStopwatchPage> {
  final pm = PlayerModeManager.instance;
  Timer? ticker;

  @override
  void initState() {
    super.initState();

    pm.createPlayers(widget.playerCount);

    // ⭐ Auto-summary callback
    pm.onAllPlayersStopped = (summaries) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MultiPlayerSummaryPage(
            summaries: summaries,
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      );
    };

    ticker = Timer.periodic(
      const Duration(milliseconds: 100),
          (_) => mounted ? setState(() {}) : null,
    );
  }

  @override
  void didUpdateWidget(covariant PlayerModeStopwatchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playerCount != oldWidget.playerCount) {
      pm.createPlayers(widget.playerCount);
    }
  }

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
  }

  String format(int ms) => StopwatchController.format(ms);

  @override
  Widget build(BuildContext context) {
    final players = pm.controllers;

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

            // --------------------------
            // Start All + Stop All
            // --------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GlassButton(
                  text: "Start All",
                  onPressed: pm.startAll,
                ),
                const SizedBox(width: 16),
                GlassButton(
                  text: "Stop All",
                  onPressed: pm.stopAll,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --------------------------
            // PLAYER LIST
            // --------------------------
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (_, i) {
                  final c = players[i];
                  final lapList = pm.laps[i];

                  return Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    padding: const EdgeInsets.all(16),
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
                        const SizedBox(height: 8),

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
                          children: [
                            if (!c.isRunning && c.elapsedMs == 0)
                              GlassButton(
                                text: "Start",
                                onPressed: () => pm.startPlayer(i),
                              ),

                            if (c.isRunning && !c.isPaused)
                              GlassButton(
                                text: "Pause",
                                onPressed: () => pm.pausePlayer(i),
                              ),

                            if (c.isPaused)
                              GlassButton(
                                text: "Resume",
                                onPressed: () => pm.resumePlayer(i),
                              ),

                            if (c.elapsedMs > 0)
                              GlassButton(
                                text: "Lap",
                                onPressed: () => setState(() {
                                  pm.lapPlayer(i);
                                }),
                              ),

                            if (c.elapsedMs > 0)
                              GlassButton(
                                text: "Stop",
                                onPressed: () => pm.stopPlayer(i),
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        if (lapList.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Laps",
                                  style: TextStyle(color: Colors.white70)),
                              const SizedBox(height: 6),
                              ...lapList.map(
                                    (lap) => Padding(
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    format(lap.inMilliseconds),
                                    style:
                                    const TextStyle(color: Colors.white),
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

            const SizedBox(height: 10),
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
