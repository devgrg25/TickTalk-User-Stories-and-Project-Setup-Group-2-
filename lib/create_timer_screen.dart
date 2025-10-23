import 'package:flutter/material.dart';
import 'timer_model.dart';
import 'package:flutter/services.dart'; // For number input formatting

class CreateTimerScreen extends StatefulWidget {
  final TimerData? existingTimer;
  const CreateTimerScreen({super.key, this.existingTimer});

  @override
  State<CreateTimerScreen> createState() => _CreateTimerScreenState();
}

class _CreateTimerScreenState extends State<CreateTimerScreen> {
  final _nameController = TextEditingController();
  List<TimerStep> _steps = [];

  bool get _isEditing => widget.existingTimer != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.existingTimer!.name;
      // Copy the list of steps
      _steps = List<TimerStep>.from(widget.existingTimer!.steps);
    } else {
      // Start with one empty step for convenience
      _steps = [TimerStep(name: '', durationInMinutes: 0)];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // --- LOGIC FOR MANAGING STEPS ---

  void _addStep() {
    setState(() {
      _steps.add(TimerStep(name: '', durationInMinutes: 0));
    });
  }

  void _removeStep(int index) {
    if (_steps.length > 1) {
      setState(() {
        _steps.removeAt(index);
      });
    } else {
      // Show snackbar if user tries to remove the last step
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A timer must have at least one step.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _updateStepName(int index, String name) {
    _steps[index] = TimerStep(name: name, durationInMinutes: _steps[index].durationInMinutes);
  }

  void _updateStepDuration(int index, String duration) {
    final int minutes = int.tryParse(duration) ?? 0;
    _steps[index] = TimerStep(name: _steps[index].name, durationInMinutes: minutes);
  }

  void _saveTimer() {
    // 1. Validate inputs
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a timer name.')),
      );
      return;
    }

    // Check for any invalid steps
    for (var step in _steps) {
      if (step.name.isEmpty || step.durationInMinutes <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All steps must have a name and a duration greater than 0.')),
        );
        return;
      }
    }

    // 2. Create the new TimerData object
    final timerData = TimerData(
      id: _isEditing ? widget.existingTimer!.id : DateTime.now().toIso8601String(),
      name: _nameController.text,
      steps: _steps,
    );

    // 3. Return the saved data to the previous screen (HomeScreen)
    Navigator.of(context).pop(timerData);
  }

  // --- UI BUILDER ---
  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF007BFF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Timer' : 'Create New Timer', style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Timer Name ---
                  _buildSectionCard(
                    child: _buildTextField(
                      controller: _nameController,
                      label: 'Timer Name',
                      icon: Icons.label_outline,
                      hint: 'e.g., Morning Workout',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Steps List ---
                  const Text(
                    'Timer Steps',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _steps.length,
                    itemBuilder: (context, index) {
                      return _buildStepCard(index);
                    },
                  ),
                  const SizedBox(height: 12),

                  // --- Add Step Button ---
                  Center(
                    child: TextButton.icon(
                      onPressed: _addStep,
                      icon: const Icon(Icons.add_circle_outline, color: primaryBlue),
                      label: const Text('Add Step', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Save Button ---
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: SafeArea(
              child: ElevatedButton.icon(
                onPressed: _saveTimer,
                icon: const Icon(Icons.save_outlined, size: 22),
                label: Text(
                  _isEditing ? 'Save Changes' : 'Save Timer',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildStepCard(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: const Color(0xFFF9FAFB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Step Number
            CircleAvatar(
              backgroundColor: const Color(0xFF007BFF),
              child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            // Text Fields
            Expanded(
              child: Column(
                children: [
                  TextFormField(
                    initialValue: _steps[index].name,
                    decoration: const InputDecoration(labelText: 'Step Name', isDense: true),
                    onChanged: (name) => _updateStepName(index, name),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _steps[index].durationInMinutes == 0 ? '' : _steps[index].durationInMinutes.toString(),
                    decoration: const InputDecoration(labelText: 'Duration (minutes)', isDense: true),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (duration) => _updateStepDuration(index, duration),
                  ),
                ],
              ),
            ),
            // Remove Button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _removeStep(index),
            ),
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
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Color(0xFF007BFF), width: 2.0)),
      ),
    );
  }
}