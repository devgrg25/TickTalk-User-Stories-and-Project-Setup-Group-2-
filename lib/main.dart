import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'homepage.dart';       // your HomeScreen
import 'welcome_page.dart';   // the voice-driven welcome we added

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final hasSeenWelcome = false;

  runApp(TickTalkApp(hasSeenWelcome: hasSeenWelcome));
}

class TickTalkApp extends StatelessWidget {
  const TickTalkApp({super.key, required this.hasSeenWelcome});
  final bool hasSeenWelcome;

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
      home: hasSeenWelcome ? const HomeScreen() : const WelcomePage(),
      routes: {
        '/createTimer': (context) => const Placeholder(),
        // TODO: replace Placeholder with your CreateTimer screen.
      },
    );
  }
}
