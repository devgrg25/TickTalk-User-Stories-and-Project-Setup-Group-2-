import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_page.dart';

class SettingsPage extends StatelessWidget {
  // Make timerData optional so the route can be const SettingsPage()
  final dynamic timerData;
  const SettingsPage({super.key, this.timerData});

  // Mark the tutorial to run again on next start
  Future<void> _rerunTutorial(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcome', false);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('The tutorial will be shown on the next app start.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Immediately jump to the Welcome screen and clear history
  Future<void> _goToWelcomeScreen(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcome', false);

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomePage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.replay),
            title: const Text('Rerun Tutorial on Next Start'),
            subtitle: const Text('See the introduction again next time.'),
            onTap: () => _rerunTutorial(context),
          ),
          ListTile(
            leading: const Icon(Icons.play_circle_fill),
            title: const Text('Go to Welcome Screen Now'),
            subtitle: const Text('Jump back to the welcome/tutorial.'),
            onTap: () => _goToWelcomeScreen(context),
          ),
        ],
      ),
    );
  }
}
