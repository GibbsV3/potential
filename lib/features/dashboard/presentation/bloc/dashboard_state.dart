part of 'dashboard_bloc.dart';

enum DashboardStatus { initial, loading, ready, failure }

class DashboardState extends Equatable {
  const DashboardState({
    required this.status,
    required this.selectedDate,
    required this.routines,
    required this.routinesByDate,
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
      routinesByDate: const {},
      completions: const {},
      routineProgress: const [],
      dailyProgress: 0,
      selectedDayCompletions: const {},
    );
  }

  final DashboardStatus status;
  final DateTime selectedDate;
  final List<Routine> routines;
  final Map<String, List<Routine>> routinesByDate;
  final Map<String, Map<String, double>> completions;
  final List<RoutineProgress> routineProgress;
  final double dailyProgress;
  final Map<String, double> selectedDayCompletions;
  final String? errorMessage;

  DashboardState copyWith({
    DashboardStatus? status,
    DateTime? selectedDate,
    List<Routine>? routines,
    Map<String, List<Routine>>? routinesByDate,
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
      routinesByDate: routinesByDate ?? this.routinesByDate,
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
    Map<String, List<Routine>>? routinesByDate,
    Map<String, Map<String, double>>? completions,
    String? errorMessage,
  }) {
    final resolvedDate = normalizeDate(selectedDate ?? this.selectedDate);
    final resolvedRoutines = routines ?? this.routines;
    final resolvedRoutinesByDate = routinesByDate ?? this.routinesByDate;
    final resolvedCompletions = completions ?? this.completions;
    final filteredRoutines = routinesForDateWithHistory(
      resolvedRoutines,
      resolvedDate,
      routinesByDate: resolvedRoutinesByDate,
    );
    final dayCompletions =
        completionsForDate(resolvedDate, resolvedCompletions);
    final routineProgress =
        routineProgressForDate(filteredRoutines, dayCompletions);
    final double dailyProgress =
        dailyProgressForDate(filteredRoutines, routineProgress);

    return DashboardState(
      status: status ?? this.status,
      selectedDate: resolvedDate,
      routines: resolvedRoutines,
      routinesByDate: resolvedRoutinesByDate,
      completions: resolvedCompletions,
      routineProgress: routineProgress,
      dailyProgress: dailyProgress,
      selectedDayCompletions: dayCompletions,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  double progressForDate(DateTime date) {
    return weightedProgressForDate(
      date: date,
      routines: routines,
      completions: completions,
      routinesByDate: routinesByDate,
    );
  }

  @override
  List<Object?> get props => [
        status,
        selectedDate,
        routines,
        routinesByDate,
        completions,
        routineProgress,
        dailyProgress,
        selectedDayCompletions,
        errorMessage,
      ];
}
