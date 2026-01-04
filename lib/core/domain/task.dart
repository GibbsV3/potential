import 'package:equatable/equatable.dart';

import 'routine_importance.dart';

class Task extends Equatable {
  const Task({
    required this.id,
    required this.title,
    required this.weight,
    this.details = '',
    this.importance = RoutineImportance.medium,
  });

  final String id;
  final String title;
  final double weight;
  final String details;
  final RoutineImportance importance;

  @override
  List<Object> get props => [id, title, weight, details, importance];
}

double weightForImportance(RoutineImportance importance) {
  return importance.level.toDouble();
}

RoutineImportance importanceForWeight(double weight) {
  final maxLevel = RoutineImportance.values.last.level.toDouble();
  final normalized = weight <= 1.0 ? weight * maxLevel : weight;
  final clamped = normalized.clamp(1, maxLevel).round();
  return RoutineImportance.fromLevel(clamped);
}
