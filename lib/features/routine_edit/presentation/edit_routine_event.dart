part of 'edit_routine_bloc.dart';

sealed class EditRoutineEvent extends Equatable {
  const EditRoutineEvent();

  @override
  List<Object?> get props => [];
}

final class EditRoutineStarted extends EditRoutineEvent {
  const EditRoutineStarted(this.routineId);

  final String? routineId;

  @override
  List<Object?> get props => [routineId];
}

final class EditRoutineTitleChanged extends EditRoutineEvent {
  const EditRoutineTitleChanged(this.title);

  final String title;

  @override
  List<Object?> get props => [title];
}

final class EditRoutineWeekdayToggled extends EditRoutineEvent {
  const EditRoutineWeekdayToggled(this.weekday);

  final Weekday weekday;

  @override
  List<Object?> get props => [weekday];
}

final class EditRoutineImportanceChanged extends EditRoutineEvent {
  const EditRoutineImportanceChanged(this.importance);

  final RoutineImportance importance;

  @override
  List<Object?> get props => [importance];
}

final class EditRoutineTaskAdded extends EditRoutineEvent {
  const EditRoutineTaskAdded();
}

final class EditRoutineTaskRemoved extends EditRoutineEvent {
  const EditRoutineTaskRemoved(this.taskId);

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

final class EditRoutineTaskTitleChanged extends EditRoutineEvent {
  const EditRoutineTaskTitleChanged({
    required this.taskId,
    required this.title,
  });

  final String taskId;
  final String title;

  @override
  List<Object?> get props => [taskId, title];
}

final class EditRoutineTaskSubmitted extends EditRoutineEvent {
  const EditRoutineTaskSubmitted({
    this.taskId,
    required this.title,
    required this.details,
    required this.importance,
  });

  final String? taskId;
  final String title;
  final String details;
  final RoutineImportance importance;

  @override
  List<Object?> get props => [taskId, title, details, importance];
}

final class EditRoutineSaved extends EditRoutineEvent {
  const EditRoutineSaved();
}
