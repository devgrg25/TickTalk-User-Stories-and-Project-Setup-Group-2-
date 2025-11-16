import 'package:flutter/material.dart';
import '../../../logic/routines/routine_storage.dart';
import '../../../logic/routines/routine_model.dart';
import '../../../logic/timer/timer_controller.dart';

class EditRoutinePage extends StatefulWidget {
  final Routine? existing;

  const EditRoutinePage({super.key, this.existing});

  @override
  State<EditRoutinePage> createState() => _EditRoutinePageState();
}

class _EditRoutinePageState extends State<EditRoutinePage> {
  final nameCtrl = TextEditingController();
  List<TimerInterval> intervals = [];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      nameCtrl.text = widget.existing!.name;
      intervals = widget.existing!.intervals
          .map((i) => TimerInterval(name: i.name, seconds: i.seconds))
          .toList();
    }
  }

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
          style: const TextStyle(color: Colors.white),
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
              child: const Text("Cancel", style: TextStyle(color: Colors.red))),
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

  Future<void> _save() async {
    final name = nameCtrl.text.trim();
    if (name.isEmpty || intervals.isEmpty) return;

    final routine = Routine(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.toUpperCase(),
      intervals: intervals,
    );

    await RoutineStorage.instance.saveRoutine(routine);

    if (mounted) Navigator.pop(context);
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
              widget.existing == null ? "New Routine" : "Edit Routine",
              style: const TextStyle(color: Colors.white, fontSize: 22),
            ),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Routine Name",
                  labelStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: intervals.isEmpty
                  ? const Center(
                  child: Text("No intervals added",
                      style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                itemCount: intervals.length,
                itemBuilder: (_, i) {
                  final item = intervals[i];
                  return ListTile(
                    title: Text(item.name,
                        style: const TextStyle(color: Colors.white)),
                    trailing: Text("${item.seconds}s",
                        style: const TextStyle(color: Colors.white70)),
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
              onPressed: intervals.isEmpty ? null : _save,
              child: const Text("Save Routine"),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
