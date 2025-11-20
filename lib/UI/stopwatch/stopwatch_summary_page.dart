import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StopwatchSummaryPage extends StatelessWidget {
  final Duration? total;
  final List<Duration>? laps;
  final VoidCallback onClose;

  const StopwatchSummaryPage({
    super.key,
    required this.total,
    required this.laps,
    required this.onClose,
  });

  String format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds % 1000 ~/ 10).toString().padLeft(2, '0');
    return "$m:$s.$ms";
  }

  @override
  Widget build(BuildContext context) {
    if (total == null || laps == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Stopwatch Summary",
                  style: GoogleFonts.orbitron(
                      color: Colors.white, fontSize: 26, letterSpacing: 2)),

              const SizedBox(height: 20),

              Text("Total Time",
                  style: GoogleFonts.orbitron(color: Colors.blueAccent, fontSize: 16)),

              Text(format(total!),
                  style: GoogleFonts.orbitron(color: Colors.white, fontSize: 42)),

              const SizedBox(height: 30),

              Text("Laps (${laps!.length})",
                  style: GoogleFonts.orbitron(color: Colors.white70, fontSize: 16)),

              const SizedBox(height: 10),

              Expanded(
                child: laps!.isEmpty
                    ? Center(
                  child: Text("No laps recorded",
                      style: GoogleFonts.orbitron(color: Colors.grey)),
                )
                    : ListView.builder(
                  itemCount: laps!.length,
                  itemBuilder: (_, i) {
                    final lap = laps![i];
                    return ListTile(
                      title: Text("Lap ${i + 1}",
                          style: GoogleFonts.orbitron(color: Colors.white)),
                      trailing: Text(format(lap),
                          style: GoogleFonts.orbitron(color: Colors.blueAccent)),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: ElevatedButton(
                  onPressed: onClose,
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
