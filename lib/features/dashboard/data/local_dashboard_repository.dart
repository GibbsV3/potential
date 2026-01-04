import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;

import 'package:potential/potential.dart';

const _cacheLimit = 90;
const _logName = 'LocalDashboardRepository';

class LocalDashboardRepository extends DashboardRepository {
  LocalDashboardRepository(this._store);

  final DashboardLocalStore _store;
  late final StreamController<List<Routine>> _routinesController =
      StreamController<List<Routine>>.broadcast(
    onListen: _emitRoutines,
  );

  List<Routine>? _routines;
  Map<String, Map<String, double>>? _completions;
  final _routinesByDateCache = _BoundedDateCache<List<Routine>>(
    maxEntries: _cacheLimit,
    onEvict: (key, _) => developer.log(
      'Evicting routines snapshot for $key',
      name: _logName,
    ),
  );

  @override
  Future<List<Routine>> loadRoutines() async {
    if (_routines != null) {
      _emitRoutines();
      return _routines!;
    }
    final stored = await _store.readRoutines();
    _routines = stored != null ? List<Routine>.from(stored) : <Routine>[];
    _emitRoutines();
    return _routines!;
  }

  @override
  Future<Map<String, Map<String, double>>> loadCompletions() async {
    if (_completions != null) {
      return _completions!;
    }
    _completions =
        await _store.readCompletions() ?? <String, Map<String, double>>{};
    await _ensureSnapshotsForDates(_completions!.keys);
    return _completions!;
  }

  @override
  Future<Map<String, List<Routine>>> loadRoutinesByDate({
    Iterable<String> dateKeys = const [],
  }) async {
    final requestedKeys = _normalizeKeys(dateKeys);
    if (requestedKeys.isEmpty) {
      return _routinesByDateCache.snapshot();
    }

    final results = <String, List<Routine>>{};
    final missing = <String>[];
    for (final key in requestedKeys) {
      final cached = _routinesByDateCache.get(key);
      if (cached != null) {
        results[key] = cached;
        continue;
      }
      missing.add(key);
    }

    if (missing.isEmpty) {
      return results;
    }

    final stored = await _store.readRoutinesByDateKeys(missing);
    List<Routine>? routines;
    for (final key in missing) {
      final storedSnapshot = stored[key];
      List<Routine>? snapshot;
      if (storedSnapshot != null) {
        snapshot = _materializeSnapshot(storedSnapshot);
      } else {
        final parsedDate = _parseDateKey(key);
        if (parsedDate != null) {
          routines ??= await loadRoutines();
          snapshot = _snapshotForDate(parsedDate, routines);
          await _persistRoutineSnapshots({key: snapshot});
        }
      }

      if (snapshot != null) {
        _routinesByDateCache.put(key, snapshot);
        results[key] = snapshot;
      }
    }

    return results;
  }

  @override
  Future<void> setTaskProgress(
    String dateKey,
    String taskId,
    double progress,
  ) async {
    await _ensureRoutineSnapshot(dateKey);
    final completions = await loadCompletions();
    final dayMap = completions[dateKey] ?? <String, double>{};
    dayMap[taskId] = progress.clamp(0, 1);
    completions[dateKey] = dayMap;
    _completions = completions;
    await _store.saveCompletions(completions);
  }

  @override
  Stream<List<Routine>> watchRoutines() {
    _emitRoutines();
    return _routinesController.stream;
  }

  @override
  Future<void> setRoutineActive(String routineId, bool isActive) async {
    final routines = await loadRoutines();
    _routines = routines
        .map(
          (routine) => routine.id == routineId
              ? Routine(
                  id: routine.id,
                  title: routine.title,
                  weight: routine.weight,
                  priority: routine.priority,
                  weekdays: routine.weekdays,
                  tasks: routine.tasks,
                  isActive: isActive,
                )
              : routine,
        )
        .toList();
    await _persistRoutines();
    _emitRoutines();
  }

  @override
  Future<void> deleteRoutine(String routineId) async {
    final routines = await loadRoutines();
    _routines = routines.where((routine) => routine.id != routineId).toList();
    await _persistRoutines();
    _emitRoutines();
  }

  @override
  Future<void> saveRoutine(Routine routine) async {
    final routines = await loadRoutines();
    final existingIndex =
        routines.indexWhere((candidate) => candidate.id == routine.id);
    _routines = List<Routine>.from(routines);
    if (existingIndex >= 0) {
      _routines![existingIndex] = routine;
    } else {
      _routines!.add(routine);
    }
    await _persistRoutines();
    _emitRoutines();
  }

  Future<void> _persistRoutines() async {
    if (_routines == null) {
      return;
    }
    await _store.saveRoutines(
      _routines!
          .map(
            (routine) => RoutineModel(
              id: routine.id,
              title: routine.title,
              weight: routine.weight,
              priority: routine.priority,
              weekdays: routine.weekdays,
              tasks: routine.tasks,
              isActive: routine.isActive,
            ),
          )
          .toList(),
    );
  }

