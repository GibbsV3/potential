import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/data/dashboard_repository.dart';
import '../../../core/domain/routine.dart';
import '../../../core/domain/routine_importance.dart';
import '../../../core/domain/task.dart';
import '../../../core/domain/weekday.dart';

part 'edit_routine_event.dart';
part 'edit_routine_state.dart';

class EditRoutineBloc extends Bloc<EditRoutineEvent, EditRoutineState> {
  EditRoutineBloc(this._repository) : super(const EditRoutineState.initial()) {
    on<EditRoutineStarted>(_onStarted);
    on<EditRoutineTitleChanged>(_onTitleChanged);
    on<EditRoutineWeekdayToggled>(_onWeekdayToggled);
    on<EditRoutineImportanceChanged>(_onImportanceChanged);
    on<EditRoutineTaskAdded>(_onTaskAdded);
    on<EditRoutineTaskRemoved>(_onTaskRemoved);
    on<EditRoutineTaskTitleChanged>(_onTaskTitleChanged);
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
          importance: routine.importance,
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

  void _onImportanceChanged(
    EditRoutineImportanceChanged event,
    Emitter<EditRoutineState> emit,
  ) {
    emit(
      state.copyWith(
        importance: event.importance,
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
          weight: 1.0,
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
        importance: state.importance,
        weekdays: Set<Weekday>.from(state.weekdays),
        tasks: state.tasks
            .map(
              (task) => Task(
                id: task.id,
                title: task.title.trim(),
                weight: task.weight,
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
        weight: 1.0,
      ),
    ],
    importance: RoutineImportance.medium,
    weight: 1.0,
    isActive: true,
    errorMessage: null,
  );
}

String _defaultTaskTitle(int index) {
  return 'Task $index';
}
