import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:potential/potential.dart';

/// Simple key-value SQLite store to keep the existing repository API.
class DashboardLocalStore {
  DashboardLocalStore(this._db);

  final Database _db;

  static const _table = 'kv_store';

  static const _routinesKey = 'dashboard_routines_v1';
  static const _completionsKey = 'dashboard_completions_v1';
  static const _routinesByDateKey = 'dashboard_routines_by_date_v1';

  static Future<DashboardLocalStore> open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'potential.db');
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (database, version) async {
        await database.execute(
          '''
          CREATE TABLE $_table (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
          ''',
        );
      },
    );
    return DashboardLocalStore(db);
  }

  Future<void> _setString(String key, String value) async {
    await _db.insert(
      _table,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> _getString(String key) async {
    final rows = await _db.query(
      _table,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['value'] as String?;
  }

  Future<List<RoutineModel>?> readRoutines() async {
    final raw = await _getString(_routinesKey);
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
    await _setString(_routinesKey, encoded);
  }

  Future<Map<String, Map<String, double>>?> readCompletions() async {
    final raw = await _getString(_completionsKey);
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
    await _setString(_completionsKey, encoded);
  }

  Future<Map<String, List<RoutineModel>>?> readRoutinesByDate() async {
    final raw = await _getString(_routinesByDateKey);
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
    await _setString(_routinesByDateKey, encoded);
  }
}
