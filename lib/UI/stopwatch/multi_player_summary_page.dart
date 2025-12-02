import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../logic/stopwatch/player_mode_manager.dart';

class MultiPlayerSummaryPage extends StatelessWidget {
  final List<PlayerStopwatchSummary> summaries;
  final VoidCallback onClose;

  const MultiPlayerSummaryPage({
    super.key,
    required this.summaries,
    required this.onClose,
  });

  String format(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              "Player Summary",
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: summaries.length,
                itemBuilder: (_, i) {
                  final s = summaries[i];

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Player ${s.number}",
                          style: GoogleFonts.orbitron(
                            color: Colors.blueAccent,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          "Total: ${format(s.total)}",
                          style: const TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        const SizedBox(height: 12),

                        if (s.laps.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Laps", style: TextStyle(color: Colors.white70)),
                              const SizedBox(height: 6),
                              ...s.laps.map(
                                    (lap) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    format(lap),
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

            ElevatedButton(
              onPressed: onClose,
              child: const Text("Close"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
