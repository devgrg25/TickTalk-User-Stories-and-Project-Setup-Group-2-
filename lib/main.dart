import 'package:flutter/material.dart';
import 'app_shell/main_shell.dart';

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
      home: const MainShell(),
    );
  }
}
