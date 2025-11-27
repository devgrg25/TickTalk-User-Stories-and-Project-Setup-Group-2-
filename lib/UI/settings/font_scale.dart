import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontScale extends ChangeNotifier {
  FontScale._();
  static final FontScale instance = FontScale._();

  static const String _prefsKey = 'font_scale';

  double _scale = 1.0;
  double get scale => _scale;

  /// Load saved scale from SharedPreferences
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _scale = prefs.getDouble(_prefsKey) ?? 1.0;
    notifyListeners();
  }

  /// Set and persist scale (clamped between 70% and 160%)
  Future<void> setScale(double value) async {
    final clamped = value.clamp(0.7, 1.6);
    _scale = clamped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefsKey, _scale);
    notifyListeners();
  }

  Future<void> increaseBy10() => setScale(_scale + 0.10);
  Future<void> decreaseBy10() => setScale(_scale - 0.10);
}