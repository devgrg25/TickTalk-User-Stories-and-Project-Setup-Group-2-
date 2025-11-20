import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_shell/main_shell.dart';

// NEW: Import stopwatch pages
import 'package:ticktalk_app/UI/stopwatch/stopwatch_selector_page.dart';
import 'package:ticktalk_app/UI/stopwatch/normal_stopwatch_page.dart';

// NEW: Welcome page
import 'UI/welcome_page/welcome_page.dart';

// 🔹 NEW: font scale
import 'UI/settings/font_scale.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

// 🔹 CHANGED: make main async and load FontScale before runApp
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FontScale.instance.load(); // load saved font scale
  runApp(const TickTalkApp());
}

class TickTalkApp extends StatelessWidget {
  const TickTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔹 NEW: rebuild when font scale changes
    return AnimatedBuilder(
      animation: FontScale.instance,
      builder: (context, _) {
        final scale = FontScale.instance.scale;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "TickTalk",
          theme: ThemeData.dark(),
          navigatorObservers: [routeObserver],

          // ✅ Stopwatch routes stay the same
          routes: {
            "/stopwatch": (context) => const StopwatchSelectorPage(),
            "/normalStopwatch": (context) => const NormalStopwatchPage(),
          },

          // 🔹 NEW: apply global text scale
          builder: (context, child) {
            if (child == null) return const SizedBox.shrink();
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(scale),
              ),
              child: child,
            );
          },

          // ✅ Decide whether to show WelcomePage or MainShell
          home: const _StartupWrapper(),
        );
      },
    );
  }
}

class _StartupWrapper extends StatefulWidget {
  const _StartupWrapper({super.key});

  @override
  State<_StartupWrapper> createState() => _StartupWrapperState();
}

class _StartupWrapperState extends State<_StartupWrapper> {
  bool? _hasSeenWelcome;

  @override
  void initState() {
    super.initState();
    _loadFlag();
  }

  Future<void> _loadFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('hasSeenWelcome') ?? false;
    if (!mounted) return;
    setState(() {
      _hasSeenWelcome = seen;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Small loading screen while we read SharedPreferences
    if (_hasSeenWelcome == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If user has already seen the welcome, go straight to new UI
    if (_hasSeenWelcome!) {
      return const MainShell();
    }

    // First time → show voice-based WelcomePage
    return const WelcomePage();
  }
}
