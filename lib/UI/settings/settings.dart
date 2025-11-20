import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../welcome_page/welcome_page.dart';
import 'font_scale.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // ------- Tutorial helpers -------
  Future<void> _rerunTutorial(BuildContext context) async {
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

  Future<void> _goToWelcomeScreen(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcome', false);

    if (!context.mounted) return;

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomePage()),
          (route) => false,
    );
  }

  // ------- Font helpers -------
  Future<void> _increaseFont() async {
    await FontScale.instance.increaseBy10();
  }

  Future<void> _decreaseFont() async {
    await FontScale.instance.decreaseBy10();
  }

  Future<void> _resetFont() async {
    await FontScale.instance.setScale(1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AnimatedBuilder(
        animation: FontScale.instance,
        builder: (context, _) {
          final percent = (FontScale.instance.scale * 100).toStringAsFixed(0);

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // ---------- Text Size ----------
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Text Size',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: const Text('Current size'),
                subtitle: Text('$percent% (applies across the app)'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _decreaseFont,
                        icon: const Icon(Icons.remove),
                        label: const Text('Smaller (-10%)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _increaseFont,
                        icon: const Icon(Icons.add),
                        label: const Text('Larger (+10%)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _resetFont,
                        child: const Text('Reset (100%)'),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 32),

              // ---------- Tutorial ----------
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Text(
                  'Tutorial',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.replay),
                title: const Text('Rerun Tutorial on Next Start'),
                subtitle:
                const Text('See the introductory guide again next time.'),
                onTap: () => _rerunTutorial(context),
              ),
              ListTile(
                leading: const Icon(Icons.play_circle_fill),
                title: const Text('Go to Welcome Screen Now'),
                subtitle:
                const Text('Return immediately to the welcome/tutorial.'),
                onTap: () => _goToWelcomeScreen(context),
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}
