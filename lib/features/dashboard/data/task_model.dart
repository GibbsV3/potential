import 'package:potential/potential.dart';

class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.title,
    required super.weight,
    super.details,
    super.priority,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final rawWeight = (json['weight'] as num?)?.toDouble() ?? 1.0;
    final priorityLevel =
        (json['priority'] as num? ?? json['importance'] as num?)?.toInt();
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      weight: rawWeight,
      details: (json['details'] as String?) ?? '',
      priority: priorityLevel != null
          ? Priority.fromLevel(priorityLevel)
          : priorityForWeight(rawWeight),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'weight': weight,
      'details': details,
      'priority': priority.level,
    };
  }
}
