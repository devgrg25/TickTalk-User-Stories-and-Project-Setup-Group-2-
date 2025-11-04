import 'package:flutter/material.dart';
import 'dart:math' as math;
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

class _CreateTimerScreenState extends State<CreateTimerScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _workIntervalController = TextEditingController();
  final _breakIntervalController = TextEditingController();
  final _setsController = TextEditingController();

  late FlutterTts _tts;
  late AnimationController _clockController;

  bool get _isEditing => widget.existingTimer != null;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _initTts();

    _clockController =
    AnimationController(vsync: this, duration: const Duration(seconds: 60))
      ..repeat();

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
    _clockController.dispose();
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

    Navigator.of(context).pop(timerData);
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
          'Create Timer',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),

      // 🧩 ONE-PAGE COMPACT BODY (no scroll)
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🔹 TIMER DETAILS (compact card style)
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Timer Details',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Name',
                    icon: Icons.label_outline,
                    hint: 'e.g., Workout Routine',
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _workIntervalController,
                          label: 'Work (min)',
                          icon: Icons.fitness_center_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField(
                          controller: _breakIntervalController,
                          label: 'Break (min)',
                          icon: Icons.pause_circle_outline,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: _setsController,
                    label: 'Sets',
                    icon: Icons.repeat,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // 🔹 METALLIC CLOCK (Tap to Start)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _startCountdown,
                    child: CustomPaint(
                      size: const Size(180, 180),
                      painter: _MetallicClockPainter(
                        animation: _clockController,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tap the clock to start',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
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
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
        labelText: label,
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
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

class _MetallicClockPainter extends CustomPainter {
  final Animation<double> animation;
  _MetallicClockPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Metallic gradient background
    final basePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF444444), Color(0xFF222222)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, basePaint);

    // Border ring
    final borderPaint = Paint()
      ..color = Colors.grey.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius - 4, borderPaint);

    final now = DateTime.now();
    final secondAngle = (now.second + animation.value * 60) * 6 * math.pi / 180;
    final minuteAngle = (now.minute + now.second / 60) * 6 * math.pi / 180;
    final hourAngle =
        ((now.hour % 12) + now.minute / 60) * 30 * math.pi / 180;

    // Hour hand
    final hourHand = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        center,
        Offset(center.dx + 35 * math.sin(hourAngle),
            center.dy - 35 * math.cos(hourAngle)),
        hourHand);

    // Minute hand
    final minuteHand = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        center,
        Offset(center.dx + 50 * math.sin(minuteAngle),
            center.dy - 50 * math.cos(minuteAngle)),
        minuteHand);

    // Second hand
    final secondHand = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        center,
        Offset(center.dx + 60 * math.sin(secondAngle),
            center.dy - 60 * math.cos(secondAngle)),
        secondHand);

    // Center pin
    final pin = Paint()..color = Colors.grey.shade800;
    canvas.drawCircle(center, 6, pin);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
