import 'package:equatable/equatable.dart';

import 'package:potential/potential.dart';

class Task extends Equatable {
  const Task({
    required this.id,
    required this.title,
    required this.weight,
    this.details = '',
    this.priority = Priority.medium,
  });

  final String id;
  final String title;
  final double weight;
  final String details;
  final Priority priority;

  @override
  List<Object> get props => [id, title, weight, details, priority];
}

double weightForPriority(Priority priority) {
  return priority.level.toDouble();
}

Priority priorityForWeight(double weight) {
  final maxLevel = Priority.values.last.level.toDouble();
  final normalized = weight <= 1.0 ? weight * maxLevel : weight;
  final clamped = normalized.clamp(1, maxLevel).round();
  return Priority.fromLevel(clamped);
}
