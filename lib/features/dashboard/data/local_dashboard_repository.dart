import 'dart:async';

import 'package:potential/potential.dart';

class LocalDashboardRepository extends DashboardRepository {
  LocalDashboardRepository(this._store);

  final DashboardLocalStore _store;
  late final StreamController<List<Routine>> _routinesController =
      StreamController<List<Routine>>.broadcast(
    onListen: _emitRoutines,
  );

  List<Routine>? _routines;
  Map<String, Map<String, double>>? _completions;
  Map<String, List<Routine>>? _routinesByDate;

  @override
  Future<List<Routine>> loadRoutines() async {
    if (_routines != null) {
      _emitRoutines();
      return _routines!;
    }
    final stored = _store.readRoutines();
    if (stored != null && stored.isNotEmpty) {
      _routines = stored;
    } else {
      _routines = _seedRoutines();
      await _persistRoutines();
    }
    _emitRoutines();
    return _routines!;
  }

  @override
  Future<Map<String, Map<String, double>>> loadCompletions() async {
    if (_completions != null) {
      return _completions!;
    }
    _completions = _store.readCompletions() ?? <String, Map<String, double>>{};
    await _ensureSnapshotsForDates(_completions!.keys);
    return _completions!;
  }

  @override
  Future<Map<String, List<Routine>>> loadRoutinesByDate() async {
    if (_routinesByDate != null) {
      return _routinesByDate!;
    }
    final stored = _store.readRoutinesByDate();
    _routinesByDate = stored?.map(
          (date, routines) => MapEntry(
            date,
            List<Routine>.from(routines),
          ),
        ) ??
        <String, List<Routine>>{};
    return _routinesByDate!;
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

  Future<void> _persistRoutinesByDate() async {
    if (_routinesByDate == null) {
      return;
    }
    await _store.saveRoutinesByDate(
      _routinesByDate!.map(
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

  Future<void> _ensureRoutineSnapshot(String dateKey) async {
    final parsedDate = _parseDateKey(dateKey);
    if (parsedDate == null) {
      return;
    }
    final routinesByDate = await loadRoutinesByDate();
    if (routinesByDate.containsKey(dateKey)) {
      return;
    }
    final routines = await loadRoutines();
    final snapshot = _snapshotForDate(parsedDate, routines);
    _routinesByDate = Map<String, List<Routine>>.from(routinesByDate)
      ..[dateKey] = snapshot;
    await _persistRoutinesByDate();
  }

  Future<void> _ensureSnapshotsForDates(Iterable<String> dateKeys) async {
    final routinesByDate = await loadRoutinesByDate();
    final missing = dateKeys.where((key) => !routinesByDate.containsKey(key));
    if (missing.isEmpty) {
      return;
    }
    final routines = await loadRoutines();
    final updated = Map<String, List<Routine>>.from(routinesByDate);
    for (final key in missing) {
      final date = _parseDateKey(key);
      if (date == null) {
        continue;
      }
      updated[key] = _snapshotForDate(date, routines);
    }
    _routinesByDate = updated;
    await _persistRoutinesByDate();
  }

  List<Routine> _snapshotForDate(DateTime date, List<Routine> routines) {
    final active = routinesForDate(routines, date);
    return active
        .map(
          (routine) => Routine(
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
          ),
        )
        .toList();
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

  List<Routine> _seedRoutines() {
    return  [
      Routine(
        id: 'routine-work',
        title: 'Work',
        weight: 0.6,
        priority: Priority.high,
        weekdays: {
          Weekday.monday,
          Weekday.tuesday,
          Weekday.wednesday,
          Weekday.thursday,
          Weekday.friday,
        },
        tasks: [
          Task(
            id: 'task-design',
            title: 'Design Presentation',
            weight: 0.55,
            details: '',
            priority: priorityForWeight(0.55),
          ),
          Task(
            id: 'task-meeting',
            title: 'Team Meeting',
            weight: 0.45,
            details: '',
            priority: priorityForWeight(0.45),
          ),
        ],
        isActive: true,
      ),
      Routine(
        id: 'routine-personal',
        title: 'Personal',
        weight: 0.4,
        priority: Priority.medium,
        weekdays: {
          Weekday.monday,
          Weekday.tuesday,
          Weekday.wednesday,
          Weekday.thursday,
          Weekday.friday,
          Weekday.saturday,
          Weekday.sunday,
        },
        tasks: [
          Task(
            id: 'task-grocery',
            title: 'Grocery Shopping',
            weight: 1.0,
            details: '',
            priority: priorityForWeight(1.0),
          ),
        ],
        isActive: true,
      ),
    ];
  }

  void _emitRoutines() {
    if (_routines == null || _routinesController.isClosed) {
      return;
    }
    _routinesController.add(List<Routine>.unmodifiable(_routines!));
  }
}
