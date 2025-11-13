import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontScale extends ChangeNotifier {
  static final FontScale instance = FontScale._();
  FontScale._();

  static const _kPrefKey = 'global_text_scale';
  static const double _min = 0.8;
  static const double _max = 1.8;

  double _scale = 1.0;
  double get scale => _scale;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _scale = prefs.getDouble(_kPrefKey) ?? 1.0;
    _scale = _clamp(_scale);
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kPrefKey, _scale);
  }

  static double _clamp(double v) => v.clamp(_min, _max);

  Future<void> setScale(double value) async {
    _scale = _clamp(value);
    await _persist();
    notifyListeners();
  }

  /// +10%
  Future<void> increase10() => setScale(_scale * 1.10);

  /// −10%
  Future<void> decrease10() => setScale(_scale * 0.90);
}
