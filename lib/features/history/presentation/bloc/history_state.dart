part of 'history_bloc.dart';

enum HistoryStatus { initial, loading, ready, failure }

enum HistoryRange { daily, weekly }

class HistoryPoint extends Equatable {
  const HistoryPoint({
    required this.date,
    required this.progress,
  });

  final DateTime date;
  final double progress;

  @override
  List<Object?> get props => [date, progress];
}

class HistoryState extends Equatable {
  const HistoryState({
    required this.status,
    required this.range,
    required this.anchorDate,
    required this.points,
    required this.routines,
    required this.completions,
    this.errorMessage,
  });

  factory HistoryState.initial() {
    final today = normalizeDate(DateTime.now());
    return HistoryState(
      status: HistoryStatus.initial,
      range: HistoryRange.daily,
      anchorDate: today,
      points: const [],
      routines: const [],
      completions: const {},
    );
  }

  final HistoryStatus status;
  final HistoryRange range;
  final DateTime anchorDate;
  final List<HistoryPoint> points;
  final List<Routine> routines;
  final Map<String, Map<String, double>> completions;
  final String? errorMessage;

  HistoryState copyWith({
    HistoryStatus? status,
    HistoryRange? range,
    DateTime? anchorDate,
    List<HistoryPoint>? points,
    List<Routine>? routines,
    Map<String, Map<String, double>>? completions,
    String? errorMessage,
  }) {
    return HistoryState(
      status: status ?? this.status,
      range: range ?? this.range,
      anchorDate: anchorDate ?? this.anchorDate,
      points: points ?? this.points,
      routines: routines ?? this.routines,
      completions: completions ?? this.completions,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        range,
        anchorDate,
        points,
        routines,
        completions,
        errorMessage,
      ];
}
