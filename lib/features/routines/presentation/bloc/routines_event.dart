part of 'routines_bloc.dart';

sealed class RoutinesEvent extends Equatable {
  const RoutinesEvent();

  @override
  List<Object?> get props => [];
}

final class RoutinesLoaded extends RoutinesEvent {
  const RoutinesLoaded();
}

final class RoutinesEditToggled extends RoutinesEvent {
  const RoutinesEditToggled();
}

final class RoutineActivationChanged extends RoutinesEvent {
  const RoutineActivationChanged({
    required this.routineId,
    required this.isActive,
  });

  final String routineId;
  final bool isActive;

  @override
  List<Object?> get props => [routineId, isActive];
}

final class RoutineDeleted extends RoutinesEvent {
  const RoutineDeleted(this.routineId);

  final String routineId;

  @override
  List<Object?> get props => [routineId];
}

final class _RoutinesSynced extends RoutinesEvent {
  const _RoutinesSynced(this.routines);

  final List<Routine> routines;

  @override
  List<Object?> get props => [routines];
}
