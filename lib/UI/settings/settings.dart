import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../welcome_page/welcome_page.dart';
import 'font_scale.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // Resets the tutorial flag to rerun on next app start
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

  // Immediately navigates to the Welcome page
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

  // Helpers for +/- 10%
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
      appBar: AppBar(
        title: const Text('Settings'),
      ),

      // Rebuild when font scale changes
      body: AnimatedBuilder(
        animation: FontScale.instance,
        builder: (context, _) {
          final scale = FontScale.instance.scale;
          final percent = (scale * 100).toStringAsFixed(0);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ---------- TEXT SIZE CARD ----------
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Text Size',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Current: $percent% (applies across the app)',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Slider
                      Slider(
                        min: 0.8,
                        max: 1.6,
                        divisions: 8,
                        value: scale.clamp(0.8, 1.6),
                        label: '$percent%',
                        onChanged: (value) {
                          FontScale.instance.setScale(value);
                        },
                      ),

                      const SizedBox(height: 8),

                      // Buttons row
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _increaseBy10,
                              icon: const Icon(Icons.text_increase),
                              label: const Text('Bigger (+10%)'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _decreaseBy10,
                              icon: const Icon(Icons.text_decrease),
                              label: const Text('Smaller (−10%)'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Reset to 100%',
                            onPressed: () => FontScale.instance.setScale(1.0),
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ---------- TUTORIAL SECTION ----------
              const Text(
                'Tutorial',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Rerun Tutorial on Next Start'),
                subtitle: const Text('See the introductory guide again next time.'),
                leading: const Icon(Icons.replay),
                onTap: () => _rerunTutorial(context),
              ),
              ListTile(
                title: const Text('Go to Welcome Screen Now'),
                subtitle:
                const Text('Return immediately to the welcome/tutorial.'),
                leading: const Icon(Icons.play_circle_fill),
                onTap: () => _goToWelcomeScreen(context),
              ),
            ],
          );
        },
      ),
    );
  }
}