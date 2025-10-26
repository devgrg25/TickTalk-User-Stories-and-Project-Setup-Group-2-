import 'package:flutter/material.dart';
import 'countdown_screen.dart';
import 'timer_model.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'widgets/global_scaffold.dart'; // ✅ Global mic wrapper

class CreateTimerScreen extends StatefulWidget {
  final TimerData? existingTimer;
  const CreateTimerScreen({super.key, this.existingTimer});

  @override
  State<CreateTimerScreen> createState() => _CreateTimerScreenState();
}

class _CreateTimerScreenState extends State<CreateTimerScreen> {
  final _nameController = TextEditingController();
  final _workIntervalController = TextEditingController();
  final _breakIntervalController = TextEditingController();
  final _setsController = TextEditingController();

  late FlutterTts _tts;

  bool get _isEditing => widget.existingTimer != null;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _initTts();

    if (_isEditing) {
      _nameController.text = widget.existingTimer!.name;
      _workIntervalController.text =
          widget.existingTimer!.workInterval.toString();
      _breakIntervalController.text =
          widget.existingTimer!.breakInterval.toString();
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
    _workIntervalController.dispose();
    _breakIntervalController.dispose();
    _setsController.dispose();
    _tts.stop();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    _tts.stop();
    _tts.speak(message);
  }

  void _startCountdown() {
    int workTime = int.tryParse(_workIntervalController.text) ?? 0;
    int breakTime = int.tryParse(_breakIntervalController.text) ?? 5;
    int totalSets = int.tryParse(_setsController.text) ?? 0;

    if (workTime <= 0 || totalSets <= 0) {
      _showMessage('Please provide valid work time and sets.');
      return;
    }

    final totalTime =
        (workTime * totalSets) + (breakTime * (totalSets - 1));

    final timerData = TimerData(
      id: _isEditing
          ? widget.existingTimer!.id
          : DateTime.now().toIso8601String(),
      name: _nameController.text.isNotEmpty
          ? _nameController.text
          : 'My Timer',
      totalTime: totalTime,
      workInterval: workTime,
      breakInterval: breakTime,
      totalSets: totalSets,
      currentSet: 1,
    );

    // Return data to home
    Navigator.of(context).pop(timerData);

    // ✅ Navigate directly to CountdownScreen (it already uses GlobalScaffold internally)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CountdownScreen(timerData: timerData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF007BFF);

    return GlobalScaffold(
      appBar: AppBar(
        title: const Text(
          'Create New Timer',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),

      // ✅ FIXED: use child instead of body
      child: SingleChildScrollView(
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
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Timer Name',
                    icon: Icons.label_outline,
                    hint: 'e.g., Morning Workout',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _workIntervalController,
                    label: 'Work Interval (minutes)',
                    icon: Icons.fitness_center_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _breakIntervalController,
                    label: 'Break Interval (minutes)',
                    icon: Icons.pause_circle_outline,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _setsController,
                    label: 'Number of Sets',
                    icon: Icons.repeat,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _startCountdown,
              icon: const Icon(Icons.timer_outlined, size: 22),
              label: const Text(
                'Save and Start Timer',
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
            const SizedBox(height: 20),
            // 👇 Mic handled globally
          ],
        ),
      ),
    );
  }

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
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
          borderSide: BorderSide(color: primaryBlue, width: 2.0),
        ),
      ),
    );
  }
}
