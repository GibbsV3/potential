import 'routine.dart';
import 'routine_progress.dart';
import 'weekday.dart';

DateTime normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

Map<String, double> completionsForDate(
  DateTime date,
  Map<String, Map<String, double>> completions,
) {
  return Map<String, double>.from(
    completions[_dateKey(date)] ?? <String, double>{},
  );
}

List<Routine> routinesForDate(List<Routine> routines, DateTime date) {
  final resolvedDate = normalizeDate(date);
  final resolvedWeekday = Weekday.fromDate(resolvedDate);
  return routines
      .where(
        (routine) =>
            routine.isActive && routine.weekdays.contains(resolvedWeekday),
      )
      .toList();
}

List<RoutineProgress> routineProgressForDate(
  List<Routine> routines,
  Map<String, double> dayCompletions,
) {
  return routines.map((routine) {
    final totalWeight = routine.tasks.fold<double>(
      0,
      (sum, task) => sum + task.weight,
    );
    final completedWeight = routine.tasks.fold<double>(
      0,
      (sum, task) => sum + (task.weight * (dayCompletions[task.id] ?? 0)),
    );
    final double completion =
        totalWeight == 0 ? 0 : completedWeight / totalWeight;
    return RoutineProgress(routine: routine, completion: completion);
  }).toList();
}

double dailyProgressForDate(
  List<Routine> routines,
  List<RoutineProgress> routineProgress,
) {
  final routineWeightTotal = routines.fold<double>(
    0,
    (sum, routine) => sum + routine.weight,
  );
  final weightedCompletion = routineProgress.fold<double>(
    0,
    (sum, progress) =>
        sum + (progress.routine.weight * progress.completion),
  );
  return routineWeightTotal == 0 ? 0 : weightedCompletion / routineWeightTotal;
}

double weightedProgressForDate({
  required DateTime date,
  required List<Routine> routines,
  required Map<String, Map<String, double>> completions,
}) {
  final normalizedDate = normalizeDate(date);
  final routinesForDay = routinesForDate(routines, normalizedDate);
  if (routinesForDay.isEmpty) {
    return 0;
  }
  final dayCompletions = completionsForDate(normalizedDate, completions);
  final routineProgress =
      routineProgressForDate(routinesForDay, dayCompletions);
  return dailyProgressForDate(routinesForDay, routineProgress);
}

String _dateKey(DateTime date) {
  final normalized = normalizeDate(date);
  final year = normalized.year.toString().padLeft(4, '0');
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
