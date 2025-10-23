// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:speech_to_text/speech_to_text.dart';
// import 'package:flutter_tts/flutter_tts.dart';
//
// import 'welcome_page.dart';
// import 'homepage.dart';
// import 'create_timer_screen.dart';
// import 'stopwatchmodeselecter.dart';
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   final prefs = await SharedPreferences.getInstance();
//   final bool hasSeenWelcome = prefs.getBool('hasSeenWelcome') ?? false;
//
//   runApp(TickTalkApp(hasSeenWelcome: hasSeenWelcome));
// }
//
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   HomeScreenState createState() => HomeScreenState(); // ✅ made public
// }
//
// class HomeScreenState extends State<HomeScreen> {
//   final FlutterTts _tts = FlutterTts();
//
//   @override
//   void initState() {
//     super.initState();
//     _speak("Welcome back to TickTalk. Ready to assist you!");
//   }
//
//   // --- Voice Actions (called from main.dart) ---
//   void openNormalStopwatch({bool autoStart = false}) {
//     _speak("Opening Stopwatch");
//     // TODO: Navigate to your Stopwatch screen
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Stopwatch started")),
//     );
//   }
//
//   void startMindfulnessMinute() {
//     _speak("Starting a mindfulness minute");
//     // TODO: Implement mindfulness routine
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Mindfulness minute started")),
//     );
//   }
//
//   void startSimpleLaundryCycle() {
//     _speak("Starting laundry cycle");
//     // TODO: Implement laundry timer logic
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Laundry timer started")),
//     );
//   }
//
//   void start202020Rule() {
//     _speak("Starting 20-20-20 rule");
//     // TODO: Implement the 20-20-20 rule
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("20-20-20 rule started")),
//     );
//   }
//
//   void rerunTutorial() {
//     _speak("Rerunning tutorial");
//     // TODO: Navigate to your tutorial or onboarding
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Tutorial restarted")),
//     );
//   }
//
//   Future<void> _speak(String text) async {
//     try {
//       await _tts.setLanguage("en-US");
//       await _tts.setSpeechRate(0.9);
//       await _tts.speak(text);
//     } catch (e) {
//       debugPrint("TTS Error: $e");
//     }
//   }
//
//   // --- UI for Home Screen ---
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("TickTalk Home"),
//         backgroundColor: const Color(0xFF007BFF),
//         foregroundColor: Colors.white,
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16.0),
//         children: [
//           _buildHeader(),
//           const SizedBox(height: 16),
//           _buildRoutineSection(),
//           const SizedBox(height: 16),
//           _buildQuickActions(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFF007BFF),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: const Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Welcome to TickTalk 👋",
//             style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
//           ),
//           SizedBox(height: 8),
//           Text(
//             "Use your voice or tap below to manage your routines and timers.",
//             style: TextStyle(color: Colors.white70),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildRoutineSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           "Popular Routines",
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             _routineCard("Mindfulness", Icons.self_improvement, startMindfulnessMinute),
//             _routineCard("Laundry", Icons.local_laundry_service, startSimpleLaundryCycle),
//             _routineCard("20-20-20", Icons.visibility, start202020Rule),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Widget _routineCard(String title, IconData icon, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 100,
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: const [
//             BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
//           ],
//         ),
//         child: Column(
//           children: [
//             Icon(icon, color: const Color(0xFF007BFF), size: 32),
//             const SizedBox(height: 8),
//             Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildQuickActions() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           "Quick Actions",
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 8),
//         _quickActionButton("Start Stopwatch", Icons.timer, openNormalStopwatch),
//         _quickActionButton("Rerun Tutorial", Icons.school, rerunTutorial),
//       ],
//     );
//   }
//
//   Widget _quickActionButton(String title, IconData icon, VoidCallback onTap) {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: ListTile(
//         onTap: onTap,
//         leading: Icon(icon, color: const Color(0xFF007BFF)),
//         title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//         trailing: const Icon(Icons.chevron_right),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_page.dart';
import 'homepage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenWelcome = prefs.getBool('hasSeenWelcome') ?? false;

  runApp(TickTalkApp(hasSeenWelcome: hasSeenWelcome));
}

class TickTalkApp extends StatelessWidget {
  final bool hasSeenWelcome;

  const TickTalkApp({super.key, required this.hasSeenWelcome});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TickTalk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF007BFF),
        scaffoldBackgroundColor: const Color(0xFFF2F6FA),
      ),
      home: hasSeenWelcome ? const HomeScreen() : const WelcomePage(),
    );
  }
}
