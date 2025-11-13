import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_page.dart'; // ✅ Correct import
import 'font_scale.dart';  // 👈 fixed import

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
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomePage()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // 🔹 TEXT SIZE SECTION
          const ListTile(
            leading: Icon(Icons.text_fields),
            title: Text('Text Size'),
            subtitle: Text('Adjust app-wide text size for better readability.'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await FontScale.instance.decrease10();
                    },
                    icon: const Icon(Icons.text_decrease),
                    label: const Text('Smaller'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await FontScale.instance.increase10();
                    },
                    icon: const Icon(Icons.text_increase),
                    label: const Text('Bigger'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Existing tutorial options
          ListTile(
            title: const Text('Rerun Tutorial on Next Start'),
            subtitle: const Text('See the introductory guide again next time.'),
            leading: const Icon(Icons.replay),
            onTap: () => _rerunTutorial(context),
          ),
          ListTile(
            title: const Text('Go to Welcome Screen Now'),
            subtitle: const Text('Return immediately to the welcome/tutorial.'),
            leading: const Icon(Icons.play_circle_fill),
            onTap: () => _goToWelcomeScreen(context),
          ),
        ],
      ),
    );
  }
}
