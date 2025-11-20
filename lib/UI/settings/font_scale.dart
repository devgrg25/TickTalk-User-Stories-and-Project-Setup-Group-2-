import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontScale extends ChangeNotifier {
  FontScale._internal();
  static final FontScale instance = FontScale._internal();

  static const _prefsKey = 'globalFontScale';

  double _scale = 1.0; // 100%
  double get scale => _scale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _scale = prefs.getDouble(_prefsKey) ?? 1.0;
    notifyListeners();
  }

  Future<void> setScale(double value) async {
    // keep between 80% and 160% so it doesn’t get crazy
    _scale = value.clamp(0.8, 1.6);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefsKey, _scale);
  }
}
