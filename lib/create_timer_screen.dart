import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'timer_models/timer_model.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'controllers/mic_controller.dart';

class CreateTimerScreen extends StatefulWidget {
  final TimerData? existingTimer;
  final Function(TimerData)? onSaveTimer;
  final bool startVoiceConfirmation;

  const CreateTimerScreen({super.key, this.existingTimer, this.onSaveTimer, this.startVoiceConfirmation = false,});


  @override
  State<CreateTimerScreen> createState() => _CreateTimerScreenState();
}

class _CreateTimerScreenState extends State<CreateTimerScreen> {
  late FlutterTts _tts;
  final stt.SpeechToText _speech = stt.SpeechToText();

  final _nameController = TextEditingController();
  final _workIntervalController = TextEditingController();
  final _breakIntervalController = TextEditingController();
  final _setsController = TextEditingController();

  bool _isListening = false;
  String _lastHeard = "This shows the last spoken command";

  // Check if we are in "edit" mode
  bool get _isEditing => widget.existingTimer != null;

  @override
  void initState() {
    super.initState();
    _speech.initialize();
    _tts = FlutterTts();
    _initTts();
    // If we are editing, pre-fill the form fields
    if (_isEditing) {
      _nameController.text = widget.existingTimer!.name;
      _workIntervalController.text = widget.existingTimer!.workInterval.toString();
      _breakIntervalController.text = widget.existingTimer!.breakInterval.toString();
      _setsController.text = widget.existingTimer!.totalSets.toString();
    }
    if (widget.startVoiceConfirmation && widget.existingTimer != null) {
      // We must wait for the screen to build before speaking
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confirmTimerWithVoice(widget.existingTimer!);
      });
    }
  }

  @override
  void didUpdateWidget(CreateTimerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the screen is now in editing mode and the timer changed, update fields
    if (widget.existingTimer != null &&
        widget.existingTimer != oldWidget.existingTimer) {
      _nameController.text = widget.existingTimer!.name;
      _workIntervalController.text = widget.existingTimer!.workInterval.toString();
      _breakIntervalController.text = widget.existingTimer!.breakInterval.toString();
      _setsController.text = widget.existingTimer!.totalSets.toString();
    }
  }


  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    // REMOVED: Dispose the controller that was removed.
    // _totalTimeController.dispose();
    _workIntervalController.dispose();
    _breakIntervalController.dispose();
    _setsController.dispose();
    _tts.stop(); // stop any ongoing speech
    _speech.stop();

    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    _tts.stop(); // stop any ongoing speech
    _tts.speak(message); // read out the message
  }

  Future<void> _confirmTimerWithVoice(TimerData timerData) async {
    final name = timerData.name;
    final work = timerData.workInterval;
    final rest = timerData.breakInterval;
    final sets = timerData.totalSets;

    final confirmationText = rest > 0
        ? "You created a timer named $name. Work for $work minutes, break for $rest minutes, for $sets sets. Should I start?"
        : "You created a timer named $name for $work minutes. Should I start?";

    await _tts.stop();
    await _tts.speak(confirmationText);

    // Start listening for yes/no answer
    bool available = await _speech.initialize();
    if (!available) return;

    setState(() => _isListening = true);

    await _speech.listen(
      listenFor: const Duration(seconds: 5),
      onResult: (result) async {
        final spoken = result.recognizedWords.toLowerCase();
        setState(() => _lastHeard = spoken);

        if (spoken.contains("yes") || spoken.contains("start")) {
          await _tts.speak("Starting now.");
          widget.onSaveTimer?.call(timerData);
        } else if (spoken.contains("no") || spoken.contains("cancel")) {
          await _tts.speak("Okay, cancelled.");
        }

        _speech.stop();
        setState(() => _isListening = false);
      },
    );
  }

  // UPDATED: Core logic for starting the timer is changed here.
  void startCountdown({int? simpleTimerMinutes}) {

    int workTime;
    int breakTime;
    int totalSets;

    // 1. Get values and provide defaults for optional fields.
    if (simpleTimerMinutes != null) {
      // --- Simple timer mode ---
      workTime = simpleTimerMinutes;
      breakTime = 0;
      totalSets = 1;
    } else {
        workTime = int.tryParse(_workIntervalController.text) ?? 0;
        breakTime = int.tryParse(_breakIntervalController.text) ?? 5; // Default break is 5 mins
        totalSets = int.tryParse(_setsController.text) ?? 0;
    }

    // 2. Validate essential inputs.
    if (workTime <= 0 || totalSets <= 0) {
      _showMessage('Please provide a valid time or number of sets.');
      return;
    }

    // 3. Calculate the total time automatically.
    // Total Time = (Work Time * Number of Sets) + (Break Time * (Number of Sets - 1))
    // The (sets - 1) ensures no break time is added after the final set.
    final calculatedTotalTime = ((workTime * totalSets) + (breakTime * (totalSets - 1)))*60;

    // 4. Create the TimerData object.
    final timerData = TimerData(
      id: _isEditing ? widget.existingTimer!.id : DateTime.now().toIso8601String(),
      name: _nameController.text.isNotEmpty
          ? _nameController.text
          : (simpleTimerMinutes != null ? 'Quick Timer' : 'My Timer'),
      totalTime: calculatedTotalTime, // Use the calculated time
      workInterval: workTime,
      breakInterval: breakTime,
      totalSets: totalSets,
      currentSet: 1,
    );

    //widget.onSaveTimer?.call(timerData);
    //_confirmTimerWithVoice(timerData);
    final bool isTrulyEditing = _isEditing && !widget.startVoiceConfirmation;

    if (isTrulyEditing) {
      // User tapped "Edit" on an old timer and is now saving.
      // Just save immediately.
      widget.onSaveTimer?.call(timerData);
    } else {
      // This is either a NEW manual timer OR a voice-filled timer.
      // In both cases, run the voice confirmation.
      _confirmTimerWithVoice(timerData);
    }

  }

  // --- routines BUILDERS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create New Timer', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
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
                const SizedBox(height: 8),
                Text(_isListening ? "Listening..." : _lastHeard,
                    style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: startCountdown,
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