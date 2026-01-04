import '../../../core/domain/routine.dart';
import '../../../core/domain/priority.dart';
import '../../../core/domain/weekday.dart';
import 'task_model.dart';

class RoutineModel extends Routine {
  const RoutineModel({
    required super.id,
    required super.title,
    required super.weight,
    required super.priority,
    required super.weekdays,
    required super.tasks,
    required super.isActive,
  });

  factory RoutineModel.fromJson(Map<String, dynamic> json) {
    return RoutineModel(
      id: json['id'] as String,
      title: json['title'] as String,
      weight: (json['weight'] as num).toDouble(),
      priority: Priority.fromLevel(
        (json['priority'] as num? ?? json['importance'] as num?)?.toInt(),
      ),
      weekdays: ((json['weekdays'] as List<dynamic>?) ?? const <dynamic>[])
          .map(Weekday.fromJson)
          .whereType<Weekday>()
          .toSet(),
      tasks: (json['tasks'] as List<dynamic>)
          .map((item) => TaskModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      isActive: (json['isActive'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'weight': weight,
      'priority': priority.level,
      'weekdays': weekdays.map((day) => day.number).toList(),
      'tasks': tasks
          .map((task) => TaskModel(
                id: task.id,
                title: task.title,
                weight: task.weight,
                details: task.details,
                priority: task.priority,
              ))
          .map((task) => task.toJson())
          .toList(),
      'isActive': isActive,
    };
  }
}
