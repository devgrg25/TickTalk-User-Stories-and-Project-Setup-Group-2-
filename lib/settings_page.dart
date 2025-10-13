import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // This function handles the logic for resetting the tutorial flag.
  // It's an async function because SharedPreferences operations are asynchronous.
  void _rerunTutorial(BuildContext context) async {
    // 1. Get an instance of SharedPreferences.
    final prefs = await SharedPreferences.getInstance();

    // 2. Set the 'hasSeenTutorial' flag to false.
    //    On your app's startup, you would check for this flag.
    //    If it's false or doesn't exist, you show the tutorial.
    await prefs.setBool('hasSeenWelcome', false);

    // 3. Show a confirmation message to the user.
    //    It's good practice to check if the widget is still in the tree
    //    before showing a SnackBar.
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The tutorial will be shown on the next app start.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        // The back button is automatically added by Flutter's Navigator
      ),
      body: ListView(
        // Using a ListView is great for settings pages
        children: [
          ListTile(
            title: const Text('Rerun Tutorial'),
            subtitle: const Text('See the introductory guide again.'),
            leading: const Icon(Icons.replay),
            onTap: () => _rerunTutorial(context), // This calls the function when tapped
          ),
        ],
      ),
    );
  }
}