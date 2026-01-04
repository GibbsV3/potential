import 'package:equatable/equatable.dart';

import 'package:potential/potential.dart';

class RoutineProgress extends Equatable {
  const RoutineProgress({
    required this.routine,
    required this.completion,
  });

  final Routine routine;
  final double completion;

  @override
  List<Object> get props => [routine, completion];
}
