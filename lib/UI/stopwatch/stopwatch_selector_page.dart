import 'package:flutter/material.dart';

class StopwatchSelectorPage extends StatelessWidget {
  const StopwatchSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, "/normalStopwatch");
                },
                child: const Text("Normal Stopwatch"),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  // player mode later
                },
                child: const Text("Player Mode"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
