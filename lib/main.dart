import 'package:flutter/material.dart';
import 'homepage.dart'; // Make sure this path matches your folder structure

void main() {
  runApp(const TickTalkApp());
}

class TickTalkApp extends StatelessWidget {
  const TickTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TickTalk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF007BFF),
        scaffoldBackgroundColor: const Color(0xFFF2F6FA),
      ),
      home: const HomeScreen(),
      routes: {
        '/createTimer': (context) => const Placeholder(), 
        // 👆 Replace Placeholder() with your actual CreateTimer screen later.
      },
    );
  }
}

