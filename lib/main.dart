import 'package:flutter/material.dart';
import 'app_shell/main_shell.dart';

// NEW: Import stopwatch pages
import 'package:ticktalk_app/UI/stopwatch/stopwatch_selector_page.dart';
import 'package:ticktalk_app/UI/stopwatch/normal_stopwatch_page.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() {
  runApp(const TickTalkApp());
}

class TickTalkApp extends StatelessWidget {
  const TickTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "TickTalk",
      theme: ThemeData.dark(),
      navigatorObservers: [routeObserver],

      // ✅ Add stopwatch routes here
      routes: {
        "/stopwatch": (context) => const StopwatchSelectorPage(),
        "/normalStopwatch": (context) => const NormalStopwatchPage(),
      },

      home: const MainShell(),
    );
  }
}
