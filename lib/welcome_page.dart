import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'homepage.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  // This function will be called when the user clicks the button
  Future<void> _onGetStarted(BuildContext context) async {
    // 1. Get the shared preferences instance
    final prefs = await SharedPreferences.getInstance();
    // 2. Set the flag to true
    await prefs.setBool('hasSeenWelcome', true);

    // 3. Navigate to the HomePage and remove the WelcomePage from the stack
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to Tick Talk!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            const Text(
              'Your new favorite timer app.',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _onGetStarted(context),
              child: const Text('Get Started'),
            )
          ],
        ),
      ),
    );
  }
}