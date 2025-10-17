import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'countdown_screen.dart';

// TimerData class remains the same
class TimerData {
  final String name;
  final int totalTime;
  final int workInterval;
  final int breakInterval;
  final int currentSet;
  final int totalSets;

  TimerData({
    required this.name,
    required this.totalTime,
    required this.workInterval,
    required this.breakInterval,
    required this.currentSet,
    required this.totalSets,
  });
}

class CreateTimerScreen extends StatefulWidget {
  const CreateTimerScreen({super.key});

  @override
  State<CreateTimerScreen> createState() => _CreateTimerScreenState();
}

class _CreateTimerScreenState extends State<CreateTimerScreen> {
  final _nameController = TextEditingController();
  // REMOVED: No longer need a controller for total time.
  // final _totalTimeController = TextEditingController();
  final _workIntervalController = TextEditingController();
  final _breakIntervalController = TextEditingController();
  final _setsController = TextEditingController();
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
    // REMOVED: Dispose the controller that was removed.
    // _totalTimeController.dispose();
    _workIntervalController.dispose();
    _breakIntervalController.dispose();
    _setsController.dispose();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _lastHeard = val.recognizedWords;
            // UPDATED: Process the command only on the final result for efficiency.
            if (val.finalResult) {
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

    // --- UPDATED: More flexible Regular Expressions ---

    // Captures names like "start a study timer" or "create a workout timer"
    // The '(\w+)' looks for a single word after 'a' if 'timer' isn't the next word.
    final nameMatch = RegExp(r'start a (\w+) timer|create a (\w+) timer').firstMatch(commandLower);

    // Captures "25 minute work", "work for 25 mins", "25 min focus", "30 work"
    final workMatch = RegExp(r'(\d+)\s*(?:minute|min|mins)?\s*(?:work|focus|session)|(?:work|focus|session)\s*(\d+)').firstMatch(commandLower);

    // Captures "5 minute break", "rest for 10 mins", "15 min rest", "5 break"
    final breakMatch = RegExp(r'(\d+)\s*(?:minute|min|mins)?\s*(?:break|rest)|(?:break|rest)\s*(\d+)').firstMatch(commandLower);

    // Captures "for 4 sets", "3 rounds", "do 8 sets"
    final setsMatch = RegExp(r'(\d+)\s*(?:set|sets|round|rounds)').firstMatch(commandLower);

    // --- Logic to populate fields ---

    if (nameMatch != null) {
      // Check group 1, if null, use group 2. This handles both "start a..." and "create a..."
      _nameController.text = nameMatch.group(1) ?? nameMatch.group(2) ?? '';
    }

    if (workMatch != null) {
      // Check the first capture group, if it's null, use the second one.
      // This handles cases where the number comes before or after the keyword.
      _workIntervalController.text = workMatch.group(1) ?? workMatch.group(2) ?? '';
    }

    if (breakMatch != null) {
      _breakIntervalController.text = breakMatch.group(1) ?? breakMatch.group(2) ?? '';
    }

    if (setsMatch != null) {
      _setsController.text = setsMatch.group(1) ?? '';
    }

    // --- Auto-start logic ---

    // Checks if the command contains a trigger word and essential fields have been filled.
    if (commandLower.contains('start') || commandLower.contains('create')) {
      // A small delay gives the user a moment to see the fields populate before starting.
      Future.delayed(const Duration(milliseconds: 750), () {
        if (mounted && _workIntervalController.text.isNotEmpty && _setsController.text.isNotEmpty) {
          _speech.stop();
          setState(() => _isListening = false);
          _startCountdown();
        }
      });
    }
  }

  // UPDATED: Core logic for starting the timer is changed here.
  void _startCountdown() {
    // 1. Get values and provide defaults for optional fields.
    final workTime = int.tryParse(_workIntervalController.text);
    final breakTime = int.tryParse(_breakIntervalController.text) ?? 5; // Default break is 5 mins
    final totalSets = int.tryParse(_setsController.text);

    // 2. Validate essential inputs.
    if (workTime == null || totalSets == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Work interval and number of sets are required.')),
      );
      return;
    }

    if (workTime <= 0 || totalSets <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Work time and sets must be greater than zero.')),
      );
      return;
    }

    // 3. Calculate the total time automatically.
    // Total Time = (Work Time * Number of Sets) + (Break Time * (Number of Sets - 1))
    // The (sets - 1) ensures no break time is added after the final set.
    final calculatedTotalTime = (workTime * totalSets) + (breakTime * (totalSets - 1));

    // 4. Create the TimerData object.
    final timerData = TimerData(
      name: _nameController.text.isNotEmpty ? _nameController.text : 'My Timer',
      totalTime: calculatedTotalTime, // Use the calculated time
      workInterval: workTime,
      breakInterval: breakTime,
      totalSets: totalSets,
      currentSet: 1,
    );

    // 5. Navigate to the countdown screen.
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create New Timer', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: _buildFormUI(),
    );
  }

  Widget _buildFormUI() {
    const Color primaryBlue = Color(0xFF007BFF);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Timer Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                    controller: _nameController,
                    label: 'Timer Name',
                    icon: Icons.label_outline,
                    hint: 'e.g., Morning Workout'),
                const SizedBox(height: 16),
                // REMOVED: The text field for Total Time is gone from the UI.
                _buildTextField(
                    controller: _workIntervalController,
                    label: 'Work Interval (minutes)',
                    icon: Icons.fitness_center_outlined,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildTextField(
                    controller: _breakIntervalController,
                    label: 'Break Interval (minutes)',
                    icon: Icons.pause_circle_outline,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildTextField(
                    controller: _setsController,
                    label: 'Number of Sets',
                    icon: Icons.repeat,
                    keyboardType: TextInputType.number),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            // ... (The voice command card remains the same)
            child: Column(
              children: [
                const Text(
                  'Or Use a Voice Command',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  '"Start a study timer for 4 sets with 25 minute work and 5 minute break."',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  onPressed: _listen,
                  backgroundColor: primaryBlue,
                  child: Icon(_isListening ? Icons.mic : Icons.mic_off,
                      color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(_isListening ? "Listening..." : _lastHeard,
                    style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _startCountdown,
            icon: const Icon(Icons.timer_outlined, size: 22),
            label: const Text(
              'Save and Start Timer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---
  // The helper widgets _buildSectionCard and _buildTextField remain unchanged.
  Widget _buildSectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    const Color primaryBlue = Color(0xFF007BFF);

    return TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: primaryBlue, width: 2.0),
          ),
        ));
  }
}