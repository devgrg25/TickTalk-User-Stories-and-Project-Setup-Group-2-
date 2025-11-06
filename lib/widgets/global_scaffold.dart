import 'package:flutter/material.dart';
import 'global_mic_button.dart';

class GlobalScaffold extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Color backgroundColor;

  const GlobalScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: SafeArea(child: child),
      bottomSheet: const GlobalMicButton(), // permanent mic section
    );
  }
}
