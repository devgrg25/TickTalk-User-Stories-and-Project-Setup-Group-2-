import 'dart:math' as math;
import 'package:flutter/material.dart';

class VoiceMicBar extends StatefulWidget {
  final bool isListening;
  final VoidCallback onTap;

  const VoiceMicBar({
    super.key,
    required this.isListening,
    required this.onTap,
  });

  @override
  State<VoiceMicBar> createState() => _VoiceMicBarState();
}

class _VoiceMicBarState extends State<VoiceMicBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12), // slow background animation
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = (math.sin(_controller.value * math.pi * 2) + 1) / 2;

        // Animated background gradient
        final bg1 = Color.lerp(
          const Color(0xFF1A1A1A),
          const Color(0xFF2A1B3F),
          t,
        )!;
        final bg2 = Color.lerp(
          const Color(0xFF0F0F0F),
          const Color(0xFF1A1A1A),
          t,
        )!;

        // Glow color for orb
        final glowColor = Color.lerp(
          const Color(0xFF7A3FFF),
          const Color(0xFF00E5FF),
          t,
        )!;

        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [bg1, bg2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFF2A2A2A),
                      Color(0xFF0F0F0F),
                    ],
                  ),
                  boxShadow: widget.isListening
                      ? [
                    BoxShadow(
                      color: glowColor.withOpacity(0.45),
                      blurRadius: 42,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: glowColor.withOpacity(0.20),
                      blurRadius: 70,
                      spreadRadius: 14,
                    ),
                  ]
                      : [],
                ),
                child: Icon(
                  widget.isListening ? Icons.mic : Icons.mic_none,
                  size: 36,
                  color: Colors.white.withOpacity(
                    widget.isListening ? 1.0 : 0.65,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
