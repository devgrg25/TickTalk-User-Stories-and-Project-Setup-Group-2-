import 'package:flutter/material.dart';
import 'countdown_screen.dart';
import '../../logic/models/timer_model.dart';

class CreateTimerScreen extends StatefulWidget {
  final TimerData? existingTimer;
  final Function(TimerData)? onSaveTimer;

  const CreateTimerScreen({super.key, this.existingTimer, this.onSaveTimer});

  @override
  State<CreateTimerScreen> createState() => _CreateTimerScreenState();
}

class _CreateTimerScreenState extends State<CreateTimerScreen> {
  final _nameController = TextEditingController();
  final _workIntervalController = TextEditingController();
  final _breakIntervalController = TextEditingController();
  final _setsController = TextEditingController();

  bool get _isEditing => widget.existingTimer != null;

  @override
  void initState() {
    super.initState();

    // Pre-fill form if editing an existing timer
    if (_isEditing) {
      _nameController.text = widget.existingTimer!.name;
      _workIntervalController.text =
          widget.existingTimer!.workInterval.toString();
      _breakIntervalController.text =
          widget.existingTimer!.breakInterval.toString();
      _setsController.text = widget.existingTimer!.totalSets.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _workIntervalController.dispose();
    _breakIntervalController.dispose();
    _setsController.dispose();
    super.dispose();
  }

  // Core logic to start or save a timer
  void startCountdown({int? simpleTimerMinutes}) {
    int workTime;
    int breakTime;
    int totalSets;

    if (simpleTimerMinutes != null) {
      // Simple quick timer
      workTime = simpleTimerMinutes;
      breakTime = 0;
      totalSets = 1;
    } else {
      workTime = int.tryParse(_workIntervalController.text) ?? 0;
      breakTime = int.tryParse(_breakIntervalController.text) ?? 5;
      totalSets = int.tryParse(_setsController.text) ?? 0;
    }

    if (workTime <= 0 || totalSets <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a valid time or number of sets.'),
        ),
      );
      return;
    }

    final calculatedTotalTime =
        ((workTime * totalSets) + (breakTime * (totalSets - 1))) * 60;

    final timerData = TimerData(
      id: _isEditing
          ? widget.existingTimer!.id
          : DateTime.now().toIso8601String(),
      name: _nameController.text.isNotEmpty
          ? _nameController.text
          : (simpleTimerMinutes != null ? 'Quick Timer' : 'My Timer'),
      totalTime: calculatedTotalTime,
      workInterval: workTime,
      breakInterval: breakTime,
      totalSets: totalSets,
      currentSet: 1,
    );

    widget.onSaveTimer?.call(timerData);

    // Navigation handled by parent or router
  }

  // --- UI BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create New Timer',
            style: TextStyle(color: Colors.black)),
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
          const SizedBox(height: 20),

          // Voice Command Placeholder
          _buildSectionCard(
            child: Column(
              children: [
                const Text(
                  'Voice Command (Coming Soon)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  'You’ll soon be able to create a timer by speaking commands like:',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  '"Start a study timer for 4 sets with 25-minute work and 5-minute breaks."',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  onPressed: () {},
                  backgroundColor: primaryBlue,
                  child:
                  const Icon(Icons.mic_none_outlined, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Voice control disabled in this build',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Save button
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

  // --- Helper Widgets ---
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
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
          borderSide: BorderSide(color: primaryBlue, width: 2.0),
        ),
      ),
    );
  }
}
