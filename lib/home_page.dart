
// import 'package:flutter/material.dart';
//
// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         title: const Text(
//           'TickTalk',
//           style: TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.bold,
//             fontSize: 20,
//           ),
//         ),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications_none, color: Colors.black),
//             onPressed: () {},
//           )
//         ],
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Create New Timer Button
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton.icon(
//                   icon: const Icon(Icons.add_circle_outline, size: 24),
//                   label: const Text(
//                     'Create New Timer',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF007BFF),
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   onPressed: () => Navigator.pushNamed(context, '/createTimer'),
//                 ),
//               ),
//               const SizedBox(height: 24),
//
//               // Pre-defined Timer Routines
//               const Text(
//                 'Pre-defined Timer Routines',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.black87,
//                 ),
//               ),
//               const SizedBox(height: 12),
//
//               // FIXED: auto-sizing scrollable cards
//               SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: Row(
//                   children: const [
//                     RoutineCard(
//                       title: 'Exercise Sets',
//                       description:
//                       'Intervals for strength & cardio training.',
//                       icon: Icons.fitness_center,
//                     ),
//                     RoutineCard(
//                       title: 'Pomodoro Focus',
//                       description: '25-min work, 5-min break cycles.',
//                       icon: Icons.timer_outlined,
//                     ),
//                   ],
//                 ),
//               ),
//
//               const SizedBox(height: 24),
//
//               // Your Timers
//               const Text(
//                 'Your Timers',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.black87,
//                 ),
//               ),
//               const SizedBox(height: 12),
//
//               const TimerCard(
//                 title: 'Morning Workout',
//                 status: 'Active',
//                 feedback: 'Audio + Haptic',
//                 color: Color(0xFF007BFF),
//               ),
//               const TimerCard(
//                 title: 'Cooking Timer',
//                 status: 'Paused',
//                 feedback: 'Audio Only',
//                 color: Colors.grey,
//               ),
//               const TimerCard(
//                 title: 'Meditation',
//                 status: 'Completed',
//                 feedback: 'Haptic Only',
//                 color: Colors.green,
//               ),
//               const TimerCard(
//                 title: 'Study Break',
//                 status: 'Paused',
//                 feedback: 'Audio + Haptic',
//                 color: Colors.grey,
//               ),
//             ],
//           ),
//         ),
//       ),
//
//       // Bottom Navigation Bar
//       bottomNavigationBar: BottomNavigationBar(
//         selectedItemColor: const Color(0xFF007BFF),
//         unselectedItemColor: Colors.grey,
//         type: BottomNavigationBarType.fixed,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.add_circle_outline), label: 'Create'),
//           BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Routines'),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.bar_chart_outlined), label: 'Activity'),
//         ],
//       ),
//     );
//   }
// }
//
// //---------------------------------------------
// // Routine Card (auto-sizing, no overflow)
// //---------------------------------------------
// class RoutineCard extends StatelessWidget {
//   final String title;
//   final String description;
//   final IconData icon;
//
//   const RoutineCard({
//     super.key,
//     required this.title,
//     required this.description,
//     required this.icon,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 220,
//       margin: const EdgeInsets.only(right: 16, bottom: 8),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF9FAFB),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min, // 👈 key line (fix overflow)
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(icon, color: const Color(0xFF007BFF), size: 32),
//           const SizedBox(height: 12),
//           Text(
//             title,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             description,
//             style: const TextStyle(fontSize: 13, color: Colors.black54),
//           ),
//           const SizedBox(height: 8),
//           TextButton(
//             onPressed: () {},
//             child: const Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text('Start Routine', style: TextStyle(fontSize: 14)),
//                 Icon(Icons.arrow_right_alt, size: 18),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// //---------------------------------------------
// // Timer Card (unchanged)
// //---------------------------------------------
// class TimerCard extends StatelessWidget {
//   final String title;
//   final String status;
//   final String feedback;
//   final Color color;
//
//   const TimerCard({
//     super.key,
//     required this.title,
//     required this.status,
//     required this.feedback,
//     required this.color,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF9FAFB),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 title,
//                 style:
//                 const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//               Container(
//                 padding:
//                 const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.15),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Text(
//                   status,
//                   style: TextStyle(color: color, fontWeight: FontWeight.w600),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Feedback: $feedback',
//             style: const TextStyle(fontSize: 14, color: Colors.black54),
//           ),
//           const SizedBox(height: 12),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               IconButton(
//                 onPressed: () {},
//                 icon: const Icon(Icons.play_arrow, color: Colors.black54),
//               ),
//               IconButton(
//                 onPressed: () {},
//                 icon: const Icon(Icons.edit_outlined, color: Colors.black54),
//               ),
//               IconButton(
//                 onPressed: () {},
//                 icon: const Icon(Icons.delete_outline, color: Colors.black54),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final FlutterTts tts = FlutterTts();

  // Speak + optional vibration
  Future<void> _announce(String message) async {
    await tts.speak(message);
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FA),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        title: const Text(
          'TickTalk',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
            tooltip: 'Notifications',
            onPressed: () => _announce('No new notifications'),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔵 Create New Timer Button
              Semantics(
                label: 'Create new timer',
                button: true,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 26),
                  label: const Text(
                    'Create New Timer',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007BFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () async {
                    await _announce('Opening timer creation screen');
                    if (!mounted) return; // ✅ Prevent async context warning
                    Navigator.pushNamed(context, '/createTimer');
                  },
                ),
              ),

              const SizedBox(height: 28),

              // 💪 Pre-defined Routines
              const Text(
                'Pre-defined Routines',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  RoutineCard(
                    title: 'Exercise Sets',
                    description: 'Intervals for strength and cardio.',
                    icon: Icons.fitness_center,
                    onStart: () => _announce('Starting Exercise Sets routine'),
                  ),
                  RoutineCard(
                    title: 'Pomodoro Focus',
                    description: '25 minutes work, 5 minute breaks.',
                    icon: Icons.timer_outlined,
                    onStart: () => _announce('Starting Pomodoro Focus routine'),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ⏱ Your Timers
              const Text(
                'Your Timers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              AccessibleTimerCard(
                title: 'Morning Workout',
                status: 'Active',
                feedback: 'Audio + Haptic',
                color: Colors.blue,
                onPlay: () => _announce('Morning workout timer started'),
                onEdit: () => _announce('Editing morning workout timer'),
                onDelete: () => _announce('Deleted morning workout timer'),
              ),
              AccessibleTimerCard(
                title: 'Cooking Timer',
                status: 'Paused',
                feedback: 'Audio only',
                color: Colors.grey,
                onPlay: () => _announce('Cooking timer resumed'),
                onEdit: () => _announce('Editing cooking timer'),
                onDelete: () => _announce('Deleted cooking timer'),
              ),
              AccessibleTimerCard(
                title: 'Meditation',
                status: 'Completed',
                feedback: 'Haptic only',
                color: Colors.green,
                onPlay: () => _announce('Meditation timer restarted'),
                onEdit: () => _announce('Editing meditation timer'),
                onDelete: () => _announce('Deleted meditation timer'),
              ),
            ],
          ),
        ),
      ),

      // ⚙️ Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color(0xFF007BFF),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => _announce(
          'Navigated to ${['Home', 'Create', 'Routines', 'Activity'][i]}',
        ),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Routines'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Activity'),
        ],
      ),
    );
  }
}

