import 'package:flutter/material.dart';
import 'UI/create_timer.dart';   // MUST MATCH FOLDER NAME EXACTLY

void main() {
  runApp(const TimerApp());
}

class TimerApp extends StatelessWidget {
  const TimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Timer App',

      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      ),

      home: const CreateTimer(),   // MUST MATCH CLASS NAME EXACTLY
    );
  }
}
