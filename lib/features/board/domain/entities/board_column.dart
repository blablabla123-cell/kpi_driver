import 'package:equatable/equatable.dart';

import 'task_item.dart';

/// One Kanban column: key is [parentId] (`null` = inbox / без папки).
class BoardColumn extends Equatable {
  const BoardColumn({
    required this.parentId,
    required this.title,
    required this.tasks,
  });

  final int? parentId;
  final String title;
  final List<TaskItem> tasks;

  int get taskCount => tasks.length;

  @override
  List<Object?> get props => [parentId, title, tasks];
}
