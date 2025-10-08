import 'package:flutter/material.dart';
import 'stopwatch_page.dart'; // Import the new stopwatch page

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // State variable to track the selected tab index
  int _selectedIndex = 0;

  // List of pages to be displayed by the navigation bar
  static const List<Widget> _pages = <Widget>[
    StopwatchPage(), // Our new stopwatch page
    Center(child: Text('Timers Page')), // Placeholder for Timers
    Center(child: Text('World Clock Page')), // Placeholder for World Clock
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: const Text('Tick Talk'),
      ),
      // Display the selected page from the list
      body: _pages.elementAt(_selectedIndex),
      // ADDED: The Bottom Navigation Bar
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        // Using a more modern indicator style
        indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Stopwatch',
          ),
          NavigationDestination(
            icon: Icon(Icons.hourglass_empty_outlined),
            selectedIcon: Icon(Icons.hourglass_empty),
            label: 'Timers',
          ),
          NavigationDestination(
            icon: Icon(Icons.public_outlined),
            selectedIcon: Icon(Icons.public),
            label: 'World Clock',
          ),
        ],
      ),
    );
  }
}