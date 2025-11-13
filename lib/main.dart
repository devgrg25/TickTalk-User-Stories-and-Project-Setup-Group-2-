import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'MainPage.dart';
import 'welcome_page.dart';
import 'font_scale.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenWelcome = prefs.getBool('hasSeenWelcome') ?? false;

  // Load saved global font scale
  await FontScale.instance.init();

  runApp(TickTalkApp(hasSeenWelcome: hasSeenWelcome));
}

class TickTalkApp extends StatelessWidget {
  final bool hasSeenWelcome;

  const TickTalkApp({super.key, required this.hasSeenWelcome});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: FontScale.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'TickTalk',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF007BFF),
            scaffoldBackgroundColor: const Color(0xFFF2F6FA),
          ),
          // Apply font scaling to the whole app
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(FontScale.instance.scale),
              ),
              child: child!,
            );
          },
          home: hasSeenWelcome ? const MainPage() : const WelcomePage(),
        );
      },
    );
  }
}
