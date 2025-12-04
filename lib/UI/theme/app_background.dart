import 'dart:math';
import 'package:flutter/material.dart';

class AppBackground extends StatefulWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with TickerProviderStateMixin {
  late AnimationController driftCtrl;
  late AnimationController gridCtrl;
  late AnimationController pulseCtrl;

  @override
  void initState() {
    super.initState();

    driftCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat(reverse: true);

    gridCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    driftCtrl.dispose();
    gridCtrl.dispose();
    pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([driftCtrl, gridCtrl, pulseCtrl]),
      builder: (_, __) {
        return CustomPaint(
          painter: _AuroraPainter(
            drift: driftCtrl.value,
            gridShift: gridCtrl.value,
            pulse: pulseCtrl.value,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double drift;
  final double gridShift;
  final double pulse;

  _AuroraPainter({
    required this.drift,
    required this.gridShift,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // ---- Much darker base ----
    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF000000),
          Color(0xFF05020F),
        ],
      ).createShader(rect);

    canvas.drawRect(rect, base);

    // ---- Aurora Glow Layer 1 (very subtle purple) ----
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.softLight
        ..shader = RadialGradient(
          center: Alignment(-0.4 + drift * 0.15, -0.3),
          radius: 1.0,
          colors: [
            const Color.fromRGBO(138, 43, 226, 0.25),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    // ---- Aurora Glow Layer 2 (darker cyan) ----
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = RadialGradient(
          center: Alignment(0.6 - drift * 0.15, 0.1),
          radius: 1.1,
          colors: [
            const Color.fromRGBO(0, 191, 255, 0.18),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    // ---- Aurora Glow Layer 3 (soft green) ----
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.overlay
        ..shader = RadialGradient(
          center: Alignment(0, 0.55 - drift * 0.07),
          radius: 1.0,
          colors: [
            const Color.fromRGBO(50, 205, 50, 0.15),
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    // ---- Dimmer Grid Pattern ----
    _paintGrid(canvas, size);

    // ---- Darker Pulse Overlay ----
    final pulsePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Color.fromRGBO(5, 3, 14, 0.90 + pulse * 0.05),
        ],
        radius: 0.85 + pulse * 0.03,
      ).createShader(rect);

    canvas.drawRect(rect, pulsePaint);
  }

  void _paintGrid(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withOpacity(0.015) // much darker grid
      ..strokeWidth = 1;

    const spacing = 40.0;
    final shift = gridShift * spacing * 2;

    for (double x = -size.width; x < size.width * 2; x += spacing) {
      canvas.drawLine(
        Offset(x + shift, -size.height),
        Offset(x - size.height + shift, size.height * 2),
        grid,
      );
    }

    for (double x = -size.width; x < size.width * 2; x += spacing) {
      canvas.drawLine(
        Offset(x - shift, -size.height),
        Offset(x + size.height - shift, size.height * 2),
        grid,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
