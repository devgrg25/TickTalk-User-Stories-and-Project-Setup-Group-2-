import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlayerCountSelectorPage extends StatelessWidget {
  final void Function(int count) onSelectPlayers;

  const PlayerCountSelectorPage({super.key, required this.onSelectPlayers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            Text(
              "Select Number of Players",
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 22,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                padding: const EdgeInsets.all(16),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: List.generate(6, (i) {
                  final number = i + 1;
                  return GestureDetector(
                    onTap: () => onSelectPlayers(number),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blueAccent, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          "$number",
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            )
          ],
        ),
      ),
    );
  }
}
