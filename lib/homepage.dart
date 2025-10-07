import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  // Use const constructor for widgets that don't change
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // CHANGE: Increased toolbarHeight to add vertical space
        toolbarHeight: 80,
        // CHANGE: Moved the PopupMenuButton to the `leading` property for the left side
        leading: PopupMenuButton(
          icon: const Icon(Icons.menu), // Added a standard menu icon
          itemBuilder: (context) => [
            const PopupMenuItem(child: Text('Settings')),
            const PopupMenuItem(child: Text('About')),
          ],
        ),
        title: const Text('Tick Talk'),
        centerTitle: false,
        // CHANGE: The `actions` property is now removed as it's no longer needed
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to the Timer App!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Timer Started!')),
                );
              },
              style: ElevatedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}