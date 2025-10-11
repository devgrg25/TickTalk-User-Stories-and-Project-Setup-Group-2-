import 'package:flutter/material.dart';
import 'home_page.dart'; // make sure this points to your actual home screen file
// import 'onboarding/welcome_screen.dart'; // adjust if your folder name is different

void main() {
  runApp(const TickTalkApp());
}

class TickTalkApp extends StatelessWidget {
  const TickTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TickTalk Timer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: false,
      ),

      // 👇 Start at the welcome screen for first launch
      initialRoute: '/welcome',

      // 👇 Define all your routes here
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/home': (context) => const HomeScreen(),
        '/createTimer': (context) => const Placeholder(), // build later
        '/onboarding': (context) => const Placeholder(), // tutorial placeholder for now
      },
    );
  }
}
