part of 'dashboard_bloc.dart';

enum DashboardStatus { initial, loading, ready, failure }

class DashboardState extends Equatable {
  const DashboardState({
    required this.status,
    required this.selectedDate,
    required this.routines,
    required this.completions,
    required this.routineProgress,
    required this.dailyProgress,
    required this.selectedDayCompletions,
    this.errorMessage,
  });

  factory DashboardState.initial(DateTime date) {
    return DashboardState(
      status: DashboardStatus.initial,
      selectedDate: DateTime(date.year, date.month, date.day),
      routines: const [],
      completions: const {},
      routineProgress: const [],
      dailyProgress: 0,
      selectedDayCompletions: const {},
    );
  }

  final DashboardStatus status;
  final DateTime selectedDate;
  final List<Routine> routines;
  final Map<String, Map<String, double>> completions;
  final List<RoutineProgress> routineProgress;
  final double dailyProgress;
  final Map<String, double> selectedDayCompletions;
  final String? errorMessage;

  DashboardState copyWith({
    DashboardStatus? status,
    DateTime? selectedDate,
    List<Routine>? routines,
    Map<String, Map<String, double>>? completions,
    List<RoutineProgress>? routineProgress,
    double? dailyProgress,
    Map<String, double>? selectedDayCompletions,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      selectedDate: selectedDate ?? this.selectedDate,
      routines: routines ?? this.routines,
      completions: completions ?? this.completions,
      routineProgress: routineProgress ?? this.routineProgress,
      dailyProgress: dailyProgress ?? this.dailyProgress,
      selectedDayCompletions:
          selectedDayCompletions ?? this.selectedDayCompletions,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  DashboardState buildWith({
    DashboardStatus? status,
    DateTime? selectedDate,
    List<Routine>? routines,
    Map<String, Map<String, double>>? completions,
    String? errorMessage,
  }) {
    final resolvedDate = _normalizeDate(selectedDate ?? this.selectedDate);
    final resolvedRoutines = routines ?? this.routines;
    final resolvedCompletions = completions ?? this.completions;
    final filteredRoutines = resolvedRoutines
        .where((routine) =>
            routine.isActive &&
            routine.weekdays.contains(resolvedDate.weekday))
        .toList();
    final dayCompletions =
        _completionsForDate(resolvedDate, resolvedCompletions);
    final routineProgress =
        _routineProgressForDate(filteredRoutines, dayCompletions);
    final double dailyProgress =
        _dailyProgressForDate(filteredRoutines, routineProgress);

    return DashboardState(
      status: status ?? this.status,
      selectedDate: resolvedDate,
      routines: resolvedRoutines,
      completions: resolvedCompletions,
      routineProgress: routineProgress,
      dailyProgress: dailyProgress,
      selectedDayCompletions: dayCompletions,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  double progressForDate(DateTime date) {
    final normalizedDate = _normalizeDate(date);
    final routinesForDate = routines
        .where((routine) =>
            routine.isActive &&
            routine.weekdays.contains(normalizedDate.weekday))
        .toList();
    if (routinesForDate.isEmpty) {
      return 0;
    }
    final dayCompletions = _completionsForDate(normalizedDate, completions);
    final dayRoutineProgress =
        _routineProgressForDate(routinesForDate, dayCompletions);
    return _dailyProgressForDate(routinesForDate, dayRoutineProgress);
  }

  @override
  List<Object?> get props => [
        status,
        selectedDate,
        routines,
        completions,
        routineProgress,
        dailyProgress,
        selectedDayCompletions,
        errorMessage,
      ];
}

DateTime _normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

Map<String, double> _completionsForDate(
  DateTime date,
  Map<String, Map<String, double>> completions,
) {
  return Map<String, double>.from(completions[dateKey(date)] ?? {});
}

List<RoutineProgress> _routineProgressForDate(
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
      (sum, task) =>
          sum + (task.weight * (dayCompletions[task.id] ?? 0)),
    );
    final double completion =
        totalWeight == 0 ? 0 : completedWeight / totalWeight;
    return RoutineProgress(routine: routine, completion: completion);
  }).toList();
}

double _dailyProgressForDate(
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
