import 'package:flutter/material.dart';
import '../../../logic/routines/routine_storage.dart';
import '../../../logic/routines/routine_model.dart';
import '../../../logic/timer/timer_controller.dart';
import '../../../logic/timer/timer_manager.dart';
import '../timer/countdown_page.dart';

class RoutinesPage extends StatefulWidget {
  const RoutinesPage({Key? key}) : super(key: key);

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

  Future<void> reload() async {
    routines = await RoutineStorage.instance.loadRoutines();
    if (mounted) setState(() {});
  }

  void _delete(String id) async {
    await RoutineStorage.instance.deleteRoutine(id);
    reload();
  }

  void _startRoutine(Routine routine) {
    final cloned = routine.intervals
        .map((i) => TimerInterval(name: i.name, seconds: i.seconds))
        .toList();

    final controller = TimerManager.instance.startTimer(
      routine.name,
      cloned,
    );

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
        child: routines.isEmpty
            ? const Center(
          child: Text("No routines saved",
              style: TextStyle(color: Colors.grey)),
        )
            : ListView.builder(
          itemCount: routines.length,
          itemBuilder: (_, i) {
            final r = routines[i];
            return Card(
              color: const Color(0xFF1C1C1C),
              child: ListTile(
                title: Text(r.name,
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  "${r.intervals.length} intervals",
                  style: const TextStyle(color: Colors.white70),
                ),
                onTap: () => _startRoutine(r),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _delete(r.id),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
