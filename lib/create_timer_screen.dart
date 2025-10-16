import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'countdown_screen.dart';

class TimerData {
  final String name;
  final int totalTime;
  final int workInterval;
  final int breakInterval;

  TimerData({
    required this.name,
    required this.totalTime,
    required this.workInterval,
    required this.breakInterval,
  });
}

class CreateTimerScreen extends StatefulWidget {
  const CreateTimerScreen({super.key});

  @override
  State<CreateTimerScreen> createState() => _CreateTimerScreenState();
}

class _CreateTimerScreenState extends State<CreateTimerScreen> {
  // --- STATE FOR THE FORM & VOICE ---
  final _nameController = TextEditingController();
  final _totalTimeController = TextEditingController();
  final _workIntervalController = TextEditingController();
  final _breakIntervalController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _lastHeard = "Tap the mic and speak a command...";

  @override
  void initState() {
    super.initState();
    _speech.initialize();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalTimeController.dispose();
    _workIntervalController.dispose();
    _breakIntervalController.dispose();
    super.dispose();
  }

  // --- VOICE COMMAND LOGIC ---
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _lastHeard = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _parseVoiceCommand(_lastHeard);
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _parseVoiceCommand(String command) {
    final commandLower = command.toLowerCase();
    bool commandRecognized = false;

    final nameMatch = RegExp(r'start a (.*?) timer').firstMatch(commandLower);
    final workMatch = RegExp(r'(\d+)\s*minute work').firstMatch(commandLower);
    final breakMatch = RegExp(r'(\d+)\s*minute break').firstMatch(commandLower);

    if (nameMatch != null) {
      _nameController.text = nameMatch.group(1)!;
      commandRecognized = true;
    }
    if (workMatch != null) {
      _workIntervalController.text = workMatch.group(1)!;
      _totalTimeController.text = workMatch.group(1)!;
      commandRecognized = true;
    }
    if (breakMatch != null) {
      _breakIntervalController.text = breakMatch.group(1)!;
      commandRecognized = true;
    }

    if (commandLower.startsWith('start') && commandRecognized) {
      _speech.stop();
      setState(() => _isListening = false);
      _startCountdown();
    }
  }

  // --- NAVIGATION LOGIC ---
  void _startCountdown() {
    // Basic validation
    if (_workIntervalController.text.isEmpty || _totalTimeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all time fields.')),
      );
      return;
    }

    final totalTime = int.tryParse(_totalTimeController.text);
    final workTime = int.tryParse(_workIntervalController.text);

    if (totalTime == null || workTime == null || workTime > totalTime) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Work interval cannot be greater than total time.')),
      );
      return;
    }

    final timerData = TimerData(
      name: _nameController.text.isNotEmpty ? _nameController.text : 'My Timer',
      totalTime: totalTime,
      workInterval: workTime,
      breakInterval: int.tryParse(_breakIntervalController.text) ?? 5,
    );

    // Navigate to the separate countdown screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CountdownScreen(timerData: timerData),
      ),
    );
  }

  // --- UI BUILDERS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Timer'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: _buildFormUI(), // Directly build the form UI
    );
  }

  Widget _buildFormUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionCard(
            child: Column(
              children: [
                _buildTextField(controller: _nameController, label: 'Timer Name', icon: Icons.label_outline, hint: 'e.g., Morning Workout'),
                const SizedBox(height: 16),
                _buildTextField(controller: _totalTimeController, label: 'Total Time (minutes)', icon: Icons.hourglass_bottom_outlined, keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildTextField(controller: _workIntervalController, label: 'Work Interval (minutes)', icon: Icons.fitness_center_outlined, keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildTextField(controller: _breakIntervalController, label: 'Break Interval (minutes)', icon: Icons.pause_circle_outline, keyboardType: TextInputType.number),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            child: Column(
              children: [
                Text('Or Use a Voice Command', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                  '"Start a study timer with 25 minute work and 5 minute break intervals."',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  onPressed: _listen,
                  backgroundColor: Colors.blue.shade600,
                  child: Icon(_isListening ? Icons.mic : Icons.mic_off, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(_isListening ? "Listening..." : _lastHeard, style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _startCountdown,
            icon: const Icon(Icons.timer_outlined),
            label: const Text('Save and Start Timer'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildSectionCard({required Widget child}) { return Card(elevation: 2, shadowColor: Colors.grey.withAlpha((0.3 * 255).round()), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(16.0), child: child));}
  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, String? hint, TextInputType keyboardType = TextInputType.text}) { return TextField(controller: controller, keyboardType: keyboardType, decoration: InputDecoration(prefixIcon: Icon(icon, color: Colors.grey[600]), labelText: label, hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)), filled: true, fillColor: Colors.grey[50]));}
}