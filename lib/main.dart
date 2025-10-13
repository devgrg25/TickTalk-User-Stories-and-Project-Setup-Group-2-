import 'package:flutter/material.dart';
import 'homepage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_page.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  // Check if the user has seen the welcome screen
  final bool hasSeenWelcome = prefs.getBool('hasSeenWelcome') ?? false;
  //final bool hasSeenWelcome = false;

  runApp(TickTalkApp(hasSeenWelcome: hasSeenWelcome));
}

class TickTalkApp extends StatelessWidget {

  final bool hasSeenWelcome;
  const TickTalkApp({super.key, required this.hasSeenWelcome});

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
      home: hasSeenWelcome ? const HomeScreen() : const WelcomePage(),//replace second homescreen once the welcome page is added
      routes: {
        '/createTimer': (context) => const Placeholder(),
        // 👆 Replace Placeholder() with your actual CreateTimer screen later.
      },
    );
  }
}

