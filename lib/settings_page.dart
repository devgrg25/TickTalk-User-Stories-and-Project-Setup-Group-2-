import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_page.dart';
import 'font_scale.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomePage()),
            (route) => false,
      );
    }
  }

  // Exact +10 / -10 percentage points each press
  Future<void> _increaseBy10() async {
    final current = FontScale.instance.scale;
    await FontScale.instance.setScale(current + 0.10);
  }

  Future<void> _decreaseBy10() async {
    final current = FontScale.instance.scale;
    await FontScale.instance.setScale(current - 0.10);
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
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Text Size',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black54),
                ),
              ),
              ListTile(
                title: const Text('Current size'),
                subtitle: Text('$percent% (applies across the app)'),
                leading: const Icon(Icons.text_fields),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _increaseBy10,       // +10 percentage points
                        child: const Text('Increase (+10%)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _decreaseBy10,       // −10 percentage points
                        child: const Text('Decrease (−10%)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => FontScale.instance.setScale(1.0),
                        child: const Text('Reset (100%)'),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),

              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Text(
                  'Tutorial',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black54),
                ),
              ),
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
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}
