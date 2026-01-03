import '../domain/task.dart';

class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.title,
    required super.weight,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      weight: (json['weight'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'weight': weight,
    };
  }
}
