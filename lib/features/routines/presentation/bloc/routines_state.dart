part of 'routines_bloc.dart';

enum RoutinesStatus { initial, loading, ready, failure }

class RoutinesState extends Equatable {
  const RoutinesState({
    this.status = RoutinesStatus.initial,
    this.routines = const [],
    this.isEditing = false,
    this.errorMessage,
  });

  final RoutinesStatus status;
  final List<Routine> routines;
  final bool isEditing;
  final String? errorMessage;

  RoutinesState copyWith({
    RoutinesStatus? status,
    List<Routine>? routines,
    bool? isEditing,
    String? errorMessage,
  }) {
    return RoutinesState(
      status: status ?? this.status,
      routines: routines ?? this.routines,
      isEditing: isEditing ?? this.isEditing,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, routines, isEditing, errorMessage];
}
