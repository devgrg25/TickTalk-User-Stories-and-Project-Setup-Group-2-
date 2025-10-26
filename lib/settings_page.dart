import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_page.dart'; // ✅ Correct import
import 'widgets/global_scaffold.dart'; // ✅ Add this for mic bar

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // Resets the tutorial flag to rerun on next app start
  void _rerunTutorial(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcome', false);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The tutorial will be shown on the next app start.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Immediately navigates to the Welcome page
  void _goToWelcomeScreen(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcome', false);

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomePage()),
            (route) => false, // Clears all previous routes
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold( // ✅ Use GlobalScaffold for persistent mic
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Rerun Tutorial on Next Start'),
            subtitle: const Text('See the introductory guide again next time.'),
            leading: const Icon(Icons.replay, color: Colors.blueAccent),
            onTap: () => _rerunTutorial(context),
          ),
          const Divider(),
          ListTile(
            title: const Text('Go to Welcome Screen Now'),
            subtitle: const Text('Return immediately to the welcome/tutorial.'),
            leading: const Icon(Icons.play_circle_fill, color: Colors.blueAccent),
            onTap: () => _goToWelcomeScreen(context),
          ),
          const SizedBox(height: 100), // space above mic bar
        ],
      ),
    );
  }
}
