part of 'history_bloc.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class HistoryLoaded extends HistoryEvent {
  const HistoryLoaded();
}

class HistoryRangeChanged extends HistoryEvent {
  const HistoryRangeChanged(this.range);

  final HistoryRange range;

  @override
  List<Object?> get props => [range];
}

class HistoryAnchorChanged extends HistoryEvent {
  const HistoryAnchorChanged(this.anchorDate);

  final DateTime anchorDate;

  @override
  List<Object?> get props => [anchorDate];
}

class HistoryRoutinesUpdated extends HistoryEvent {
  const HistoryRoutinesUpdated(this.routines);

  final List<Routine> routines;

  @override
  List<Object?> get props => [routines];
}

class HistoryCompletionsUpdated extends HistoryEvent {
  const HistoryCompletionsUpdated(this.completions);

  final Map<String, Map<String, double>> completions;

  @override
  List<Object?> get props => [completions];
}
