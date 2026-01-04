import 'package:equatable/equatable.dart';

class Task extends Equatable {
  const Task({
    required this.id,
    required this.title,
    required this.weight,
  });

  final String id;
  final String title;
  final double weight;

  @override
  List<Object> get props => [id, title, weight];
}
