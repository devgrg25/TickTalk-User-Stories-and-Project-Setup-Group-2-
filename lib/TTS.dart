// import 'dart:async';
// import 'package:flutter/material.dart';
//
// // Type alias is added here to help your GlobalKey definition in homepage.dart
// typedef StopwatchPageState = State<StopwatchPage>;
//
// class StopwatchPage extends StatefulWidget {
//   // The parent widget will pass the GlobalKey here
//   const StopwatchPage({super.key});
//
//   @override
//   // Note: The key type requires the State class name for external access
//   State<StopwatchPage> createState() => _StopwatchPageState();
// }
//
// class _StopwatchPageState extends State<StopwatchPage> {
//   final Stopwatch _stopwatch = Stopwatch();
//   // Timer to update the UI
//   Timer? _timer;
//   String _displayTime = '00:00.00';
//
//   @override
//   void dispose() {
//     // Cancel the timer to avoid memory leaks
//     _timer?.cancel();
//     super.dispose();
//   }
//
//   // 📢 PUBLIC METHOD: Allows external voice handler to stop the watch
//   void stopStopwatch() {
//     if (_stopwatch.isRunning) {
//       _stopwatch.stop();
//       _timer?.cancel();
//       setState(() {});
//     }
//   }
//
//   // 📢 PUBLIC METHOD: Allows external voice handler to start the watch
//   void startStopwatch() {
//     if (!_stopwatch.isRunning) {
//       _stopwatch.start();
//       // Update the UI every 30 milliseconds for a smooth display
//       _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
//         setState(() {
//           _displayTime = _formatTime(_stopwatch.elapsed);
//         });
//       });
//       setState(() {});
//     }
//   }
//
//   // Internal method to handle the physical button press (toggles state)
//   void _toggleStartStop() {
//     if (_stopwatch.isRunning) {
//       stopStopwatch();
//     } else {
//       startStopwatch();
//     }
//   }
//
//   void _reset() {
//     _stopwatch.stop();
//     _stopwatch.reset();
//     _timer?.cancel();
//     setState(() {
//       _displayTime = '00:00.00';
//     });
//   }
//
//   String _formatTime(Duration duration) {
//     // Format the duration into MM:SS:ms
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
//     String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
//     String twoDigitMilliseconds =
//     twoDigits(duration.inMilliseconds.remainder(1000) ~/ 10);
//     return "$twoDigitMinutes:$twoDigitSeconds.$twoDigitMilliseconds";
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Get text style from the app's theme
//     final textTheme = Theme.of(context).textTheme;
//
//     // Determine the button color based on state
//     final bool isRunning = _stopwatch.isRunning;
//     final Color buttonColor = isRunning
//         ? Theme.of(context).colorScheme.error
//         : Theme.of(context).colorScheme.primary;
//
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               _displayTime,
//               style: textTheme.displayLarge?.copyWith(
//                 fontSize: 80,
//                 fontFamily: 'monospace', // Gives a classic digital clock feel
//               ),
//             ),
//             const SizedBox(height: 50),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // Reset Button
//                 ElevatedButton(
//                   onPressed: _reset,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.grey.shade800,
//                     foregroundColor: Colors.white,
//                   ),
//                   child: const Text('Reset'),
//                 ),
//                 const SizedBox(width: 20),
//                 // Start/Stop Button (Uses the internal toggle method)
//                 ElevatedButton(
//                   onPressed: _toggleStartStop, // Calls the toggle method
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: buttonColor,
//                     foregroundColor: Colors.black,
//                   ),
//                   child: Text(isRunning ? 'Stop' : 'Start'),
//                 ),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }