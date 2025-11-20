import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../logic/routines/routine_storage.dart';
import '../../../logic/routines/routine_model.dart';

import '../../../logic/timer/timer_controller.dart';
import '../../../logic/timer/timer_manager.dart';
import '../timer/countdown_page.dart';

class RoutinesPage extends StatefulWidget {
  const RoutinesPage({super.key});

  @override
  State<RoutinesPage> createState() => RoutinesPageState();
}

class RoutinesPageState extends State<RoutinesPage> {
  List<Routine> routines = [];

  @override
  void initState() {
    super.initState();
    reload();
  }

  // Reload routines from storage
  Future<void> reload() async {
    routines = await RoutineStorage.instance.loadRoutines();
    if (mounted) setState(() {});
  }

  // Delete routine
  void _delete(String id) async {
    await RoutineStorage.instance.deleteRoutine(id);
    reload();
  }

  // Start routine → consistent with HomePage timer behavior
  void _startRoutine(Routine routine) {
    final cloned = routine.intervals
        .map((i) => TimerInterval(name: i.name, seconds: i.seconds))
        .toList();

    // Start via TimerManager
    TimerManager.instance.startTimer(routine.name, cloned);

    // Grab the active timer we just started
    final active = TimerManager.instance.timers.last;
    final controller = active.controller;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CountdownPage(
          controller: controller,
          onExit: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            Center(
              child: Text(
                "Your Routines",
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 22,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: routines.isEmpty
                  ? const Center(
                child: Text(
                  "No routines saved",
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: routines.length,
                itemBuilder: (_, i) {
                  final r = routines[i];

                  return Card(
                    color: const Color(0xFF1C1C1C),
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    child: ListTile(
                      onTap: () => _startRoutine(r),
                      title: Text(
                        r.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        "${r.intervals.length} intervals",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _delete(r.id),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
