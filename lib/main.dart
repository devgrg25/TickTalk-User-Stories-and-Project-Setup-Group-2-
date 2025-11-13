import 'package:flutter/material.dart';
import 'font_scale.dart';
import 'welcome_page.dart'; // or your launcher

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FontScale.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: FontScale.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            final base = MediaQuery.of(context);
            return MediaQuery(
              data: base.copyWith(textScaleFactor: FontScale.instance.scale),
              child: child!,
            );
          },
          home: const WelcomePage(),
        );
      },
    );
  }
}
