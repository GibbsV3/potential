import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:potential/potential.dart';

class DashboardLocalStore {
  DashboardLocalStore(this._prefs);

  final SharedPreferences _prefs;

  static const _routinesKey = 'dashboard_routines_v1';
  static const _completionsKey = 'dashboard_completions_v1';
  static const _routinesByDateKey = 'dashboard_routines_by_date_v1';

  List<RoutineModel>? readRoutines() {
    final raw = _prefs.getString(_routinesKey);
    if (raw == null) {
      return null;
    }
    final data = jsonDecode(raw) as List<dynamic>;
    return data
        .map((item) => RoutineModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveRoutines(List<RoutineModel> routines) async {
    final encoded = jsonEncode(routines.map((item) => item.toJson()).toList());
    await _prefs.setString(_routinesKey, encoded);
  }

  Map<String, Map<String, double>>? readCompletions() {
    final raw = _prefs.getString(_completionsKey);
    if (raw == null) {
      return null;
    }
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return data.map((dateKey, value) {
      final taskMap = (value as Map<String, dynamic>).map((taskId, done) {
        if (done is num) {
          return MapEntry(taskId, done.toDouble());
        }
        if (done is bool) {
          return MapEntry(taskId, done ? 1.0 : 0.0);
        }
        return MapEntry(taskId, 0.0);
      });
      return MapEntry(dateKey, taskMap);
    });
  }

  Future<void> saveCompletions(
    Map<String, Map<String, double>> completions,
  ) async {
    final encoded = jsonEncode(completions);
    await _prefs.setString(_completionsKey, encoded);
  }

  Map<String, List<RoutineModel>>? readRoutinesByDate() {
    final raw = _prefs.getString(_routinesByDateKey);
    if (raw == null) {
      return null;
    }
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return data.map((dateKey, routines) {
      final parsed = (routines as List<dynamic>)
          .map((item) => RoutineModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return MapEntry(dateKey, parsed);
    });
  }

  Future<void> saveRoutinesByDate(
    Map<String, List<RoutineModel>> routinesByDate,
  ) async {
    final encoded = jsonEncode(
      routinesByDate.map(
        (dateKey, routines) => MapEntry(
          dateKey,
          routines.map((routine) => routine.toJson()).toList(),
        ),
      ),
    );
    await _prefs.setString(_routinesByDateKey, encoded);
  }
}
