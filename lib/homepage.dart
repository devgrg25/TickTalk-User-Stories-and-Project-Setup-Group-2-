import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'settings_page.dart';
import 'timer_models/timer_model.dart';
import 'controllers/voice_controller.dart';

class HomeScreen extends StatefulWidget {
  final List<TimerData> timers;
  final Function(TimerData) onPlayTimer;
  final Function(TimerData) onEditTimer;
  final Function(String) onDeleteTimer;
  final void Function(int) onSwitchTab;
  final Function(TimerData) onStartTimer;
  final TimerData? activeTimer;

  const HomeScreen({
    super.key,
    required this.timers,
    required this.onPlayTimer,
    required this.onEditTimer,
    required this.onDeleteTimer,
    required this.onSwitchTab,
    required this.onStartTimer,
    this.activeTimer,
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final FlutterTts _tts = FlutterTts();
  final VoiceController _voiceController = VoiceController();

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    await _voiceController.initialize();
    //await _loadTimers();
    await Future.delayed(const Duration(milliseconds: 1000));
    await _tts.speak("You are now on the home page.");
  }

  @override
  void dispose() {
    _tts.stop();
    _voiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('TickTalk', style: TextStyle(color: Color(0xFF007BFF), fontWeight: FontWeight.bold, fontSize: 30)),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black),
              onPressed: () {}),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (String result) {
              if (result == 'settings') {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsPage()));
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined),
                    SizedBox(width: 10),
                    Text("Settings"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      // ----------------------- MAIN BODY ------------------------
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          // increased from 90
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline, size: 24),
                    label: const Text(
                      'Create New Timer',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007BFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => widget.onSwitchTab(1),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Your Timers',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                ),
                const SizedBox(height: 12),
                widget.timers.isEmpty
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      "You haven't created any timers yet.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 40),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.timers.length,
                  itemBuilder: (context, index) {
                    final timer = widget.timers[index];
                    final bool isActive = widget.activeTimer?.id == timer.id;

                    return TimerCard(
                      timer: timer,
                      isActive: isActive,
                      activeTime: isActive ? widget.activeTimer!.totalTime : null,
                      title: timer.name,
                      status: isActive ? 'Active' : 'Ready',
                      feedback: 'Audio + Haptic',
                      color: isActive ? Colors.green : const Color(0xFF007BFF),
                      onPlay: () {
                        if (!isActive) {
                          widget.onStartTimer(timer);
                        }
                        else {
                          widget.onPlayTimer(timer);
                        }
                      },
                      onEdit: () => widget.onEditTimer(timer),
                      onDelete: () => widget.onDeleteTimer(timer.id),
                    );

                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
String _formatTime(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
}

// ---------------------------------------------
// TimerCard
// ---------------------------------------------
class TimerCard extends StatelessWidget {
  final TimerData timer;
  final String title;
  final String status;
  final String feedback;
  final Color color;
  final VoidCallback onPlay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isActive;
  final int? activeTime; // remaining time if active


  const TimerCard({
    super.key,
    required this.timer,
    required this.title,
    required this.status,
    required this.feedback,
    required this.color,
    required this.onPlay,
    required this.onEdit,
    required this.onDelete,
    required this.isActive,     // NEW
    this.activeTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title,
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(status,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ),
          ]),
          Text(
            isActive
                ? _formatTime(activeTime ?? 0)
                : _formatTime(timer.totalTime),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text('Feedback: $feedback',
              style: const TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            IconButton(
                onPressed: onPlay,
                icon: const Icon(Icons.play_arrow, color: Colors.black54)),
            IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, color: Colors.black54)),
            IconButton(
                onPressed: onDelete,
                icon:
                const Icon(Icons.delete_outline, color: Colors.redAccent)),
          ]),
        ],
      ),
    );
  }
}
