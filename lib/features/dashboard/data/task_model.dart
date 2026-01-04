import '../../../core/domain/routine_importance.dart';
import '../../../core/domain/task.dart';

class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.title,
    required super.weight,
    super.details,
    super.importance,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final rawWeight = (json['weight'] as num?)?.toDouble() ?? 1.0;
    final importanceLevel = (json['importance'] as num?)?.toInt();
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      weight: rawWeight,
      details: (json['details'] as String?) ?? '',
      importance: importanceLevel != null
          ? RoutineImportance.fromLevel(importanceLevel)
          : importanceForWeight(rawWeight),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'weight': weight,
      'details': details,
      'importance': importance.level,
    };
  }
}