// -------------------------------------------
// 🧱 RoutineCard
// -------------------------------------------
class RoutineCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onStart;

  const RoutineCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title routine. $description',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF007BFF), size: 36),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                description,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Start'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007BFF),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------
// ⏱ AccessibleTimerCard – with glow animation
// -------------------------------------------
class AccessibleTimerCard extends StatefulWidget {
  final String title;
  final String status;
  final String feedback;
  final Color color;
  final VoidCallback onPlay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AccessibleTimerCard({
    super.key,
    required this.title,
    required this.status,
    required this.feedback,
    required this.color,
    required this.onPlay,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<AccessibleTimerCard> createState() => _AccessibleTimerCardState();
}

class _AccessibleTimerCardState extends State<AccessibleTimerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.status.toLowerCase() == 'active';
    return AnimatedBuilder(
      animation: _glowController,
      builder: (_, __) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? widget.color.withValues(alpha: 0.2 + 0.2 * _glowController.value)
                    : Colors.black12,
                blurRadius: 10,
                spreadRadius: isActive ? 2 : 0,
              )
            ],
          ),
          child: Semantics(
            label:
            '${widget.title} timer, status ${widget.status}, feedback ${widget.feedback}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.status,
                        style: TextStyle(
                            color: widget.color, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Feedback: ${widget.feedback}',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.play_arrow),
                      tooltip: 'Play timer',
                      onPressed: widget.onPlay,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit timer',
                      onPressed: widget.onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete timer',
                      onPressed: widget.onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
