import 'package:flutter/material.dart';
import 'app_shell/main_shell.dart';
import 'UI/settings/font_scale.dart';  // 👈 NEW

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

// 👇 make main async so we can load the saved font scale
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FontScale.instance.load(); // load saved font size
  runApp(const TickTalkApp());
}

class TickTalkApp extends StatelessWidget {
  const TickTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild app whenever FontScale changes
    return AnimatedBuilder(
      animation: FontScale.instance,
      builder: (context, _) {
        final scale = FontScale.instance.scale;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "TickTalk",
          theme: ThemeData.dark(),
          navigatorObservers: [routeObserver],

          // Apply global text scaling
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

          home: const MainShell(),
        );
      },
    );
  }
}