import 'package:equatable/equatable.dart';

class TaskItem extends Equatable {
  const TaskItem({
    required this.indicatorToMoId,
    required this.name,
    required this.parentId,
    required this.order,
  });

  final int indicatorToMoId;
  final String name;
  final int? parentId;
  final int? order;

  TaskItem copyWith({
    int? indicatorToMoId,
    String? name,
    int? parentId,
    int? order,
  }) {
    return TaskItem(
      indicatorToMoId: indicatorToMoId ?? this.indicatorToMoId,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      order: order ?? this.order,
    );
  }

  @override
  List<Object?> get props => [indicatorToMoId, name, parentId, order];
}

