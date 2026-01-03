import 'package:equatable/equatable.dart';

import 'task.dart';
import 'weekday.dart';

class Routine extends Equatable {
  const Routine({
    required this.id,
    required this.title,
    required this.weight,
    required this.weekdays,
    required this.tasks,
    required this.isActive,
  });

  final String id;
  final String title;
  final double weight;
  final Set<Weekday> weekdays;
  final List<Task> tasks;
  final bool isActive;

  @override
  List<Object> get props => [id, title, weight, weekdays, tasks, isActive];
}
