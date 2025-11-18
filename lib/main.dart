import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tts_service.dart';
import 'main_page.dart';
import 'welcome_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenWelcome = prefs.getBool('hasSeenWelcome') ?? false;
  final ttsService = TTSService();
  await ttsService.initialize();

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
      home: hasSeenWelcome ? const MainPage() : const WelcomePage(),
    );
  }
}
