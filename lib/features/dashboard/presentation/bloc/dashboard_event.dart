part of 'dashboard_bloc.dart';

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

final class DashboardLoaded extends DashboardEvent {
  const DashboardLoaded();
}

final class DashboardDateSelected extends DashboardEvent {
  const DashboardDateSelected(this.date);

  final DateTime date;

  @override
  List<Object?> get props => [date];
}

final class DashboardTaskToggled extends DashboardEvent {
  const DashboardTaskToggled({
    required this.date,
    required this.taskId,
  });

  final DateTime date;
  final String taskId;

  @override
  List<Object?> get props => [date, taskId];
}

final class DashboardTaskProgressChanged extends DashboardEvent {
  const DashboardTaskProgressChanged({
    required this.date,
    required this.taskId,
    required this.progress,
  });

  final DateTime date;
  final String taskId;
  final double progress;

  @override
  List<Object?> get props => [date, taskId, progress];
}