  Future<void> _ensureRoutineSnapshot(String dateKey) async {
    final parsedDate = _parseDateKey(dateKey);
    if (parsedDate == null) {
      return;
    }
    if (_routinesByDateCache.containsKey(dateKey)) {
      return;
    }

    final stored = await _store.readRoutinesByDateKeys([dateKey]);
    final routines = await loadRoutines();
    final storedSnapshot = stored[dateKey];
    final snapshot = storedSnapshot != null
        ? _materializeSnapshot(storedSnapshot)
        : _snapshotForDate(parsedDate, routines);
    _routinesByDateCache.put(dateKey, snapshot);
    await _persistRoutineSnapshots({dateKey: snapshot});
  }

  Future<void> _ensureSnapshotsForDates(Iterable<String> dateKeys) async {
    final normalizedKeys = _normalizeKeys(dateKeys);
    if (normalizedKeys.isEmpty) {
      return;
    }
    final stored = await _store.readRoutinesByDateKeys(normalizedKeys);
    List<Routine>? routines;
    final pendingWrites = <String, List<Routine>>{};
    for (final key in normalizedKeys) {
      if (_routinesByDateCache.containsKey(key)) {
        continue;
      }
      final storedSnapshot = stored[key];
      List<Routine>? snapshot;
      if (storedSnapshot != null) {
        snapshot = _materializeSnapshot(storedSnapshot);
      } else {
        final parsedDate = _parseDateKey(key);
        if (parsedDate == null) {
          continue;
        }
        routines ??= await loadRoutines();
        snapshot = _snapshotForDate(parsedDate, routines);
        pendingWrites[key] = snapshot;
      }
      if (snapshot != null) {
        _routinesByDateCache.put(key, snapshot);
      }
    }

    if (pendingWrites.isNotEmpty) {
      await _persistRoutineSnapshots(pendingWrites);
    }
  }

  List<Routine> _snapshotForDate(DateTime date, List<Routine> routines) {
    final active = routinesForDate(routines, date);
    return active.map(_copyRoutine).toList();
  }

  List<Routine> _materializeSnapshot(List<RoutineModel> models) {
    return models.map(_copyRoutine).toList();
  }

  Future<void> _persistRoutineSnapshots(
    Map<String, List<Routine>> snapshots,
  ) async {
    if (snapshots.isEmpty) {
      return;
    }
    await _store.upsertRoutinesByDateEntries(
      snapshots.map(
        (dateKey, routines) => MapEntry(
          dateKey,
          routines
              .map(
                (routine) => RoutineModel(
                  id: routine.id,
                  title: routine.title,
                  weight: routine.weight,
                  priority: routine.priority,
                  weekdays: routine.weekdays,
                  tasks: routine.tasks,
                  isActive: routine.isActive,
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  List<String> _normalizeKeys(Iterable<String> keys) {
    final entries = <MapEntry<String, DateTime>>[];
    for (final key in keys) {
      final parsed = _parseDateKey(key);
      if (parsed != null) {
        entries.add(MapEntry(key, parsed));
      }
    }
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.map((entry) => entry.key).toList();
  }

  Routine _copyRoutine(Routine routine) {
    return Routine(
      id: routine.id,
      title: routine.title,
      weight: routine.weight,
      priority: routine.priority,
      weekdays: Set<Weekday>.from(routine.weekdays),
      tasks: routine.tasks
          .map(
            (task) => Task(
              id: task.id,
              title: task.title,
              weight: task.weight,
              details: task.details,
              priority: task.priority,
            ),
          )
          .toList(),
      isActive: routine.isActive,
    );
  }

  DateTime? _parseDateKey(String dateKey) {
    final parts = dateKey.split('-');
    if (parts.length != 3) {
      return null;
    }
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }
    return DateTime(year, month, day);
  }

  void _emitRoutines() {
    if (_routines == null || _routinesController.isClosed) {
      return;
    }
    _routinesController.add(List<Routine>.unmodifiable(_routines!));
  }
}

class _BoundedDateCache<T> {
  _BoundedDateCache({
    required this.maxEntries,
    this.onEvict,
  });

  final int maxEntries;
  final void Function(String key, T value)? onEvict;
  final _store = LinkedHashMap<String, T>();

  bool containsKey(String key) {
    return _store.containsKey(key);
  }

  T? get(String key) {
    final value = _store.remove(key);
    if (value != null) {
      _store[key] = value;
    }
    return value;
  }

  void put(String key, T value) {
    if (_store.containsKey(key)) {
      _store.remove(key);
    }
    _store[key] = value;
    if (_store.length > maxEntries) {
      final oldestKey = _store.keys.first;
      final evicted = _store.remove(oldestKey);
      if (evicted != null) {
        onEvict?.call(oldestKey, evicted);
      }
    }
  }

  Map<String, T> snapshot() {
    return Map<String, T>.unmodifiable(_store);
  }

  Iterable<String> get keys => _store.keys;
}
