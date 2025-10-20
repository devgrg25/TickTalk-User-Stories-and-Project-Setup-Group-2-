import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_page.dart';
import 'stopwatcht2us2.dart';                       // Stopwatch feature screen
import 'stopwatchmodeselecter.dart';


// Screens in your project
import 'homepage.dart';
import 'welcome_page.dart';
import 'create_timer_screen.dart';
import 'stopwatcht2us2.dart';
import 'settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final hasSeenWelcome = prefs.getBool('hasSeenWelcome') ?? false;

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

      // Show Welcome first unless the flag is already set
      home: hasSeenWelcome ? const HomeScreen() : const WelcomePage(),

      // Named routes you use from the voice tutorial / app
      routes: {
        '/createTimer': (context) => const Placeholder(),
        '/stopwatch': (context) => const StopwatchModeSelector(),
        // 👆 Replace Placeholder() with your actual CreateTimer screen later.
      },
    );
  }
}
