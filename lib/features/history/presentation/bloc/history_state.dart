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
    this.errorMessage,
  });

  factory HistoryState.initial() {
    final today = normalizeDate(DateTime.now());
    return HistoryState(
      status: HistoryStatus.initial,
      range: HistoryRange.daily,
      anchorDate: today,
      points: const [],
    );
  }

  final HistoryStatus status;
  final HistoryRange range;
  final DateTime anchorDate;
  final List<HistoryPoint> points;
  final String? errorMessage;

  HistoryState copyWith({
    HistoryStatus? status,
    HistoryRange? range,
    DateTime? anchorDate,
    List<HistoryPoint>? points,
    String? errorMessage,
  }) {
    return HistoryState(
      status: status ?? this.status,
      range: range ?? this.range,
      anchorDate: anchorDate ?? this.anchorDate,
      points: points ?? this.points,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        range,
        anchorDate,
        points,
        errorMessage,
      ];
}
