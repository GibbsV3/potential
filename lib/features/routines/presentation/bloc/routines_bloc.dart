import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../dashboard/data/dashboard_repository.dart';
import '../../../dashboard/domain/routine.dart';

part 'routines_event.dart';
part 'routines_state.dart';

class RoutinesBloc extends Bloc<RoutinesEvent, RoutinesState> {
  RoutinesBloc(this._repository) : super(const RoutinesState()) {
    on<RoutinesLoaded>(_onLoaded);
    on<RoutinesEditToggled>(_onEditToggled);
    on<RoutineActivationChanged>(_onActivationChanged);
    on<RoutineDeleted>(_onDeleted);
    on<_RoutinesSynced>(_onSynced);

    _subscription = _repository.watchRoutines().listen(
          (routines) => add(_RoutinesSynced(routines)),
        );
  }

  final DashboardRepository _repository;
  late final StreamSubscription<List<Routine>> _subscription;

  Future<void> _onLoaded(
    RoutinesLoaded event,
    Emitter<RoutinesState> emit,
  ) async {
    emit(state.copyWith(status: RoutinesStatus.loading));
    try {
      final routines = await _repository.loadRoutines();
      emit(
        state.copyWith(
          status: RoutinesStatus.ready,
          routines: routines,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: RoutinesStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onEditToggled(
    RoutinesEditToggled event,
    Emitter<RoutinesState> emit,
  ) {
    emit(
      state.copyWith(
        isEditing: !state.isEditing,
      ),
    );
  }

  Future<void> _onActivationChanged(
    RoutineActivationChanged event,
    Emitter<RoutinesState> emit,
  ) async {
    await _repository.setRoutineActive(event.routineId, event.isActive);
  }

  Future<void> _onDeleted(
    RoutineDeleted event,
    Emitter<RoutinesState> emit,
  ) async {
    await _repository.deleteRoutine(event.routineId);
  }

  void _onSynced(
    _RoutinesSynced event,
    Emitter<RoutinesState> emit,
  ) {
    emit(
      state.copyWith(
        status: RoutinesStatus.ready,
        routines: event.routines,
      ),
    );
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
