import '../domain/routine.dart';
import 'task_model.dart';

class RoutineModel extends Routine {
  const RoutineModel({
    required super.id,
    required super.title,
    required super.weight,
    required super.weekdays,
    required super.tasks,
  });

  factory RoutineModel.fromJson(Map<String, dynamic> json) {
    return RoutineModel(
      id: json['id'] as String,
      title: json['title'] as String,
      weight: (json['weight'] as num).toDouble(),
      weekdays: (json['weekdays'] as List<dynamic>).cast<int>(),
      tasks: (json['tasks'] as List<dynamic>)
          .map((item) => TaskModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'weight': weight,
      'weekdays': weekdays,
      'tasks': tasks
          .map((task) => TaskModel(
                id: task.id,
                title: task.title,
                weight: task.weight,
              ))
          .map((task) => task.toJson())
          .toList(),
    };
  }
}
