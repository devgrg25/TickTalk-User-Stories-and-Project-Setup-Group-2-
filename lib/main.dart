import 'package:flutter/material.dart';
import 'homepage.dart';

// CHANGE: Moved color constants outside the class for better organization.
// These are static values and don't need to be in the build method.
const Color _backgroundColor = Color(0xFF2A2623); // Very Dark Sepia
const Color _textColor = Color(0xFFFFF3E9);       // Warm Cream
const Color _primaryColor = Color(0xFFF0B429);    // Warm Amber
const Color _successColor = Color(0xFF7FB58B);    // Sage Green
const Color _errorColor = Color(0xFFD96F4E);      // Terracotta

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // CHANGE: Using ThemeData.dark() with .copyWith() is the modern way to
    // create a theme. It ensures all properties have sensible defaults,
    // and you only override what you need.
    final baseTheme = ThemeData.dark(useMaterial3: true);

    return MaterialApp(
      title: 'Natural Timer App',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: _backgroundColor,
        colorScheme: baseTheme.colorScheme.copyWith(
          // Overriding specific colors in the scheme
          primary: _primaryColor,
          onPrimary: Colors.black,
          secondary: _successColor,
          onSecondary: Colors.black,
          error: _errorColor,
          onError: Colors.white,
          surface: _backgroundColor,
          onSurface: _textColor,
        ),
        textTheme: baseTheme.textTheme.copyWith(
          bodyLarge: const TextStyle(color: _textColor),
          bodyMedium: const TextStyle(color: _textColor),
          titleLarge: const TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
      ),
      // CHANGE: Added `const` for a performance optimization.
      home: const HomePage(),
    );
  }
}