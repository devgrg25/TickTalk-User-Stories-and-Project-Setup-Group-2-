import 'package:flutter/material.dart';
import 'homepage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF2A2623); // Very Dark Sepia
    const textColor = Color(0xFFFFF3E9);       // Warm Cream
    const primaryColor = Color(0xFFF0B429);    // Warm Amber
    const successColor = Color(0xFF7FB58B);    // Sage Green
    const errorColor = Color(0xFFD96F4E);      // Terracotta

    return MaterialApp(
      title: 'Natural Timer App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: primaryColor,
          onPrimary: Colors.black, // text color on buttons
          secondary: successColor,
          onSecondary: Colors.black,
          error: errorColor,
          onError: Colors.white,
          background: backgroundColor,
          onBackground: textColor,
          surface: backgroundColor,
          onSurface: textColor,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: textColor),
          bodyMedium: TextStyle(color: textColor),
          titleLarge: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
      ),
      home: HomePage(),
    );
  }
}

