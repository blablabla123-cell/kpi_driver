import '../../domain/entities/board_column.dart';

/// Фильтрация задач по подстроке в [TaskItem.name] (без учёта регистра).
/// Пустые колонки после фильтра отбрасываются.
List<BoardColumn> filterBoardColumns(List<BoardColumn> columns, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return columns;

  return [
    for (final c in columns)
      if (c.tasks.any((t) => t.name.toLowerCase().contains(q)))
        BoardColumn(
          parentId: c.parentId,
          title: c.title,
          tasks: [
            for (final t in c.tasks)
              if (t.name.toLowerCase().contains(q)) t,
          ],
        ),
  ];
}

int countTasks(Iterable<BoardColumn> columns) {
  var n = 0;
  for (final c in columns) {
    n += c.tasks.length;
  }
  return n;
}
