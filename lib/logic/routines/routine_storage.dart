import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'routine_model.dart';

class RoutineStorage {
  RoutineStorage._();
  static final RoutineStorage instance = RoutineStorage._();

  static const String _key = "saved_routines";

  // ------------------------------------------------------------
  // LOAD ALL ROUTINES
  // ------------------------------------------------------------
  Future<List<Routine>> loadRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // ensure fresh data from disk

    final raw = prefs.getString(_key);
    if (raw == null) return [];

    final List decoded = jsonDecode(raw);
    return decoded.map((r) => Routine.fromJson(r)).toList();
  }

  // ------------------------------------------------------------
  // PRIVATE — SAVE FULL LIST (USED EVERYWHERE)
  // ------------------------------------------------------------
  Future<void> _saveAll(List<Routine> routines) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(routines.map((r) => r.toJson()).toList());
    await prefs.setString(_key, encoded);
    await prefs.reload(); // force sync flush
  }

  // ------------------------------------------------------------
  // SAVE LIST OF ROUTINES
  // (Direct overwrite)
  // ------------------------------------------------------------
  Future<void> saveRoutines(List<Routine> routines) async {
    await _saveAll(routines);
  }

  // ------------------------------------------------------------
  // ADD OR UPDATE ROUTINE
  // (If ID matches, replace; else append)
  // ------------------------------------------------------------
  Future<void> saveRoutine(Routine routine) async {
    final routines = await loadRoutines();
    final index = routines.indexWhere((r) => r.id == routine.id);

    if (index >= 0) {
      routines[index] = routine;
    } else {
      routines.add(routine);
    }

    await _saveAll(routines);
  }

  // ------------------------------------------------------------
  // DELETE ROUTINE BY ID
  // ------------------------------------------------------------
  Future<void> deleteRoutine(String id) async {
    final routines = await loadRoutines();
    routines.removeWhere((r) => r.id == id);
    await _saveAll(routines);
  }

  // ------------------------------------------------------------
  // UPDATE ROUTINE (rename, change intervals, etc.)
  // ------------------------------------------------------------
  Future<void> updateRoutine(Routine routine) async {
    final routines = await loadRoutines();
    final index = routines.indexWhere((r) => r.id == routine.id);

    if (index != -1) {
      routines[index] = routine;
      await _saveAll(routines);
    }
  }
}
