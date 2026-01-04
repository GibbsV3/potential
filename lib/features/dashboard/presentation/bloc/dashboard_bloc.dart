import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:potential/potential.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc(this._repository)
      : super(DashboardState.initial(DateTime.now())) {
    on<DashboardLoaded>(_onLoaded);
    on<DashboardDateSelected>(_onDateSelected);
    on<DashboardTaskToggled>(_onTaskToggled);
    on<DashboardTaskProgressChanged>(_onTaskProgressChanged);
    on<DashboardRoutinesUpdated>(_onRoutinesUpdated);
    _routineSubscription =
        _repository.watchRoutines().listen((routines) {
      add(DashboardRoutinesUpdated(routines));
    });
  }

  final DashboardRepository _repository;
  late final StreamSubscription<List<Routine>> _routineSubscription;

  Future<void> _onLoaded(
    DashboardLoaded event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(status: DashboardStatus.loading));
    try {
      final routines = await _repository.loadRoutines();
      final completions = await _repository.loadCompletions();
      final routinesByDate = await _repository.loadRoutinesByDate();
      emit(state.buildWith(
        routines: routines,
        routinesByDate: routinesByDate,
        completions: completions,
        selectedDate: state.selectedDate,
        status: DashboardStatus.ready,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: DashboardStatus.failure,
        errorMessage: error.toString(),
      ));
    }
  }

  void _onDateSelected(
    DashboardDateSelected event,
    Emitter<DashboardState> emit,
  ) {
    emit(state.buildWith(selectedDate: event.date));
  }

  Future<void> _onTaskToggled(
    DashboardTaskToggled event,
    Emitter<DashboardState> emit,
  ) async {
    final current = state.selectedDayCompletions[event.taskId] ?? 0;
    final updated = current >= 1 ? 0.0 : 1.0;
    await _repository.setTaskProgress(
      dateKey(event.date),
      event.taskId,
      updated,
    );
    final completions = await _repository.loadCompletions();
    final routinesByDate = await _repository.loadRoutinesByDate();
    emit(
      state.buildWith(
        completions: completions,
        routinesByDate: routinesByDate,
      ),
    );
  }

  Future<void> _onTaskProgressChanged(
    DashboardTaskProgressChanged event,
    Emitter<DashboardState> emit,
  ) async {
    await _repository.setTaskProgress(
      dateKey(event.date),
      event.taskId,
      event.progress,
    );
    final completions = await _repository.loadCompletions();
    final routinesByDate = await _repository.loadRoutinesByDate();
    emit(
      state.buildWith(
        completions: completions,
        routinesByDate: routinesByDate,
      ),
    );
  }

  Future<void> _onRoutinesUpdated(
    DashboardRoutinesUpdated event,
    Emitter<DashboardState> emit,
  ) async {
    final completions = await _repository.loadCompletions();
    final routinesByDate = await _repository.loadRoutinesByDate();
    emit(
      state.buildWith(
        routines: event.routines,
        completions: completions,
        routinesByDate: routinesByDate,
      ),
    );
  }

  @override
  Future<void> close() {
    _routineSubscription.cancel();
    return super.close();
  }
}
