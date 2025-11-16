import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../logic/timer/timer_controller.dart';
import '../../logic/timer/timer_manager.dart';
import '../../logic/routines/routine_storage.dart';
import '../../logic/routines/routine_model.dart';

class CreateTimerPage extends StatefulWidget {
  final VoidCallback onTimerStarted;

  const CreateTimerPage({super.key, required this.onTimerStarted});

  @override
  State<CreateTimerPage> createState() => _CreateTimerPageState();
}

class _CreateTimerPageState extends State<CreateTimerPage> {
  List<TimerInterval> intervals = [];
  final TextEditingController nameCtrl = TextEditingController();
  bool saveAsRoutine = false;

  void _openDialog({TimerInterval? interval, int? index}) {
    final localName = TextEditingController(text: interval?.name ?? "");
    final localSec =
    TextEditingController(text: interval?.seconds.toString() ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF171717),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          interval == null ? "Add Interval" : "Edit Interval",
          style: GoogleFonts.orbitron(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: localName,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Name",
                labelStyle: TextStyle(color: Colors.grey),
              ),
            ),
            TextField(
              controller: localSec,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Seconds",
                labelStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel",
                style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () {
              final rawName = localName.text.trim();
              final sec = int.tryParse(localSec.text.trim()) ?? 0;
              if (sec <= 0) return;

              final name = rawName.isEmpty
                  ? "INTERVAL ${intervals.length + 1}"
                  : rawName.toUpperCase();

              if (!mounted) return;
              setState(() {
                if (interval == null) {
                  intervals.add(TimerInterval(name: name, seconds: sec));
                } else {
                  intervals[index!] = TimerInterval(name: name, seconds: sec);
                }
              });

              Navigator.pop(context);
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _startTimer() async {
    final timerName = nameCtrl.text.trim();
    if (timerName.isEmpty || intervals.isEmpty) return;

    final cloned = intervals
        .map((i) => TimerInterval(name: i.name, seconds: i.seconds))
        .toList();

    if (saveAsRoutine) {
      await RoutineStorage.instance.saveRoutine(
        Routine(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: timerName.toUpperCase(),
          intervals: cloned,
        ),
      );
    }

    TimerManager.instance.startTimer(timerName.toUpperCase(), cloned);

    nameCtrl.clear();
    intervals.clear();
    saveAsRoutine = false;
    setState(() {});

    widget.onTimerStarted();

    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              "Create Timer",
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 22,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Timer Name",
                  labelStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 10),

            SwitchListTile(
              value: saveAsRoutine,
              onChanged: (v) => setState(() => saveAsRoutine = v),
              title: Text(
                "Save as Routine",
                style: GoogleFonts.orbitron(color: Colors.white, fontSize: 13),
              ),
              thumbColor: WidgetStateProperty.all(Colors.blueAccent),
            ),

            Expanded(
              child: intervals.isEmpty
                  ? Center(
                child: Text("No intervals added",
                    style: GoogleFonts.orbitron(
                        color: Colors.grey, fontSize: 13)),
              )
                  : ListView.builder(
                itemCount: intervals.length,
                itemBuilder: (_, i) {
                  final item = intervals[i];
                  return ListTile(
                    title: Text(item.name,
                        style: GoogleFonts.orbitron(
                            color: Colors.white, fontSize: 14)),
                    trailing: Text("${item.seconds}s",
                        style: GoogleFonts.orbitron(
                            color: Colors.white70, fontSize: 13)),
                    onTap: () => _openDialog(interval: item, index: i),
                  );
                },
              ),
            ),

            ElevatedButton(
              onPressed: () => _openDialog(),
              child: const Text("Add Interval"),
            ),
            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: intervals.isEmpty ? null : _startTimer,
              child: const Text("Start Timer"),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
