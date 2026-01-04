import '../domain/routine.dart';

abstract class DashboardRepository {
  const DashboardRepository();

  Future<List<Routine>> loadRoutines();
  Future<Map<String, Map<String, double>>> loadCompletions();
  Future<void> setTaskProgress(
    String dateKey,
    String taskId,
    double progress,
  );
  Stream<List<Routine>> watchRoutines();
  Future<void> setRoutineActive(String routineId, bool isActive);
  Future<void> deleteRoutine(String routineId);
  Future<void> saveRoutine(Routine routine);
}
