import 'package:flutter/material.dart';
import 'countdown_screen.dart';

class CreateTimer extends StatefulWidget {
  const CreateTimer({super.key});

  @override
  State<CreateTimer> createState() => _CreateTimerState();
}

class _CreateTimerState extends State<CreateTimer> {
  final hCtrl = TextEditingController(text: "0");
  final mCtrl = TextEditingController(text: "0");
  final sCtrl = TextEditingController(text: "0");

  int _totalSeconds() {
    final h = int.tryParse(hCtrl.text) ?? 0;
    final m = int.tryParse(mCtrl.text) ?? 0;
    final s = int.tryParse(sCtrl.text) ?? 0;
    return h * 3600 + m * 60 + s;
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: viewInsets),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 340,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              margin: EdgeInsets.only(
                top: screenHeight < 650 ? 12 : 50,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF171717),
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    offset: Offset(2, 5),
                    blurRadius: 12,
                    color: Colors.black54,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Create Timer",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 24),

                  _inputField("Hours", hCtrl),
                  _inputField("Minutes", mCtrl),
                  _inputField("Seconds", sCtrl),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _smallButton("Clear", () {
                        hCtrl.text = "0";
                        mCtrl.text = "0";
                        sCtrl.text = "0";
                        setState(() {});
                      }),
                      const SizedBox(width: 10),
                      _bigButton("Start", () {
                        if (_totalSeconds() <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Please enter a valid time.")),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CountdownScreen(totalSeconds: _totalSeconds()),
                          ),
                        );
                      }),
                    ],
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            offset: Offset(2, 5),
            blurRadius: 10,
            color: Color(0xFF050505),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(color: Color(0xFFD3D3D3)),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallButton(String text, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        backgroundColor: const Color(0xFF252525),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      onPressed: onTap,
      child: Text(text),
    );
  }

  Widget _bigButton(String text, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 10),
        backgroundColor: const Color(0xFF252525),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      onPressed: onTap,
      child: Text(text),
    );
  }
}
