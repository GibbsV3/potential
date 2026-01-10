import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:potential/potential.dart';

part 'history_event.dart';
part 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc(this._repository) : super(HistoryState.initial()) {
    on<HistoryLoaded>(_onLoaded);
    on<HistoryRangeChanged>(_onRangeChanged);
    on<HistoryAnchorChanged>(_onAnchorChanged);
    on<HistoryRoutinesUpdated>(_onRoutinesUpdated);
    on<HistoryCompletionsUpdated>(_onCompletionsUpdated);

    _routineSubscription = _repository.watchRoutines().listen((routines) {
      add(HistoryRoutinesUpdated(routines));
    });
    _completionsSubscription =
        _repository.watchCompletions().listen((completions) {
      add(HistoryCompletionsUpdated(completions));
    });
  }

  final DashboardRepository _repository;

  late final StreamSubscription<List<Routine>> _routineSubscription;
  late final StreamSubscription<Map<String, Map<String, double>>>
      _completionsSubscription;
  List<Routine> _routines = const [];
  Map<String, Map<String, double>> _completions = const {};
  Map<String, List<Routine>> _routinesByDate = const {};

  Future<void> _onLoaded(
    HistoryLoaded event,
    Emitter<HistoryState> emit,
  ) async {
    emit(state.copyWith(status: HistoryStatus.loading));
    try {
      _routines = await _repository.loadRoutines();
      _completions = await _repository.loadCompletions();
      final anchor = DateTime.now();
      _routinesByDate = await _repository.loadRoutinesByDate(
        dateKeys: _dateKeysForRange(state.range, anchor),
      );
      emit(_buildReadyState(
        status: HistoryStatus.ready,
        anchorDate: anchor,
      ));
    } catch (error) {
      emit(
        state.copyWith(
          status: HistoryStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onRangeChanged(
    HistoryRangeChanged event,
    Emitter<HistoryState> emit,
  ) async {
    try {
      _completions = await _repository.loadCompletions();
      _routinesByDate = await _repository.loadRoutinesByDate(
        dateKeys: _dateKeysForRange(event.range, state.anchorDate),
      );
      emit(
        _buildReadyState(
          range: event.range,
          status: HistoryStatus.ready,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: HistoryStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onAnchorChanged(
    HistoryAnchorChanged event,
    Emitter<HistoryState> emit,
  ) async {
    try {
      _completions = await _repository.loadCompletions();
      _routinesByDate = await _repository.loadRoutinesByDate(
        dateKeys: _dateKeysForRange(state.range, event.anchorDate),
      );
      emit(
        _buildReadyState(
          anchorDate: event.anchorDate,
          status: HistoryStatus.ready,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: HistoryStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onRoutinesUpdated(
    HistoryRoutinesUpdated event,
    Emitter<HistoryState> emit,
  ) async {
    _routines = event.routines;
    if (state.status == HistoryStatus.loading) {
      return;
    }
    try {
      _completions = await _repository.loadCompletions();
      _routinesByDate = await _repository.loadRoutinesByDate(
        dateKeys: _dateKeysForRange(state.range, state.anchorDate),
      );
      emit(
        _buildReadyState(
          status: HistoryStatus.ready,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: HistoryStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onCompletionsUpdated(
    HistoryCompletionsUpdated event,
    Emitter<HistoryState> emit,
  ) async {
    _completions = event.completions;
    if (state.status == HistoryStatus.loading) {
      return;
    }
    try {
      _routinesByDate = await _repository.loadRoutinesByDate(
        dateKeys: _dateKeysForRange(state.range, state.anchorDate),
      );
      emit(
        _buildReadyState(
          status: HistoryStatus.ready,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: HistoryStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  HistoryState _buildReadyState({
    HistoryStatus status = HistoryStatus.ready,
    HistoryRange? range,
    DateTime? anchorDate,
  }) {
    final resolvedRange = range ?? state.range;
    final resolvedAnchor = normalizeDate(anchorDate ?? state.anchorDate);
    final points = _buildSeries(resolvedRange, resolvedAnchor);
    return state.copyWith(
      status: status,
      range: resolvedRange,
      anchorDate: resolvedAnchor,
      points: points,
      routines: _routines,
      routinesByDate: _routinesByDate,
      completions: _completions,
      errorMessage: null,
    );
  }

  Set<String> _dateKeysForRange(
    HistoryRange range,
    DateTime anchorDate,
  ) {
    final normalizedAnchor = normalizeDate(anchorDate);
    switch (range) {
      case HistoryRange.daily:
        return List<DateTime>.generate(
          _dailyPoints,
          (index) => normalizedAnchor
              .subtract(Duration(days: (_dailyPoints - 1) - index)),
        ).map(dateKey).toSet();
      case HistoryRange.weekly:
        final currentWeekStart = _startOfWeek(normalizedAnchor);
        final firstWeekStart =
            currentWeekStart.subtract(Duration(days: 7 * (_weeklyPoints - 1)));
        final keys = <String>{};
        for (var week = 0; week < _weeklyPoints; week++) {
          for (var day = 0; day < 7; day++) {
            final date = firstWeekStart.add(Duration(days: (week * 7) + day));
            keys.add(dateKey(date));
          }
        }
        return keys;
    }
  }

  List<HistoryPoint> _buildSeries(
    HistoryRange range,
    DateTime anchorDate,
  ) {
    if (_routines.isEmpty && _routinesByDate.isEmpty) {
      return range == HistoryRange.daily
          ? _buildDailySkeleton(anchorDate)
          : _buildWeeklySkeleton(anchorDate);
    }
    switch (range) {
      case HistoryRange.daily:
        return _buildDailySeries(anchorDate);
      case HistoryRange.weekly:
        return _buildWeeklySeries(anchorDate);
    }
  }

  List<HistoryPoint> _buildDailySeries(DateTime anchorDate) {
    final normalizedAnchor = normalizeDate(anchorDate);
    return List<HistoryPoint>.generate(_dailyPoints, (index) {
      final date = normalizedAnchor
          .subtract(Duration(days: (_dailyPoints - 1) - index));
      final progress = weightedProgressForDate(
        date: date,
        routines: _routines,
        completions: _completions,
        routinesByDate: _routinesByDate,
      );
      return HistoryPoint(date: date, progress: progress);
    });
  }

  List<HistoryPoint> _buildWeeklySeries(DateTime anchorDate) {
    final currentWeekStart = _startOfWeek(anchorDate);
    final firstWeekStart =
        currentWeekStart.subtract(Duration(days: 7 * (_weeklyPoints - 1)));
    return List<HistoryPoint>.generate(_weeklyPoints, (index) {
      final weekStart =
          firstWeekStart.add(Duration(days: 7 * index));
      final progress = _weekAverage(weekStart);
      return HistoryPoint(date: weekStart, progress: progress);
    });
  }

  List<HistoryPoint> _buildDailySkeleton(DateTime anchorDate) {
    final normalizedAnchor = normalizeDate(anchorDate);
    return List<HistoryPoint>.generate(_dailyPoints, (index) {
      final date = normalizedAnchor
          .subtract(Duration(days: (_dailyPoints - 1) - index));
      return HistoryPoint(date: date, progress: 0);
    });
  }

  List<HistoryPoint> _buildWeeklySkeleton(DateTime anchorDate) {
    final currentWeekStart = _startOfWeek(anchorDate);
    final firstWeekStart =
        currentWeekStart.subtract(Duration(days: 7 * (_weeklyPoints - 1)));
    return List<HistoryPoint>.generate(_weeklyPoints, (index) {
      final weekStart =
          firstWeekStart.add(Duration(days: 7 * index));
      return HistoryPoint(date: weekStart, progress: 0);
    });
  }

  double _weekAverage(DateTime weekStart) {
    double sum = 0;
    for (var day = 0; day < 7; day++) {
      final date = weekStart.add(Duration(days: day));
      sum += weightedProgressForDate(
        date: date,
        routines: _routines,
        completions: _completions,
        routinesByDate: _routinesByDate,
      );
    }
    return sum / 7;
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = normalizeDate(date);
    final weekdayIndexFromSunday = normalized.weekday % 7;
    return normalized.subtract(Duration(days: weekdayIndexFromSunday));
  }

  @override
  Future<void> close() {
    _routineSubscription.cancel();
    _completionsSubscription.cancel();
    return super.close();
  }
}

const int _dailyPoints = 7;
const int _weeklyPoints = 7;
