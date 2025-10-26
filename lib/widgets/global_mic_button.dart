import 'package:flutter/material.dart';

class GlobalMicButton extends StatefulWidget {
  const GlobalMicButton({super.key});

  @override
  State<GlobalMicButton> createState() => _GlobalMicButtonState();
}

class _GlobalMicButtonState extends State<GlobalMicButton> {
  bool _isListening = false;

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
    });
    // TODO: connect this to your VoiceController if you want live voice input.
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
              Icon(
                _isListening ? Icons.mic : Icons.mic_off,
                color: Colors.white,
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
