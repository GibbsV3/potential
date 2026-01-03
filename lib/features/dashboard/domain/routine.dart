import 'package:equatable/equatable.dart';

import 'task.dart';

class Routine extends Equatable {
  const Routine({
    required this.id,
    required this.title,
    required this.weight,
    required this.weekdays,
    required this.tasks,
  });

  final String id;
  final String title;
  final double weight;
  final List<int> weekdays;
  final List<Task> tasks;

  @override
  List<Object> get props => [id, title, weight, weekdays, tasks];
}
