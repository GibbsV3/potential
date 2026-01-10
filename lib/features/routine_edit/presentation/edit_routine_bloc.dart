import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:potential/potential.dart';

part 'edit_routine_event.dart';
part 'edit_routine_state.dart';

class EditRoutineBloc extends Bloc<EditRoutineEvent, EditRoutineState> {
  EditRoutineBloc(this._repository) : super(const EditRoutineState.initial()) {
    on<EditRoutineStarted>(_onStarted);
    on<EditRoutineTitleChanged>(_onTitleChanged);
    on<EditRoutineWeekdayToggled>(_onWeekdayToggled);
    on<EditRoutinePriorityChanged>(_onPriorityChanged);
    on<EditRoutineTaskAdded>(_onTaskAdded);
    on<EditRoutineTaskRemoved>(_onTaskRemoved);
    on<EditRoutineTaskTitleChanged>(_onTaskTitleChanged);
    on<EditRoutineTaskSubmitted>(_onTaskSubmitted);
    on<EditRoutineSaved>(_onSaved);
  }

  final DashboardRepository _repository;

  Future<void> _onStarted(
    EditRoutineStarted event,
    Emitter<EditRoutineState> emit,
  ) async {
    final routineId = event.routineId;
    if (routineId == null || routineId.isEmpty) {
      emit(_freshState());
      return;
    }

    emit(state.copyWith(status: EditRoutineStatus.loading));
    try {
      final routines = await _repository.loadRoutines();
      final routine = routines.firstWhere((item) => item.id == routineId);
      emit(
        state.copyWith(
          status: EditRoutineStatus.ready,
          routineId: routine.id,
          title: routine.title,
          weekdays: Set<Weekday>.from(routine.weekdays),
          tasks: List<Task>.from(routine.tasks),
          priority: routine.priority,
          weight: routine.weight,
          isActive: routine.isActive,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: EditRoutineStatus.failure,
          errorMessage: 'Unable to load routine.',
        ),
      );
    }
  }

  void _onTitleChanged(
    EditRoutineTitleChanged event,
    Emitter<EditRoutineState> emit,
  ) {
    emit(
      state.copyWith(
        title: event.title,
      ),
    );
  }

  void _onWeekdayToggled(
    EditRoutineWeekdayToggled event,
    Emitter<EditRoutineState> emit,
  ) {
    final updated = Set<Weekday>.from(state.weekdays);
    if (updated.contains(event.weekday)) {
      updated.remove(event.weekday);
    } else {
      updated.add(event.weekday);
    }
    emit(
      state.copyWith(
        weekdays: updated,
      ),
    );
  }

  void _onPriorityChanged(
    EditRoutinePriorityChanged event,
    Emitter<EditRoutineState> emit,
  ) {
    emit(
      state.copyWith(
        priority: event.priority,
      ),
    );
  }

  void _onTaskAdded(
    EditRoutineTaskAdded event,
    Emitter<EditRoutineState> emit,
  ) {
    final tasks = List<Task>.from(state.tasks)
      ..add(
        Task(
          id: _newTaskId(),
          title: _defaultTaskTitle(state.tasks.length + 1),
          details: '',
          priority: Priority.medium,
          weight: weightForPriority(Priority.medium),
        ),
      );
    emit(
      state.copyWith(
        tasks: tasks,
      ),
    );
  }

  void _onTaskRemoved(
    EditRoutineTaskRemoved event,
    Emitter<EditRoutineState> emit,
  ) {
    final tasks = state.tasks.where((task) => task.id != event.taskId).toList();
    emit(
      state.copyWith(
        tasks: tasks,
      ),
    );
  }

  void _onTaskTitleChanged(
    EditRoutineTaskTitleChanged event,
    Emitter<EditRoutineState> emit,
  ) {
    final tasks = state.tasks.map((task) {
      if (task.id == event.taskId) {
        return Task(
          id: task.id,
          title: event.title,
          weight: task.weight,
          details: task.details,
          priority: task.priority,
        );
      }
      return task;
    }).toList();
    emit(
      state.copyWith(
        tasks: tasks,
      ),
    );
  }

  Future<void> _onSaved(
    EditRoutineSaved event,
    Emitter<EditRoutineState> emit,
  ) async {
    if (!state.canSave || state.routineId.isEmpty) {
      return;
    }
    emit(state.copyWith(status: EditRoutineStatus.saving));
    try {
      final updatedRoutine = Routine(
        id: state.routineId,
        title: state.title.trim(),
        weight: state.weight,
        priority: state.priority,
        weekdays: Set<Weekday>.from(state.weekdays),
        tasks: state.tasks
            .map(
              (task) => Task(
                id: task.id,
                title: task.title.trim(),
                weight: task.weight,
                details: task.details,
                priority: task.priority,
              ),
            )
            .toList(),
        isActive: state.isActive,
      );
      await _repository.saveRoutine(updatedRoutine);
      emit(
        state.copyWith(
          status: EditRoutineStatus.success,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: EditRoutineStatus.failure,
          errorMessage: 'Unable to save routine. Try again.',
        ),
      );
    }
  }

  void _onTaskSubmitted(
    EditRoutineTaskSubmitted event,
    Emitter<EditRoutineState> emit,
  ) {
    final title = event.title.trim();
    if (title.isEmpty) {
      return;
    }
    final updated = List<Task>.from(state.tasks);
    final weight = weightForPriority(event.priority);

    if (event.taskId == null) {
      updated.add(
        Task(
          id: _newTaskId(),
          title: title,
          weight: weight,
          details: event.details.trim(),
          priority: event.priority,
        ),
      );
    } else {
      final index = updated.indexWhere((task) => task.id == event.taskId);
      if (index >= 0) {
        updated[index] = Task(
          id: updated[index].id,
          title: title,
          weight: weight,
          details: event.details.trim(),
          priority: event.priority,
        );
      } else {
        updated.add(
          Task(
            id: event.taskId!,
            title: title,
            weight: weight,
            details: event.details.trim(),
            priority: event.priority,
          ),
        );
      }
    }
    emit(state.copyWith(tasks: updated));
  }
}

String _newTaskId() {
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  return 'task-$timestamp';
}

EditRoutineState _freshState() {
  return EditRoutineState(
    status: EditRoutineStatus.ready,
    routineId: 'routine-${DateTime.now().microsecondsSinceEpoch}',
    title: '',
    weekdays: const {},
    tasks: [
      Task(
        id: _newTaskId(),
        title: _defaultTaskTitle(1),
        details: '',
        priority: Priority.medium,
        weight: weightForPriority(Priority.medium),
      ),
    ],
    priority: Priority.medium,
    weight: 1.0,
    isActive: true,
    errorMessage: null,
  );
}

String _defaultTaskTitle(int index) {
  return 'Task $index';
}
