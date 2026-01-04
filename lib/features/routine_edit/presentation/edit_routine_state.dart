part of 'edit_routine_bloc.dart';

enum EditRoutineStatus { initial, loading, ready, saving, success, failure }

class EditRoutineState extends Equatable {
  const EditRoutineState({
    required this.status,
    required this.routineId,
    required this.title,
    required this.weekdays,
    required this.tasks,
    required this.priority,
    required this.weight,
    required this.isActive,
    this.errorMessage,
  });

  const EditRoutineState.initial()
      : status = EditRoutineStatus.initial,
        routineId = '',
        title = '',
        weekdays = const {},
        tasks = const [],
        priority = Priority.medium,
        weight = 1.0,
        isActive = true,
        errorMessage = null;

  final EditRoutineStatus status;
  final String routineId;
  final String title;
  final Set<Weekday> weekdays;
  final List<Task> tasks;
  final Priority priority;
  final double weight;
  final bool isActive;
  final String? errorMessage;

  bool get canSave {
    final hasName = title.trim().isNotEmpty;
    final hasWeekdays = weekdays.isNotEmpty;
    final hasTasks = tasks.isNotEmpty &&
        tasks.every((task) => task.title.trim().isNotEmpty);
    return hasName && hasWeekdays && hasTasks;
  }

  EditRoutineState copyWith({
    EditRoutineStatus? status,
    String? routineId,
    String? title,
    Set<Weekday>? weekdays,
    List<Task>? tasks,
    Priority? priority,
    double? weight,
    bool? isActive,
    String? errorMessage,
  }) {
    return EditRoutineState(
      status: status ?? this.status,
      routineId: routineId ?? this.routineId,
      title: title ?? this.title,
      weekdays: weekdays ?? this.weekdays,
      tasks: tasks ?? this.tasks,
      priority: priority ?? this.priority,
      weight: weight ?? this.weight,
      isActive: isActive ?? this.isActive,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        routineId,
        title,
        weekdays,
        tasks,
        priority,
        weight,
        isActive,
        errorMessage,
      ];
}
