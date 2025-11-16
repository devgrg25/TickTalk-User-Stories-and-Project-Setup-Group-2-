import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../timer_models/routine_timer_model.dart';

class CreateRoutinePage extends StatefulWidget {
  const CreateRoutinePage({super.key});

  @override
  State<CreateRoutinePage> createState() => _CreateRoutinePageState();
}

class _CreateRoutinePageState extends State<CreateRoutinePage> {
  // --- Data & Controllers ---
  final _nameController = TextEditingController(); // Routine Name
  final _stepNameController = TextEditingController(); // Manual Step Input
  final _stepDurationController = TextEditingController(); // Manual Duration Input

  final List<TimerStep> _steps = [];

  // --- Voice & TTS ---
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  String _lastHeard = "";

  @override
  void initState() {
    super.initState();
    _initVoice();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stepNameController.dispose();
    _stepDurationController.dispose();
    _tts.stop(); // Ensure speech stops when leaving page
    super.dispose();
  }

  void _initVoice() async {
    try {
      await _speech.initialize();
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.5);
    } catch (e) {
      debugPrint('Voice init error: $e');
    }
  }

  // --- 1. VOICE LOGIC ---
  Future<void> _toggleListening() async {
    // KEY CHANGE: Stop any active TTS message immediately when user taps mic
    await _tts.stop();

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _lastHeard = "Listening...";
        });
        _speech.listen(
          onResult: (result) {
            setState(() => _lastHeard = result.recognizedWords);
            if (result.finalResult) {
              _processVoiceCommand(result.recognizedWords);
            }
          },
          listenMode: stt.ListenMode.confirmation,
        );
      }
    }
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.stop(); // Stop previous speech before starting new
      await _tts.speak(text);
    } catch (e) { debugPrint("TTS Error: $e"); }
  }

  void _processVoiceCommand(String command) {
    final lower = command.toLowerCase().trim();
    setState(() => _isListening = false);
    _speech.stop();

    // A. SAVE
    if (lower.contains('save') || lower.contains('finish') || lower.contains('create')) {
      _saveRoutine();
      return;
    }

    // B. NAME ROUTINE
    final nameMatch = RegExp(r'(?:name|call|title)\s+(?:routine\s+)?(.+)', caseSensitive: false).firstMatch(lower);
    if (nameMatch != null) {
      final newName = nameMatch.group(1)?.trim();
      if (newName != null && newName.isNotEmpty) {
        setState(() => _nameController.text = newName);
        _speak("Routine named $newName");
        return;
      }
    }

    // C. ADD STEP
    final addStepMatch = RegExp(r'add\s+(.+?)\s+for\s+(\d+)\s*(?:min|minute|minutes)', caseSensitive: false).firstMatch(lower);
    if (addStepMatch != null) {
      final stepName = addStepMatch.group(1)?.trim();
      final durationStr = addStepMatch.group(2);

      if (stepName != null && durationStr != null) {
        final duration = int.parse(durationStr);
        _addStepDirectly(stepName, duration);
        return;
      }
    }

    // D. REMOVE LAST
    if (lower.contains("remove last") || lower.contains("delete last")) {
      if (_steps.isNotEmpty) {
        final removed = _steps.removeLast();
        setState(() {});
        _speak("Removed ${removed.name}");
      } else {
        _speak("No steps to remove");
      }
      return;
    }

    // E. ERROR / HELP MESSAGE
    _speak("I didn't catch that. Say 'Name routine' and speak your routine name, or say 'Add' followed by an activity and duration.");
  }

  // --- 2. MANUAL & HYBRID LOGIC ---

  void _addManualStep() {
    final name = _stepNameController.text.trim();
    final durationText = _stepDurationController.text.trim();

    if (name.isEmpty || durationText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in both fields')));
      return;
    }

    final duration = int.tryParse(durationText);
    if (duration == null || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid minutes')));
      return;
    }

    // Add to list
    _addStepDirectly(name, duration);

    // Clear manual inputs
    _stepNameController.clear();
    _stepDurationController.clear();
    FocusScope.of(context).unfocus(); // Hide keyboard
  }

  void _addStepDirectly(String name, int duration) {
    setState(() {
      _steps.add(TimerStep(name: name, durationInMinutes: duration));
    });
    _speak("Added $name for $duration minutes.");
  }

  void _saveRoutine() {
    final routineName = _nameController.text.trim();
    if (routineName.isEmpty) {
      _speak("Please name the routine first.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please name the routine')));
      return;
    }
    if (_steps.isEmpty) {
      _speak("Please add at least one step.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add steps')));
      return;
    }

    final newRoutine = TimerDataV(
      id: DateTime.now().toString(),
      name: routineName,
      steps: List.from(_steps),
    );

    _speak("Routine saved.");
    Navigator.pop(context, newRoutine);
  }

  // --- routines ---
  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF007BFF);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Routine"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveRoutine,
            tooltip: 'Save Routine',
          )
        ],
      ),
      body: Column(
        children: [
          // 1. Routine Name Field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Routine Name',
                hintText: 'e.g. Morning Prep',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
          ),

          // 2. Visual Feedback (Voice Log)
          if (_lastHeard.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: Colors.grey.shade100,
              child: Text(
                'Heard: "$_lastHeard"',
                style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade600, fontSize: 12),
              ),
            ),

          const Divider(height: 1),

          // 3. Steps List
          Expanded(
            child: _steps.isEmpty
                ? Center(
              child: Text(
                "No steps added yet.\nUse the form below or tap the mic.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500),
              ),
            )
                : ListView.builder(
              itemCount: _steps.length,
              itemBuilder: (ctx, i) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: primaryBlue.withOpacity(0.1),
                  child: Text('${i + 1}'),
                ),
                title: Text(_steps[i].name),
                subtitle: Text('${_steps[i].durationInMinutes} min'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => setState(() => _steps.removeAt(i)),
                ),
              ),
            ),
          ),

          // 4. Manual Entry Form (For Normal Users)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _stepNameController,
                    decoration: const InputDecoration(
                      labelText: 'Activity',
                      hintText: 'e.g. Run',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _stepDurationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Min',
                      hintText: '5',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addManualStep,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(backgroundColor: primaryBlue),
                ),
              ],
            ),
          ),

          // 5. Voice Button
          GestureDetector(
            onTap: _toggleListening,
            child: Container(
              color: _isListening ? Colors.redAccent : primaryBlue,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: SafeArea(
                top: false,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        _isListening ? "Listening..." : "Tap for Voice Command",
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}