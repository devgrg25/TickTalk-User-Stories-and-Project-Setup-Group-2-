import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'routine_timer_model.dart';
import 'voice_controller.dart';

class CreateRoutinePage extends StatefulWidget {
  final TimerDataV? routineToEdit;

  const CreateRoutinePage({super.key, this.routineToEdit});

  @override
  State<CreateRoutinePage> createState() => _CreateRoutinePageState();
}

class _CreateRoutinePageState extends State<CreateRoutinePage> {
  final _nameController = TextEditingController();
  final List<Map<String, TextEditingController>> _stepControllers = [];

  // Voice Control
  final VoiceController _voiceController = VoiceController();
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initVoice();

    if (widget.routineToEdit != null) {
      _nameController.text = widget.routineToEdit!.name;
      for (var step in widget.routineToEdit!.steps) {
        _stepControllers.add({
          'name': TextEditingController(text: step.name),
          'duration': TextEditingController(text: step.durationInMinutes.toString()),
        });
      }
    }

    if (_stepControllers.isEmpty) {
      _addStep();
    }
  }

  Future<void> _initVoice() async {
    await _voiceController.initialize();
    await _tts.setLanguage("en-US");
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var step in _stepControllers) {
      step['name']!.dispose();
      step['duration']!.dispose();
    }
    // _voiceController.dispose(); // Optional: depends on if you want to keep it alive
    super.dispose();
  }

  void _addStep() {
    setState(() {
      _stepControllers.add({
        'name': TextEditingController(),
        'duration': TextEditingController(),
      });
    });
  }

  void _removeStep(int index) {
    if (_stepControllers.length > 1) {
      setState(() {
        _stepControllers[index]['name']!.dispose();
        _stepControllers[index]['duration']!.dispose();
        _stepControllers.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot remove the last step.')),
      );
    }
  }

  void _saveRoutine({bool runNow = false}) {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please give your routine a name.')),
      );
      return;
    }

    List<TimerStep> steps = [];
    for (var controllers in _stepControllers) {
      String name = controllers['name']!.text.trim();
      int duration = int.tryParse(controllers['duration']!.text.trim()) ?? 0;

      if (name.isNotEmpty && duration > 0) {
        steps.add(TimerStep(name: name, durationInMinutes: duration));
      }
    }

    if (steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one valid step.')),
      );
      return;
    }

    final TimerDataV savedRoutine = widget.routineToEdit != null
        ? TimerDataV(
      id: widget.routineToEdit!.id,
      name: _nameController.text.trim(),
      steps: steps,
      isCustom: true,
      isFavorite: widget.routineToEdit!.isFavorite,
    )
        : TimerDataV(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      steps: steps,
      isCustom: true,
      isFavorite: false,
    );

    Navigator.pop(context, {
      'routine': savedRoutine,
      'runNow': runNow,
    });
  }

  // --- Voice Listening ---
  Future<void> _startListening() async {
    if (!_voiceController.isInitialized) return;
    setState(() => _isListening = true);
    await _tts.speak("Listening...");
    await _voiceController.listenAndRecognize(
      onCommandRecognized: (cmd) {
        final command = cmd.toLowerCase();
        if (command.contains('cancel') || command.contains('close') || command.contains('go back')) {
          Navigator.pop(context);
        } else if (command.contains('save')) {
          // Trigger save if they say "save"
          _saveRoutine(runNow: false);
        }
      },
      onComplete: () {
        if (mounted) setState(() => _isListening = false);
      },
    );
  }

  Future<void> _stopListening() async {
    await _voiceController.stopListening();
    if (mounted) setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routineToEdit != null ? 'Edit Routine' : 'Create Routine',
            style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        actions: [
          TextButton(
            onPressed: () => _saveRoutine(runNow: false),
            child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
      body: Padding(
        // Add padding at the bottom so the last element isn't hidden behind the mic bar
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Routine Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Steps', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                itemCount: _stepControllers.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF007BFF).withOpacity(0.1),
                            child: Text('${index + 1}',
                                style: const TextStyle(color: Color(0xFF007BFF), fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _stepControllers[index]['name'],
                              decoration: const InputDecoration(
                                labelText: 'Step Name',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: _stepControllers[index]['duration'],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Min',
                                border: InputBorder.none,
                                suffixText: 'm',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                            onPressed: () => _removeStep(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // --- Bottom Buttons ---
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addStep,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Step'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _saveRoutine(runNow: true),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Save & Run'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      // --- Global Microphone Button ---
      bottomSheet: SafeArea(
        child: GestureDetector(
          onTap: _isListening ? _stopListening : _startListening,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            color: _isListening ? Colors.redAccent : const Color(0xFF007BFF),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}