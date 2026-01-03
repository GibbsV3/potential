import '../domain/routine.dart';
import '../domain/task.dart';
import 'dashboard_local_store.dart';
import 'dashboard_repository.dart';
import 'routine_model.dart';

class LocalDashboardRepository extends DashboardRepository {
  LocalDashboardRepository(this._store);

  final DashboardLocalStore _store;

  List<Routine>? _routines;
  Map<String, Map<String, double>>? _completions;

  @override
  Future<List<Routine>> loadRoutines() async {
    if (_routines != null) {
      return _routines!;
    }
    final stored = _store.readRoutines();
    if (stored != null && stored.isNotEmpty) {
      _routines = stored;
      return _routines!;
    }
    _routines = _seedRoutines();
    await _store.saveRoutines(
      _routines!
          .map((routine) => RoutineModel(
                id: routine.id,
                title: routine.title,
                weight: routine.weight,
                weekdays: routine.weekdays,
                tasks: routine.tasks,
              ))
          .toList(),
    );
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

  List<Routine> _seedRoutines() {
    return const [
      Routine(
        id: 'routine-work',
        title: 'Work',
        weight: 0.6,
        weekdays: [1, 2, 3, 4, 5],
        tasks: [
          Task(id: 'task-design', title: 'Design Presentation', weight: 0.55),
          Task(id: 'task-meeting', title: 'Team Meeting', weight: 0.45),
        ],
      ),
      Routine(
        id: 'routine-personal',
        title: 'Personal',
        weight: 0.4,
        weekdays: [1, 2, 3, 4, 5, 6, 7],
        tasks: [
          Task(id: 'task-grocery', title: 'Grocery Shopping', weight: 1.0),
        ],
      ),
    ];
  }
}
