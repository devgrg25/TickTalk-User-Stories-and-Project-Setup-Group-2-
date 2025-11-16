import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../timer/timer_controller.dart';
import 'routine_model.dart';

class RoutineStorage {
  RoutineStorage._();
  static final RoutineStorage instance = RoutineStorage._();

  static const String _key = "saved_routines";

  /// Load all saved routines
  Future<List<Routine>> loadRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // ensure latest data in memory
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final List decoded = jsonDecode(raw);
    return decoded.map((r) => Routine.fromJson(r)).toList();
  }

  /// Save full list of routines
  Future<void> saveRoutines(List<Routine> routines) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
    jsonEncode(routines.map((r) => r.toJson()).toList());
    await prefs.setString(_key, encoded);
    await prefs.reload(); // 🔥 force commit to disk
  }

  /// Add or update a routine (if ID exists, update, else insert)
  Future<void> saveRoutine(Routine routine) async {
    final prefs = await SharedPreferences.getInstance();
    final routines = await loadRoutines();
    final index = routines.indexWhere((r) => r.id == routine.id);

    if (index >= 0) {
      routines[index] = routine;
    } else {
      routines.add(routine);
    }

    final encoded =
    jsonEncode(routines.map((r) => r.toJson()).toList());
    await prefs.setString(_key, encoded);
    await prefs.reload(); // 🔥 IMPORTANT: force write sync
  }

  /// Delete routine by ID
  Future<void> deleteRoutine(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final routines = await loadRoutines();
    routines.removeWhere((r) => r.id == id);
    final encoded =
    jsonEncode(routines.map((r) => r.toJson()).toList());
    await prefs.setString(_key, encoded);
    await prefs.reload();
  }
}
