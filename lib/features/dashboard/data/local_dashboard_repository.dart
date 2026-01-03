import 'dart:async';

import '../domain/routine.dart';
import '../domain/task.dart';
import '../domain/weekday.dart';
import 'dashboard_local_store.dart';
import 'dashboard_repository.dart';
import 'routine_model.dart';

class LocalDashboardRepository extends DashboardRepository {
  LocalDashboardRepository(this._store);

  final DashboardLocalStore _store;
  late final StreamController<List<Routine>> _routinesController =
      StreamController<List<Routine>>.broadcast(
    onListen: _emitRoutines,
  );

  List<Routine>? _routines;
  Map<String, Map<String, double>>? _completions;

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
    return _completions!;
  }

  @override
  Future<void> setTaskProgress(
    String dateKey,
    String taskId,
    double progress,
  ) async {
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
    final routineToDelete =
        routines.firstWhere((routine) => routine.id == routineId);
    final taskIds = routineToDelete.tasks.map((task) => task.id).toSet();
    _routines = routines.where((routine) => routine.id != routineId).toList();
    await _persistRoutines();

    final completions = await loadCompletions();
    bool completionsChanged = false;
    final cleaned = <String, Map<String, double>>{};
    for (final entry in completions.entries) {
      final filteredTasks = Map<String, double>.from(entry.value)
        ..removeWhere((taskId, _) => taskIds.contains(taskId));
      if (filteredTasks.isNotEmpty) {
        cleaned[entry.key] = filteredTasks;
      }
      completionsChanged =
          completionsChanged || filteredTasks.length != entry.value.length;
    }
    if (completionsChanged) {
      _completions = cleaned;
      await _store.saveCompletions(cleaned);
    }
    _emitRoutines();
  }

  List<Routine> _seedRoutines() {
    return const [
      Routine(
        id: 'routine-work',
        title: 'Work',
        weight: 0.6,
        weekdays: {
          Weekday.monday,
          Weekday.tuesday,
          Weekday.wednesday,
          Weekday.thursday,
          Weekday.friday,
        },
        tasks: [
          Task(id: 'task-design', title: 'Design Presentation', weight: 0.55),
          Task(id: 'task-meeting', title: 'Team Meeting', weight: 0.45),
        ],
        isActive: true,
      ),
      Routine(
        id: 'routine-personal',
        title: 'Personal',
        weight: 0.4,
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
          Task(id: 'task-grocery', title: 'Grocery Shopping', weight: 1.0),
        ],
        isActive: true,
      ),
    ];
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
              weekdays: routine.weekdays,
              tasks: routine.tasks,
              isActive: routine.isActive,
            ),
          )
          .toList(),
    );
  }

  void _emitRoutines() {
    if (_routines == null || _routinesController.isClosed) {
      return;
    }
    _routinesController.add(List<Routine>.unmodifiable(_routines!));
  }
}
