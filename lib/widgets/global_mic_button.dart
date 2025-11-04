import 'dart:math' as math;
import 'package:flutter/material.dart';

class GlobalMicButton extends StatefulWidget {
  const GlobalMicButton({super.key});

  @override
  State<GlobalMicButton> createState() => _GlobalMicButtonState();
}

class _GlobalMicButtonState extends State<GlobalMicButton>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  late AnimationController _controller;

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
      if (_isListening) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });
    // TODO: connect this to your VoiceController if you want live voice input.
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GestureDetector(
        onTap: _toggleListening,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: _isListening ? Colors.redAccent : const Color(0xFF007BFF),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔹 Animated glowing mic icon
              AnimatedBuilder(
                animation: _controller,
                builder: (_, child) {
                  final rotation =
                  Tween(begin: 0.0, end: 2 * math.pi).evaluate(_controller);
                  return Transform.rotate(
                    angle: rotation,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const SweepGradient(
                          colors: [
                            Color(0xFFFFBF48),
                            Color(0xFFBE4A1D),
                            Color(0xFFFFBF47),
                            Color(0xFFBE4A1D),
                            Color(0xFFFFBF48),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orangeAccent.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_off,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Text(
                _isListening ? "Listening... Tap to stop" : "Tap to Speak",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
