import '../entities/board_column.dart';
import '../entities/task_item.dart';

/// Groups [tasks] by `parent_id`, sorts by `order` (Шаг 2 плана).
List<BoardColumn> buildBoardColumns(List<TaskItem> tasks) {
  final byKey = <int?, List<TaskItem>>{};
  for (final t in tasks) {
    final key = _normalizeParentKey(t.parentId);
    byKey.putIfAbsent(key, () => <TaskItem>[]).add(t);
  }

  for (final list in byKey.values) {
    list.sort(_compareTasksForUi);
  }

  final keys = byKey.keys.toList()..sort(_compareColumnKeys);

  return [
    for (final k in keys)
      BoardColumn(
        parentId: k,
        title: _columnTitle(k),
        tasks: List<TaskItem>.unmodifiable(byKey[k]!),
      ),
  ];
}

int? _normalizeParentKey(int? parentId) {
  if (parentId == null || parentId == 0) return null;
  return parentId;
}

int _compareColumnKeys(int? a, int? b) {
  if (a == null && b == null) return 0;
  if (a == null) return -1;
  if (b == null) return 1;
  return a.compareTo(b);
}

int _compareTasksForUi(TaskItem a, TaskItem b) {
  final ao = a.order;
  final bo = b.order;
  if (ao != null && bo != null && ao != bo) return ao.compareTo(bo);
  if (ao != null && bo == null) return -1;
  if (ao == null && bo != null) return 1;
  return a.indicatorToMoId.compareTo(b.indicatorToMoId);
}

String _columnTitle(int? parentId) {
  if (parentId == null) return 'Без папки';
  return 'Папка #$parentId';
}
